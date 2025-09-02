import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/data/models/invoice_item.dart';
import 'package:saint_bi/core/services/analysis/market_basket_service.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

enum SortBy { confidence, support, lift }

List<AssociationRule> _runAnalysisIsolate(Map<String, dynamic> args) {
  final invoiceItemsJson = args['invoiceItems'] as List<dynamic>;
  final invoiceItems = invoiceItemsJson
      .map((json) => InvoiceItem.fromJson(json as Map<String, dynamic>))
      .toList();

  final minSupport = args['minSupport'] as double;
  final minConfidence = args['minConfidence'] as double;

  final marketBasketService = MarketBasketService();
  return marketBasketService.analyze(
    invoiceItems: invoiceItems,
    minSupport: minSupport,
    minConfidence: minConfidence,
  );
}

Future<List<AssociationRule>> runMarketBasketAnalysisInIsolate(
  Map<String, dynamic> analysisData,
) {
  return Isolate.run(() => _runAnalysisIsolate(analysisData));
}

class MarketBasketScreen extends StatefulWidget {
  const MarketBasketScreen({super.key});
  @override
  State<MarketBasketScreen> createState() => _MarketBasketScreenState();
}

class _MarketBasketScreenState extends State<MarketBasketScreen> {
  // final _marketBasketService = MarketBasketService();
  final _searchController = TextEditingController();
  List<AssociationRule> _allRules = [];
  List<AssociationRule> _filteredRules = [];
  bool _isLoading = false;
  double _minSupport = 0.02;
  double _minConfidence = 0.5;
  SortBy _sortBy = SortBy.confidence;

  late final Map<String, String> _productNames;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final allProducts = context.read<SummaryBloc>().state.allProducts;
      _productNames = {for (var p in allProducts) p.code: p.description};
      _searchController.addListener(_filterAndSortRules);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _runAnalysis();
        }
      });

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAndSortRules);
    _searchController.dispose();
    super.dispose();
  }

  void _runAnalysis() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final summaryState = context.read<SummaryBloc>().state;

    final invoiceItemsasMaps = summaryState.allInvoiceItems
        .map((item) => item.toMap())
        .toList();

    final double minSupport = _minSupport;
    final double minConfidence = _minConfidence;

    final rules = await runMarketBasketAnalysisInIsolate({
      'invoiceItems': invoiceItemsasMaps,
      'minSupport': minSupport,
      'minConfidence': minConfidence,
    });

    if (!mounted) return;

    setState(() {
      _allRules = rules;
      _isLoading = false;
    });
    _filterAndSortRules();
  }

  void _filterAndSortRules() {
    List<AssociationRule> tempRules = List.from(_allRules);
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      tempRules = tempRules.where((rule) {
        final antecedentMatch = rule.antecedent.any(
          (code) => _getProductName(code).toLowerCase().contains(query),
        );
        final consequentMatch = rule.consequent.any(
          (code) => _getProductName(code).toLowerCase().contains(query),
        );
        return antecedentMatch || consequentMatch;
      }).toList();
    }

    switch (_sortBy) {
      case SortBy.confidence:
        tempRules.sort((a, b) => b.confidence.compareTo(a.confidence));
        break;
      case SortBy.support:
        tempRules.sort((a, b) => b.support.compareTo(a.support));
        break;
      case SortBy.lift:
        tempRules.sort((a, b) => b.lift.compareTo(a.lift));
        break;
    }

    setState(() => _filteredRules = tempRules);
  }

  String _getProductName(String code) => _productNames[code] ?? code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de Canasta')),
      body: Column(
        children: [
          _buildControls(),
          _buildSearchAndSort(), // <-- NUEVO WIDGET
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRules.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No se encontraron reglas con los parámetros actuales. Intente reducir los umbrales.'
                            : 'No se encontraron reglas que coincidan con su búsqueda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _filteredRules.length,
                    itemBuilder: (context, index) =>
                        _buildRuleCard(_filteredRules[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    // ... (Este widget se mantiene igual) ...
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajustar Parámetros',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Soporte Mínimo:', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _minSupport,
                      min: 0.001,
                      max: 1.0,
                      divisions: 99,
                      label: '${(_minSupport * 100).toStringAsFixed(0)}%',
                      onChanged: (v) => setState(() => _minSupport = v),
                      onChangeEnd: (v) => _runAnalysis(),
                    ),
                  ),
                  Text('${(_minSupport * 100).toStringAsFixed(0)}%'),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Confianza Mínima:',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: Slider(
                      value: _minConfidence,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: '${(_minConfidence * 100).toStringAsFixed(0)}%',
                      onChanged: (v) => setState(() => _minConfidence = v),
                      onChangeEnd: (v) => _runAnalysis(),
                    ),
                  ),
                  Text('${(_minConfidence * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre de producto...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Ordenar por: '),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Confianza'),
                  selected: _sortBy == SortBy.confidence,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortBy = SortBy.confidence);
                    _filterAndSortRules();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Soporte'),
                  selected: _sortBy == SortBy.support,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortBy = SortBy.support);
                    _filterAndSortRules();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Lift'),
                  selected: _sortBy == SortBy.lift,
                  onSelected: (selected) {
                    if (selected) setState(() => _sortBy = SortBy.lift);
                    _filterAndSortRules();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(AssociationRule rule) {
    // ... (Este widget se mantiene igual) ...
    final antecedentText = rule.antecedent.map(_getProductName).join(', ');
    final consequentText = rule.consequent.map(_getProductName).join(', ');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_basket_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        const TextSpan(text: 'Si compran '),
                        TextSpan(
                          text: antecedentText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Icon(
                Icons.arrow_downward,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        const TextSpan(text: 'También compran '),
                        TextSpan(
                          text: consequentText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricChip(
                  'Confianza',
                  '${(rule.confidence * 100).toStringAsFixed(1)}%',
                ),
                _buildMetricChip(
                  'Soporte',
                  '${(rule.support * 100).toStringAsFixed(2)}%',
                ),
                _buildMetricChip('Lift', rule.lift.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
