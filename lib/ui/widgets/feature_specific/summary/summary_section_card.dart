// lib/ui/widgets/feature_specific/summary/summary_section_card.dart
import 'package:flutter/material.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class SummarySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, String> data;
  final VoidCallback? onTap;

  const SummarySectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0), // Espacio entre tarjetas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Encabezado de la Tarjeta ---
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

          // --- Contenido de la Tarjeta ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5, // Dar más espacio a la etiqueta
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow
                              .visible, // Permitir que el texto se ajuste
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4, // Espacio para el valor
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
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
