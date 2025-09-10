import 'package:flutter/material.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class SummarySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, double> data;
  final Map<String, double> previousData;
  final VoidCallback? onTap;

  const SummarySectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    this.previousData = const {},
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deviceLocale = getDeviceLocale(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: onTap,
                    tooltip: 'Ver detalle',
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: data.entries.map((entry) {
                final previousValue = previousData[entry.key];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatNumber(entry.value, deviceLocale),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (previousValue != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: _PercentageChangeChip(
                                currentValue: entry.value,
                                previousValue: previousValue,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentageChangeChip extends StatelessWidget {
  final double currentValue;
  final double previousValue;

  const _PercentageChangeChip({
    required this.currentValue,
    required this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    // Si el valor anterior es 0, un cambio porcentual es indefinido.
    // No se muestra el chip en este caso para evitar confusiones.
    if (previousValue == 0) {
      return const SizedBox.shrink();
    }

    // Usamos el valor absoluto en el denominador para manejar correctamente los valores negativos.
    final double change =
        ((currentValue - previousValue) / previousValue.abs()) * 100;

    final Color color;
    final IconData icon;

    // Se establece un umbral para considerar un cambio como significativo.
    if (change > 0.5) {
      color = AppColors.positiveValue;
      icon = Icons.arrow_upward;
    } else if (change < -0.5) {
      color = AppColors.negativeValue;
      icon = Icons.arrow_downward;
    } else {
      color = AppColors.textSecondary;
      icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            '${change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
