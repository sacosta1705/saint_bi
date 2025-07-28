import 'package:flutter/material.dart';
import 'package:saint_bi/ui/pages/analysis/kpi_dashboard_screen.dart';
import 'package:saint_bi/ui/pages/analysis/sales_forecast_screen.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class AnalysisOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget destinationScreen;

  const AnalysisOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.destinationScreen,
  });
}

class AnalysisHubScreen extends StatelessWidget {
  const AnalysisHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AnalysisOption> options = [
      const AnalysisOption(
        title: 'Indicadores de gestión',
        subtitle: '',
        icon: Icons.monetization_on,
        destinationScreen: KpiDashboardScreen(), // <-- Tu nueva pantalla
      ),
      const AnalysisOption(
        title: 'Proyección de Ventas (Suavización Exponencial Simple)',
        subtitle: '',
        icon: Icons.insights,
        destinationScreen: SalesForecastScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Análisis'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];

          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              leading: Icon(
                option.icon,
                size: 40,
                color: AppColors.primaryOrange,
              ),
              title: Text(
                option.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.primaryBlue,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => option.destinationScreen),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
