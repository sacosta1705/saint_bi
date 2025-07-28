import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/bloc/auth/auth_bloc.dart';

import 'package:saint_bi/core/bloc/connection/connection_bloc.dart'
    as connection_bloc;
import 'package:saint_bi/core/bloc/summary/summary_bloc.dart';
import 'package:saint_bi/core/data/models/account_payable.dart';
import 'package:saint_bi/core/data/models/account_receivable.dart';
import 'package:saint_bi/core/data/models/invoice.dart';
import 'package:saint_bi/core/utils/constants.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/pages/analysis/analysis_hub.dart';
import 'package:saint_bi/ui/pages/auth/login_screen.dart';
import 'package:saint_bi/ui/pages/connection/connection_settings_screen.dart';
import 'package:saint_bi/ui/pages/analysis/sales_forecast_screen.dart';
import 'package:saint_bi/ui/pages/transaction_details/transaction_list_screen.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';
import 'package:saint_bi/ui/widgets/common/admin_password_dialog.dart';
import 'package:saint_bi/ui/widgets/feature_specific/summary/transaction_list_item.dart';

class ManagementSummaryScreen extends StatefulWidget {
  const ManagementSummaryScreen({super.key});

  @override
  State<ManagementSummaryScreen> createState() =>
      _ManagementSummaryScreenState();
}

class _ManagementSummaryScreenState extends State<ManagementSummaryScreen> {
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() {
    final summaryBloc = context.read<SummaryBloc>();
    summaryBloc.add(
      SummaryDataFetched(
        startDate: summaryBloc.state.startDate,
        endDate: summaryBloc.state.endDate,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    context.read<SummaryBloc>().add(SummaryCleared());
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    final bool? isAuthenticated = await showAdminPasswordDialog(context);

    if (isAuthenticated == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConnectionSettingsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool isConsolidated = authState.status == AuthStatus.consolidated;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: isConsolidated
              ? const Text('Resumen Gerencial (Consolidado)')
              : Image.asset('assets/saint_logo_blanco.png', height: 38),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: AppConstants.logoutTooltipText,
            ),
            if (!isConsolidated)
              IconButton(
                icon: const Icon(Icons.settings_applications_outlined),
                onPressed: () => _navigateToSettings(context),
                tooltip: AppConstants.settingsTooltipText,
              ),
            BlocBuilder<SummaryBloc, SummaryState>(
              builder: (context, state) {
                final isLoading = state.status == SummaryStatus.loading;
                return IconButton(
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  onPressed: isLoading ? null : _fetchInitialData,
                  tooltip: AppConstants.reloadDataTooltipText,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child:
              BlocBuilder<
                connection_bloc.ConnectionBloc,
                connection_bloc.ConnectionState
              >(
                builder: (context, connectionState) {
                  if (connectionState.activeConnection == null &&
                      !isConsolidated &&
                      connectionState.status !=
                          connection_bloc.ConnectionStatus.loading) {
                    return Center(
                      child: _buildErrorState(
                        AppConstants.noConnectionSelectedMessage,
                        context,
                      ),
                    );
                  }

                  return BlocBuilder<SummaryBloc, SummaryState>(
                    builder: (context, summaryState) {
                      if (summaryState.status == SummaryStatus.loading &&
                          summaryState.summary.totalNetSales == 0.0) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (summaryState.status == SummaryStatus.failure) {
                        return Center(
                          child: _buildErrorState(
                            summaryState.error ?? "Error desconocido",
                            context,
                          ),
                        );
                      }

                      return Column(
                        children: [
                          _buildDateFilter(context, summaryState),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async => _fetchInitialData(),
                              child: _buildManagementSummaryBody(
                                context,
                                summaryState,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.statusMessageError,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            "Error",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.statusMessageError,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              AppConstants.tryConnectButtonLabel,
              style: TextStyle(fontSize: 16),
            ),
            onPressed: _fetchInitialData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.textOnPrimaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, SummaryState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDateText = state.startDate != null
        ? dateFormat.format(state.startDate!)
        : 'Inicio';
    final endDateText = state.endDate != null
        ? dateFormat.format(state.endDate!)
        : 'Fin';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context, state),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Período de Análisis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$startDateText - $endDateText',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_off),
                tooltip: 'Limpiar filtro',
                onPressed: () => context.read<SummaryBloc>().add(
                  const SummaryDateRangeChanged(startDate: null, endDate: null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    SummaryState currentState,
  ) async {
    final initialRange = DateTimeRange(
      start: currentState.startDate ?? DateTime.now(),
      end: currentState.endDate ?? DateTime.now().add(const Duration(days: 1)),
    );

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
      locale: const Locale('es', 'ES'),
    );

    if (newRange != null) {
      context.read<SummaryBloc>().add(
        SummaryDateRangeChanged(
          startDate: newRange.start,
          endDate: newRange.end,
        ),
      );
    }
  }

  Widget _buildManagementSummaryBody(BuildContext context, SummaryState state) {
    final summary = state.summary;
    final deviceLocale = getDeviceLocale(context);
    final isConsolidated =
        context.read<AuthBloc>().state.status == AuthStatus.consolidated;

    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        if (!isConsolidated)
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.insights,
                color: AppColors.primaryOrange,
                size: 32,
              ),
              title: const Text(
                "Análisis y Proyecciones",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Ver proyecciones y análisis."),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalysisHubScreen(),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        _buildStyledSectionCard(
          title: "RESUMEN DE OPERACIONES",
          icon: Icons.show_chart,
          context: context,
          children: [
            _buildDataRow(
              "Total ventas netas:",
              formatNumber(summary.totalNetSales, deviceLocale),
              isTotal: true,
            ),
            const Divider(
              height: 24,
              thickness: 0,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              "Ventas netas a crédito:",
              formatNumber(summary.totalNetSalesCredit, deviceLocale),
              onTap: isConsolidated
                  ? null
                  : () {
                      final creditInvoices = state.allInvoices
                          .where(
                            (inv) =>
                                inv.credit > 0 &&
                                (inv.type == 'A' || inv.type == 'B'),
                          )
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionListScreen<Invoice>(
                            title: "Facturas a crédito",
                            items: creditInvoices,
                            itemBuilder: buildInvoiceListItem,
                          ),
                        ),
                      );
                    },
            ),
            _buildDataRow(
              "Ventas netas de contado:",
              formatNumber(summary.totalNetSalesCash, deviceLocale),
              onTap: isConsolidated
                  ? null
                  : () {
                      final cashInvoices = state.allInvoices.where((inv) {
                        final isPaidCreditSale =
                            inv.credit > 0 &&
                            !state.allReceivables.any(
                              (r) =>
                                  r.docNumber == inv.docnumber && r.balance > 0,
                            );
                        return (inv.cash > 0 || isPaidCreditSale) &&
                            (inv.type == 'A' || inv.type == 'B');
                      }).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionListScreen<Invoice>(
                            title: 'Facturas de contado',
                            items: cashInvoices,
                            itemBuilder: buildInvoiceListItem,
                          ),
                        ),
                      );
                    },
            ),
            const Divider(
              height: 24,
              thickness: 0.5,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              "Costo de mercancia vendida:",
              formatNumber(summary.costOfGoodsSold, deviceLocale),
            ),
            _buildDataRow(
              "Utilidad bruta:",
              formatNumber(summary.grossProfit, deviceLocale),
              isTotal: true,
              valueColor: summary.grossProfit >= 0
                  ? AppColors.positiveValue
                  : AppColors.negativeValue,
            ),
            const Divider(
              height: 24,
              thickness: 0.5,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              'Gastos y Costos (aproximados):',
              formatNumber(summary.fixedCosts, deviceLocale),
            ),
            _buildDataRow(
              "Utilidad o pérdida (aproximada):",
              formatNumber(summary.netProfitOrLoss, deviceLocale),
              isTotal: true,
              valueColor: summary.netProfitOrLoss >= 0
                  ? AppColors.positiveValue
                  : AppColors.negativeValue,
            ),
            _buildDataRow(
              "Total Cuentas por Pagar:",
              formatNumber(summary.totalPayables, deviceLocale),
              onTap: isConsolidated
                  ? null
                  : () {
                      final payables = state.allPayables
                          .where(
                            (ap) =>
                                ap.balance > 0 &&
                                ap.type != AppConstants.payableTypeAdvance,
                          )
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionListScreen<AccountPayable>(
                                title: 'Total Cuentas por pagar',
                                items: payables,
                                itemBuilder: buildAccountPayableListItem,
                              ),
                        ),
                      );
                    },
            ),
            _buildDataRow(
              "Total cuentas por Cobrar:",
              formatNumber(summary.totalReceivables, deviceLocale),
              onTap: isConsolidated
                  ? null
                  : () {
                      final receivables = state.allReceivables
                          .where(
                            (ar) =>
                                ar.balance > 0 &&
                                ar.type != AppConstants.receivableTypeAdvance,
                          )
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionListScreen<AccountReceivable>(
                                title: 'Total cuentas por cobrar',
                                items: receivables,
                                itemBuilder: buildAccountReceivableListItem,
                              ),
                        ),
                      );
                    },
            ),
            const Divider(
              height: 24,
              thickness: 0.5,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              "Inventario total:",
              isTotal: true,
              formatNumber(
                (summary.currentInventory - summary.fixtureInventory),
                deviceLocale,
              ),
            ),
            _buildDataRow(
              "Inventario de enseres:",
              formatNumber(summary.fixtureInventory, deviceLocale),
            ),
            const Divider(
              height: 24,
              thickness: 0.5,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              "Cuentas por cobrar vencidas:",
              formatNumber(summary.overdueReceivables, deviceLocale),
              valueColor: summary.overdueReceivables > 0
                  ? AppColors.negativeValue
                  : null,
              onTap: isConsolidated
                  ? null
                  : () {
                      final now = DateTime.now();
                      final overdue = state.allReceivables
                          .where(
                            (ar) =>
                                ar.balance > 0 &&
                                ar.dueDate.isBefore(now) &&
                                ar.type != AppConstants.receivableTypeAdvance,
                          )
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionListScreen<AccountReceivable>(
                                title: 'Cuentas por cobrar vencidas',
                                items: overdue,
                                itemBuilder: buildAccountReceivableListItem,
                              ),
                        ),
                      );
                    },
            ),
            _buildDataRow(
              "Cuentas por Pagar Vencidas:",
              formatNumber(summary.overduePayables, deviceLocale),
              valueColor: summary.overduePayables > 0
                  ? AppColors.negativeValue
                  : null,
              onTap: isConsolidated
                  ? null
                  : () {
                      final now = DateTime.now();
                      final overdue = state.allPayables
                          .where(
                            (ap) =>
                                ap.balance > 0 &&
                                ap.dueDate.isBefore(now) &&
                                ap.type != AppConstants.payableTypeAdvance,
                          )
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionListScreen<AccountPayable>(
                                title: 'Cuentas por pagar vencidas',
                                items: overdue,
                                itemBuilder: buildAccountPayableListItem,
                              ),
                        ),
                      );
                    },
            ),
            _buildDataRow(
              'Pagos anticipados de Clientes:',
              formatNumber(summary.customerAdvances, deviceLocale),
            ),
          ],
        ),
        _buildStyledSectionCard(
          title: "RESUMEN DE IMPUESTOS",
          icon: Icons.receipt_long,
          context: context,
          children: [
            _buildDataRow(
              "Total I.V.A. por Pagar:",
              formatNumber(
                (summary.salesVat - summary.purchasesVat),
                deviceLocale,
              ),
              isTotal: true,
              valueColor: (summary.salesVat - summary.purchasesVat) < 0
                  ? AppColors.statusMessageError
                  : AppColors.statusMessageSuccess,
            ),
            const Divider(
              height: 24,
              thickness: 0.5,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              "I.V.A. en Ventas:",
              formatNumber(summary.salesVat, deviceLocale),
            ),
            _buildDataRow(
              "IVA Retenido por Clientes:",
              formatNumber(summary.salesIvaWithheld, deviceLocale),
            ),
            _buildDataRow(
              "I.S.L.R. Retenido por Clientes:",
              formatNumber(summary.salesIslrWithheld, deviceLocale),
            ),
            const Divider(
              height: 24,
              thickness: 0.5,
              color: AppColors.primaryOrange,
            ),
            _buildDataRow(
              "I.V.A. en Compras:",
              formatNumber(summary.purchasesVat, deviceLocale),
            ),
            _buildDataRow(
              "IVA Retenido a Proveedores:",
              formatNumber(summary.purchasesIvaWithheld, deviceLocale),
            ),
            _buildDataRow(
              "I.S.L.R. Retenido a Proveedores:",
              formatNumber(summary.purchasesIslrWithheld, deviceLocale),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyledSectionCard({
    required String title,
    required IconData icon,
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryBlue,
            child: Row(
              children: [
                Icon(icon, color: AppColors.iconOnPrimary, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
    VoidCallback? onTap,
  }) {
    final Color finalValueColor = valueColor ?? AppColors.textPrimary;
    final labelStyle = TextStyle(
      fontSize: 16,
      color: AppColors.textSecondary,
      fontWeight: isTotal ? FontWeight.w500 : FontWeight.normal,
    );
    final valueStyle = TextStyle(
      fontSize: 17,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
      color: finalValueColor,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: Text(label, style: labelStyle)),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Text(value, style: valueStyle, textAlign: TextAlign.end),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
