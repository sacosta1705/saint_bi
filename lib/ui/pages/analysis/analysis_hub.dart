import 'package:flutter/material.dart';
import 'package:saint_bi/ui/pages/analysis/combined_forecast_screen.dart';
import 'package:saint_bi/ui/pages/analysis/kpi_dashboard_screen.dart';
import 'package:saint_bi/ui/pages/analysis/market_basket_screen.dart';
import 'package:saint_bi/ui/pages/analysis/monthly_sales_screen.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';
import 'package:saint_bi/ui/widgets/common/info_dialog.dart';

class AnalysisOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget destinationScreen;
  final String explanation; // CAMPO AÑADIDO

  const AnalysisOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.destinationScreen,
    required this.explanation, // CAMPO AÑADIDO
  });
}

class AnalysisHubScreen extends StatelessWidget {
  const AnalysisHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AnalysisOption> options = [
      const AnalysisOption(
        title: 'Indicadores de gestión',
        subtitle: 'Métricas clave de rendimiento (KPIs)',
        icon: Icons.monetization_on,
        destinationScreen: KpiDashboardScreen(),
        explanation:
            'Visualiza los Indicadores Clave de Rendimiento (KPIs) más importantes para medir la salud financiera y operativa de tu negocio. Incluye métricas como márgenes de utilidad, rotación de inventario, liquidez y eficiencia en cobros.',
      ),
      const AnalysisOption(
        title: 'Ventas por mes',
        subtitle: 'Gráfico de barras de ventas mensuales por año.',
        icon: Icons.bar_chart,
        destinationScreen: MonthlySalesScreen(),
        explanation:
            'Compara el rendimiento de las ventas de cada mes a lo largo de un año específico. Este gráfico de barras te permite identificar fácilmente los meses de mayor y menor actividad, así como detectar patrones estacionales en tus ingresos.',
      ),
      const AnalysisOption(
        title: 'Proyección de Ventas',
        subtitle: 'Estima el comportamiento futuro de tus ventas.',
        icon: Icons.insights,
        destinationScreen: CombinedForecastScreen(),
        explanation:
            'Esta herramienta utiliza dos modelos estadísticos para estimar tus ventas futuras:\n\n1. Proyección Lineal: Se basa en la tendencia general de todo tu historial de ventas.\n\n2. Proyección Flexible: Le da más importancia a tus ventas más recientes para adaptarse a cambios en el mercado.\n\nUsa ambos para obtener una visión completa del posible futuro de tus ingresos.',
      ),
      const AnalysisOption(
        title: 'Análisis de Canasta de Mercado',
        subtitle: 'Descubre qué productos se venden juntos.',
        icon: Icons.shopping_basket,
        destinationScreen: MarketBasketScreen(),
        explanation:
            'Analiza los comprobantes de venta para encontrar patrones de compra y descubrir qué productos suelen comprar los clientes en una misma transacción. Esta información es muy útil para crear promociones, organizar la mercancía y mejorar tus estrategias de venta cruzada.',
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
              subtitle: option.subtitle.isNotEmpty
                  ? Text(option.subtitle)
                  : null,
              // WIDGET MODIFICADO
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    color: AppColors.primaryBlue,
                    tooltip: 'Más información',
                    onPressed: () {
                      showInfoDialog(
                        context: context,
                        title: option.title,
                        content: option.explanation,
                      );
                    },
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
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
