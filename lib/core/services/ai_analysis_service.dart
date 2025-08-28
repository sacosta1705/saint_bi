import 'package:saint_bi/core/data/models/management_summary.dart';

class AiAnalysisService {
  String createPromptFromSummary(ManagementSummary summary) {
    return '''
        Eres un experto analista financiero y de negocios. A continuación, te presento un resumen de los indicadores clave de rendimiento (KPIs) de una empresa en un período determinado. Quiero que realices un análisis detallado y ofrezcas recomendaciones accionables.

      **Resumen Financiero:**
      - **Ventas Netas Totales:** ${summary.totalNetSales}
        - A Crédito: ${summary.totalNetSalesCredit}
        - De Contado: ${summary.totalNetSalesCash}
      - **Costo de Ventas:** ${summary.costOfGoodsSold}
      - **Utilidad Bruta:** ${summary.grossProfit}
      - **Gastos Operativos:** ${summary.operatingExpenses}
      - **Utilidad Neta (Aproximada):** ${summary.netProfitOrLoss}

      **Márgenes de Rentabilidad:**
      - **Margen de Utilidad Bruta:** ${summary.grossProfitMargin.toStringAsFixed(2)}%
      - **Margen de Utilidad Neta:** ${summary.netProfitMargin.toStringAsFixed(2)}%

      **Liquidez:**
      - **Razón Corriente:** ${summary.currentRatio.toStringAsFixed(2)}
      - **Prueba Ácida:** ${summary.quickRatio.toStringAsFixed(2)}

      **Gestión de Activos:**
      - **Inventario Actual:** ${summary.currentInventory}
      - **Rotación de Inventario:** ${summary.inventoryTurnover.toStringAsFixed(2)} veces
      - **Cuentas por Cobrar Totales:** ${summary.totalReceivables}
      - **Cuentas por Cobrar Vencidas:** ${summary.overdueReceivables}
      - **Rotación de CxC (Días):** ${summary.daysSalesOutstanging.toStringAsFixed(1)} días

      **Análisis Solicitado:**
      1.  **Diagnóstico General:** ¿Cuál es la salud financiera general de la empresa según estos datos?
      2.  **Rentabilidad:** Analiza los márgenes. ¿Son saludables? ¿Qué podrían indicar?
      3.  **Liquidez:** Evalúa la capacidad de la empresa para cubrir sus obligaciones a corto plazo.
      4.  **Eficiencia Operativa:** Comenta sobre la gestión de inventarios y cuentas por cobrar.
      5.  **Puntos Críticos:** Identifica las 2-3 áreas de mayor riesgo o preocupación.
      6.  **Recomendaciones:** Proporciona 3 a 5 recomendaciones claras y accionables para mejorar la situación, basadas exclusivamente en los datos proporcionados.

      Actúa como un asesor financiero directo y conciso.
        ''';
  }

  Future<String> getAnalysis(String prompt) async {
    await Future.delayed(const Duration(seconds: 3));

    return '''
### **Análisis Financiero y Recomendaciones**

#### **1. Diagnóstico General**
La empresa muestra una rentabilidad operativa positiva (Utilidad Bruta > 0), lo cual es una buena señal. Sin embargo, la salud financiera general parece estar bajo presión debido a posibles problemas de liquidez y una gestión de cobros que podría mejorarse. Aunque se generan ganancias brutas, los gastos operativos y la gestión de activos circulantes son áreas críticas a vigilar.

#### **2. Análisis de Rentabilidad**
- **Margen Bruto:** Un margen bruto positivo indica que la venta de productos o servicios cubre su costo directo. Sería necesario compararlo con el promedio de la industria para determinar si es "saludable".
- **Margen Neto:** Este es el indicador clave. Un margen neto bajo o negativo (dependiendo del valor exacto) sugiere que los gastos operativos, impuestos e intereses consumen la mayor parte de la utilidad bruta. Es crucial controlar los gastos para mejorar este indicador.

#### **3. Evaluación de Liquidez**
- **Razón Corriente:** Una razón corriente mayor a 1.0 sugiere que la empresa puede cubrir sus pasivos a corto plazo con sus activos a corto plazo. Un valor cercano a 2.0 es a menudo considerado ideal, pero esto varía por industria.
- **Prueba Ácida:** Este indicador, al excluir el inventario, da una visión más estricta de la liquidez. Si es significativamente menor a 1.0, podría indicar una fuerte dependencia del inventario para pagar deudas, lo cual es un riesgo.

#### **4. Eficiencia Operativa**
- **Gestión de Inventario:** La rotación de inventario indica cuántas veces la empresa vende y reemplaza su inventario en el período. Un número bajo podría señalar ventas lentas o exceso de stock.
- **Gestión de Cobros:** Los días de rotación de CxC muestran el tiempo promedio que se tarda en cobrar las ventas a crédito. Un valor alto puede indicar problemas en el flujo de caja, ya que el dinero no está disponible para operar.

#### **5. Puntos Críticos de Riesgo**
1. **Flujo de Caja:** Las cuentas por cobrar vencidas y el tiempo elevado de rotación de CxC son las mayores amenazas. La empresa podría tener ganancias en papel, pero no el efectivo para pagar sus propias deudas.
2. **Control de Gastos:** La diferencia entre la utilidad bruta y la neta sugiere que los gastos operativos podrían estar erosionando la rentabilidad de manera significativa.

#### **6. Recomendaciones Accionables**
1. **Optimizar la Gestión de Cobranza:** Implementar políticas de cobro más estrictas. Ofrecer descuentos por pronto pago y renegociar plazos con clientes morosos. El objetivo debe ser reducir los días de rotación de CxC.
2. **Auditar Gastos Operativos:** Realizar una revisión exhaustiva de todos los gastos que no están directamente ligados a la producción. Buscar áreas para reducir costos sin impactar la calidad o la operación esencial.
3. **Mejorar la Rotación de Inventario:** Analizar el inventario para identificar productos de baja rotación. Considerar liquidar este stock mediante ofertas para liberar capital inmovilizado.
''';
  }
}
