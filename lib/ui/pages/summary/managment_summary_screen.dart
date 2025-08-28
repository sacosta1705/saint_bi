// lib/ui/pages/summary/managment_summary_screen.dart
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
import 'package:saint_bi/core/data/models/management_summary.dart';
import 'package:saint_bi/core/services/ai_analysis_service.dart';
import 'package:saint_bi/core/utils/constants.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/pages/analysis/ai_analysis_screen.dart';
import 'package:saint_bi/ui/pages/analysis/analysis_hub.dart';
import 'package:saint_bi/ui/pages/auth/login_screen.dart';
import 'package:saint_bi/ui/pages/connection/connection_settings_screen.dart';
import 'package:saint_bi/ui/pages/transaction_details/transaction_list_screen.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';
import 'package:saint_bi/ui/widgets/common/admin_password_dialog.dart';
import 'package:saint_bi/ui/widgets/feature_specific/summary/kpi_card.dart';
import 'package:saint_bi/ui/widgets/feature_specific/summary/summary_section_card.dart';
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

  Future<void> _runAiAnalysis() async {
    final summary = context.read<SummaryBloc>().state.summary;
    final aiService = context.read<AiAnalysisService>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt = aiService.createPromptFromSummary(summary);
      final result = await aiService.getAnalysis(prompt);

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiAnalysisScreen(analysisResult: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al realizar el analisis: $e"),
            backgroundColor: AppColors.statusMessageError,
          ),
        );
      }
    }
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
                    return _buildErrorState(
                      AppConstants.noConnectionSelectedMessage,
                    );
                  }

                  return BlocBuilder<SummaryBloc, SummaryState>(
                    builder: (context, summaryState) {
                      if (summaryState.status == SummaryStatus.loading &&
                          summaryState.summary.totalNetSales == 0.0) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (summaryState.status == SummaryStatus.failure) {
                        return _buildErrorState(
                          summaryState.error ?? "Error desconocido",
                        );
                      }

                      return _buildScrollView(
                        context,
                        summaryState,
                        isConsolidated,
                      );
                    },
                  );
                },
              ),
        ),
      ),
    );
  }

  Widget _buildScrollView(
    BuildContext context,
    SummaryState state,
    bool isConsolidated,
  ) {
    final summary = state.summary;
    final deviceLocale = getDeviceLocale(context);

    return RefreshIndicator(
      onRefresh: () async => _fetchInitialData(),
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isConsolidated, state),
          SliverToBoxAdapter(child: _buildDateFilter(context, state)),
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, "Indicadores Clave"),
          ),
          _buildKpiCarousel(summary, deviceLocale),
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, "Detalles Financieros"),
          ),
          if (!isConsolidated)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 15),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ElevatedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text("Análisis y proyecciones"),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalysisHubScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("Análisis con IA"),
                    onPressed: _runAiAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                  ),
                ]),
              ),
            ),
          _buildFinancialDetailsList(
            summary,
            deviceLocale,
            state,
            isConsolidated,
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    bool isConsolidated,
    SummaryState state,
  ) {
    return SliverAppBar(
      title: isConsolidated
          ? const Text('Resumen Consolidado')
          : Image.asset('assets/saint_logo_blanco.png', height: 38),
      floating: true,
      pinned: true,
      snap: false,
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
        IconButton(
          icon: (state.status == SummaryStatus.loading)
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(Icons.refresh_rounded),
          onPressed: (state.status == SummaryStatus.loading)
              ? null
              : _fetchInitialData,
          tooltip: AppConstants.reloadDataTooltipText,
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.negativeValue,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              "Error",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.negativeValue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppConstants.tryConnectButtonLabel),
              onPressed: _fetchInitialData,
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      Text(
                        'Período de Análisis',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$startDateText - $endDateText',
                        style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDarkBlue),
      ),
    );
  }

  Widget _buildKpiCarousel(ManagementSummary summary, String locale) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 150,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            KpiCard(
              title: "Utilidad Bruta",
              value: formatNumber(summary.grossProfit, locale),
              icon: Icons.trending_up,
              gradient: AppColors.kpiGradientGreen,
            ),
            KpiCard(
              title: "Ventas Netas",
              value: formatNumber(summary.totalNetSales, locale),
              icon: Icons.monetization_on,
              gradient: AppColors.kpiGradientBlue,
            ),
            KpiCard(
              title: "CxC Vencidas",
              value: formatNumber(summary.overdueReceivables, locale),
              icon: Icons.warning_amber_rounded,
              gradient: AppColors.kpiGradientRed,
            ),
            KpiCard(
              title: "Inventario Total",
              value: formatNumber(
                summary.currentInventory - summary.fixtureInventory,
                locale,
              ),
              icon: Icons.inventory_2_outlined,
              gradient: AppColors.kpiGradientOrange,
            ),
          ],
        ),
      ),
    );
  }

  // *** ESTE MÉTODO HA SIDO CAMBIADO ***
  Widget _buildFinancialDetailsList(
    ManagementSummary summary,
    String locale,
    SummaryState state,
    bool isConsolidated,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          SummarySectionCard(
            title: "Operaciones",
            icon: Icons.show_chart,
            data: {
              "Ventas a Crédito": formatNumber(
                summary.totalNetSalesCredit,
                locale,
              ),
              "Ventas de Contado": formatNumber(
                summary.totalNetSalesCash,
                locale,
              ),
              "Costo de Ventas": formatNumber(summary.costOfGoodsSold, locale),
              "Gastos y Costos": formatNumber(summary.fixedCosts, locale),
              "Utilidad Neta (Aprox)": formatNumber(
                summary.netProfitOrLoss,
                locale,
              ),
            },
            onTap: isConsolidated
                ? null
                : () {
                    final allInvoices = state.allInvoices
                        .where((inv) => inv.type == 'A' || inv.type == 'B')
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionListScreen<Invoice>(
                          title: 'Facturas y Devoluciones',
                          items: allInvoices,
                          itemBuilder: buildInvoiceListItem,
                        ),
                      ),
                    );
                  },
          ),
          SummarySectionCard(
            title: "Impuestos",
            icon: Icons.receipt_long,
            data: {
              "I.V.A. en Ventas": formatNumber(summary.salesVat, locale),
              "I.V.A. en Compras": formatNumber(summary.purchasesVat, locale),
              "Retenido por Clientes": formatNumber(
                summary.salesIvaWithheld,
                locale,
              ),
              "Retenido a Proveedores": formatNumber(
                summary.purchasesIvaWithheld,
                locale,
              ),
            },
          ),
          SummarySectionCard(
            title: "Cuentas por Cobrar",
            icon: Icons.person_add_alt_1,
            data: {
              "Total CxC": formatNumber(summary.totalReceivables, locale),
              "CxC Vencidas": formatNumber(summary.overdueReceivables, locale),
              "Anticipos de Clientes": formatNumber(
                summary.customerAdvances,
                locale,
              ),
            },
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
                              title: 'Cuentas por Cobrar',
                              items: receivables,
                              itemBuilder: buildAccountReceivableListItem,
                            ),
                      ),
                    );
                  },
          ),
          SummarySectionCard(
            title: "Cuentas por Pagar",
            icon: Icons.business_center,
            data: {
              "Total CxP": formatNumber(summary.totalPayables, locale),
              "CxP Vencidas": formatNumber(summary.overduePayables, locale),
            },
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
                              title: 'Cuentas por Pagar',
                              items: payables,
                              itemBuilder: buildAccountPayableListItem,
                            ),
                      ),
                    );
                  },
          ),
        ]),
      ),
    );
  }
}
