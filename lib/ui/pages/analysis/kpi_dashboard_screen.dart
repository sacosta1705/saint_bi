import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart'
    as saint_bloc;
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';
import 'package:saint_bi/ui/widgets/common/info_dialog.dart';

class KpiDashboardScreen extends StatelessWidget {
  const KpiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summaryState = context.watch<SummaryBloc>().state;
    final summary = summaryState.summary;
    final connection = context
        .watch<saint_bloc.ConnectionBloc>()
        .state
        .activeConnection;

    return Scaffold(
      appBar: AppBar(
        title: Text("KPI's: ${connection?.companyAlias ?? 'Indicadores'}"),
      ),
      body: summaryState.status == SummaryStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                padding: const EdgeInsets.all(12),
                children: [
                  _buildKpiCard(
                    context: context,
                    title: 'Margen de Utilidad Bruta',
                    value: '${summary.grossProfitMargin.toStringAsFixed(2)}%',
                    icon: Icons.trending_up,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Es el porcentaje de ganancia que obtienes por cada venta después de restar el costo de los productos vendidos. Un margen más alto significa mayor rentabilidad.',
                  ),
                  _buildKpiCard(
                    context: context,
                    title: 'Margen de Utilidad Neta',
                    value: '${summary.netProfitMargin.toStringAsFixed(2)}%',
                    icon: Icons.attach_money,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Es el porcentaje de ganancia final que queda después de restar TODOS los costos y gastos (incluyendo financiamiento e impuestos). Mide la rentabilidad real del negocio.',
                  ),
                  _buildKpiCard(
                    context: context,
                    title: 'Razón Corriente',
                    value: '${summary.currentRatio.toStringAsFixed(2)} : 1',
                    icon: Icons.account_balance,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Mide la capacidad de la empresa para pagar sus deudas a corto plazo (menos de un año). Un valor superior a 1 indica que tienes más activos que deudas a corto plazo, lo cual es saludable.',
                  ),
                  _buildKpiCard(
                    context: context,
                    title: 'Rotación de Inventario',
                    value: summary.inventoryTurnover.toStringAsFixed(2),
                    icon: Icons.sync,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Indica cuántas veces la empresa ha vendido y reemplazado su inventario durante un período. Un número más alto sugiere una buena gestión y ventas eficientes.',
                  ),
                  _buildKpiCard(
                    context: context,
                    title: 'Prueba Ácida',
                    value: summary.quickRatio.toStringAsFixed(2),
                    icon: Icons.science_outlined,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Similar a la Razón Corriente, pero más estricta, ya que excluye el inventario. Mide la capacidad de pagar deudas a corto plazo usando solo los activos más líquidos (dinero y cuentas por cobrar).',
                  ),
                  _buildKpiCard(
                    context: context,
                    title: 'Días de Cuentas por Cobrar',
                    value:
                        "${summary.daysSalesOutstanging.toStringAsFixed(1)} días",
                    icon: Icons.hourglass_bottom,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Representa el número promedio de días que tardas en cobrar el dinero de tus ventas a crédito. Un número más bajo es mejor, ya que significa que el efectivo entra más rápido a tu negocio.',
                  ),

                  _buildKpiCard(
                    context: context,
                    title: 'Ticket Promedio',
                    value: formatNumber(
                      summary.averageTicket,
                      getDeviceLocale(context),
                    ),
                    icon: Icons.shopping_cart,
                    headerColor: AppColors.primaryBlue,
                    explanation:
                        'Es el valor promedio de cada venta o factura emitida. Ayuda a entender el comportamiento de compra de tus clientes y a medir el impacto de estrategias de ventas.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color headerColor,
    required String explanation,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: AppColors.cardBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 12.0,
            ),
            color: headerColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimaryBlue,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  color: AppColors.iconOnPrimary,
                  onPressed: () {
                    showInfoDialog(
                      context: context,
                      title: title,
                      content: explanation,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: valueColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
