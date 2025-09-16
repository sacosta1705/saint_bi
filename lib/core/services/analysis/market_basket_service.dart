import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:saint_bi/core/data/models/invoice_item.dart';

// Modelo para representar una regla de asociación.
class AssociationRule {
  // Lo que el cliente ya tiene en la canasta
  final Set<String> antecedent;
  // Lo que probablemente comprará
  final Set<String> consequent;
  // Frecuencia del conjunto de ítems en todas las transacciones
  final double support;
  // Probabilidad de comprar el consecuente si ya se tiene el antecedente
  final double confidence;
  // Qué tan fuerte es la relación, independientemente de la popularidad
  final double lift;

  AssociationRule({
    required this.antecedent,
    required this.consequent,
    required this.support,
    required this.confidence,
    required this.lift,
  });

  @override
  String toString() {
    return '${antecedent.join(', ')} -> ${consequent.join(', ')} (Conf: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

class MarketBasketService {
  List<AssociationRule> analyze({
    required List<InvoiceItem> invoiceItems,
    required double minSupport,
    required double minConfidence,
  }) {
    if (invoiceItems.isEmpty) return [];

    // 1. Agrupar ítems por factura para crear las "canastas" o transacciones.
    final transactions = groupBy(invoiceItems, (item) => item.docNumber).values
        .map((items) => items.map((item) => item.productCode).toSet())
        .where(
          (transaction) => transaction.length > 1,
        ) // Solo nos interesan canastas con más de un producto
        .toList();

    if (transactions.isEmpty) return [];

    // 2. Encontrar todos los conjuntos de productos que aparecen juntos frecuentemente (algoritmo Apriori).
    final frequentItemsets = _apriori(transactions, minSupport);

    // 3. Generar todas las posibles reglas a partir de los conjuntos frecuentes.
    final allRules = _generateRules(
      frequentItemsets,
      transactions,
      minConfidence,
    );

    // 4. Filtrar reglas redundantes y resolver empates.
    final bestRules = _filterBestRules(allRules);

    // 5. Ordenar las reglas finales para mostrar las más relevantes primero.
    bestRules.sort((a, b) {
      int compare = b.confidence.compareTo(a.confidence);
      if (compare == 0) return b.lift.compareTo(a.lift);
      return compare;
    });

    return bestRules;
  }

  /// Se queda con la mejor regla para cada par de productos.
  List<AssociationRule> _filterBestRules(List<AssociationRule> allRules) {
    final Map<String, AssociationRule> bestRulesMap = {};
    // const setEquality = SetEquality();

    for (final rule in allRules) {
      // Crea una "clave canónica" para el par de productos, ordenándolos alfabéticamente.
      // Esto asegura que {A, B} y {B, A} tengan la misma clave.
      final itemset = (rule.antecedent.union(rule.consequent)).toList()..sort();
      final key = itemset.join('|');

      final existingRule = bestRulesMap[key];

      if (existingRule == null) {
        // Si es la primera vez que vemos este par, lo guardamos.
        bestRulesMap[key] = rule;
      } else {
        // Si ya existe una regla para este par, nos quedamos con la "mejor".
        // Criterio 1: Mayor Confianza.
        if (rule.confidence > existingRule.confidence) {
          bestRulesMap[key] = rule;
        }
        // Criterio 2 (desempate): Mayor Lift.
        else if (rule.confidence == existingRule.confidence &&
            rule.lift > existingRule.lift) {
          bestRulesMap[key] = rule;
        }
      }
    }
    return bestRulesMap.values.toList();
  }

  /// Genera las reglas de asociación a partir de los itemsets frecuentes.
  List<AssociationRule> _generateRules(
    Map<Set<String>, double> frequentItemsets,
    List<Set<String>> transactions,
    double minConfidence,
  ) {
    final List<AssociationRule> rules = [];
    frequentItemsets.keys.where((itemset) => itemset.length > 1).forEach((
      itemset,
    ) {
      for (final antecedent in _getSubsets(itemset)) {
        if (antecedent.isEmpty) continue;

        final consequent = itemset.difference(antecedent);
        if (consequent.isEmpty) continue;

        final double antecedentSupport =
            frequentItemsets[antecedent] ??
            _calculateSupport(antecedent, transactions);
        final double consequentSupport =
            frequentItemsets[consequent] ??
            _calculateSupport(consequent, transactions);

        if (antecedentSupport > 0 && consequentSupport > 0) {
          final confidence = frequentItemsets[itemset]! / antecedentSupport;

          if (confidence >= minConfidence) {
            final lift = confidence / consequentSupport;
            rules.add(
              AssociationRule(
                antecedent: antecedent,
                consequent: consequent,
                support: frequentItemsets[itemset]!,
                confidence: confidence,
                lift: lift,
              ),
            );
          }
        }
      }
    });
    return rules;
  }

  Map<Set<String>, double> _apriori(
    List<Set<String>> transactions,
    double minSupport,
  ) {
    const setEquality = SetEquality<String>();

    final numTransactions = transactions.length;

    Map<Set<String>, int> c1 = HashMap(
      equals: setEquality.equals,
      hashCode: setEquality.hash,
    );
    for (var transaction in transactions) {
      for (var item in transaction) {
        final itemset = {item};
        c1.update(itemset, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    Map<Set<String>, double> l1 = HashMap(
      equals: setEquality.equals,
      hashCode: setEquality.hash,
    );

    c1.forEach((itemset, count) {
      final support = count / numTransactions;
      if (support >= minSupport) {
        l1[itemset] = support;
      }
    });

    Map<Set<String>, double> allFrequentItemsets = Map.from(l1);
    Map<Set<String>, double> lk = l1;

    int k = 2;

    while (lk.isNotEmpty) {
      final Set<Set<String>> ck = _generateCandidates(lk.keys.toSet(), k);
      Map<Set<String>, int> candidateCounts = HashMap(
        equals: setEquality.equals,
        hashCode: setEquality.hash,
      );
      for (var transaction in transactions) {
        for (var candidate in ck) {
          if (transaction.containsAll(candidate)) {
            candidateCounts.update(
              candidate,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
      lk = HashMap(equals: setEquality.equals, hashCode: setEquality.hash);
      candidateCounts.forEach((candidate, count) {
        final support = count / numTransactions;
        if (support >= minSupport) {
          lk[candidate] = support;
        }
      });
      allFrequentItemsets.addAll(lk);
      k++;
    }
    return allFrequentItemsets;
  }

  Set<Set<String>> _generateCandidates(Set<Set<String>> lk_1, int k) {
    Set<Set<String>> candidates = {};
    List<Set<String>> lk1List = lk_1.toList();
    for (int i = 0; i < lk1List.length; i++) {
      for (int j = i + 1; j < lk1List.length; j++) {
        Set<String> union = lk1List[i].union(lk1List[j]);
        if (union.length == k) {
          candidates.add(union);
        }
      }
    }
    return candidates;
  }

  Iterable<Set<String>> _getSubsets(Set<String> itemset) sync* {
    List<String> items = itemset.toList();
    int n = items.length;
    for (int i = 1; i < (1 << n) - 1; i++) {
      Set<String> subset = {};
      for (int j = 0; j < n; j++) {
        if ((i >> j) % 2 == 1) {
          subset.add(items[j]);
        }
      }
      yield subset;
    }
  }

  double _calculateSupport(
    Set<String> itemset,
    List<Set<String>> transactions,
  ) {
    int count = 0;
    for (final t in transactions) {
      if (t.containsAll(itemset)) {
        count++;
      }
    }
    return count / transactions.length;
  }
}
