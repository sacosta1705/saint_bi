import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_bi/core/bloc/connection/connection_bloc.dart'
    as saint_bloc;
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

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
                padding: const EdgeInsets.all(6),
                children: [
                  _buildKpiCard(
                    title: 'Utilidad Bruta',
                    value: '${summary.grossProfitMargin.toStringAsFixed(2)}%',
                    icon: Icons.trending_up,
                    headerColor: AppColors.primaryBlue,
                  ),

                  _buildKpiCard(
                    title: 'Utilidad Neta',
                    value: '${summary.netProfitMargin.toStringAsFixed(2)}%',
                    icon: Icons.attach_money,
                    headerColor: AppColors.primaryBlue,
                  ),

                  _buildKpiCard(
                    title: 'Razón corriente',
                    value: '${summary.currentRatio.toStringAsFixed(2)} : 1',
                    icon: Icons.account_balance,
                    headerColor: AppColors.primaryBlue,
                  ),

                  _buildKpiCard(
                    title: 'Rotación inventario',
                    value: summary.inventoryTurnover.toStringAsFixed(2),
                    icon: Icons.sync,
                    headerColor: AppColors.primaryBlue,
                  ),

                  _buildKpiCard(
                    title: 'Prueba Ácida',
                    value: summary.quickRatio.toStringAsFixed(2),
                    icon: Icons.science_outlined,
                    headerColor: AppColors.primaryBlue,
                  ),

                  _buildKpiCard(
                    title: 'Rotación CxC',
                    value:
                        "${summary.daysSalesOutstanging.toStringAsFixed(1)} dias",
                    icon: Icons.hourglass_bottom,
                    headerColor: AppColors.primaryBlue,
                  ),

                  _buildKpiCard(
                    title: 'Ticket promedio',
                    value: formatNumber(
                      summary.averageTicket,
                      getDeviceLocale(context),
                    ),
                    icon: Icons.shopping_cart,
                    headerColor: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color headerColor,
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
              vertical: 8.0,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimaryBlue,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                Icon(icon, color: AppColors.iconOnPrimary, size: 16),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
