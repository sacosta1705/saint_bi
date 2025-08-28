import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:saint_bi/ui/theme/app_colors.dart';

class AiAnalysisScreen extends StatelessWidget {
  final String analysisResult;

  const AiAnalysisScreen({super.key, required this.analysisResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analisis de resumen gerencial."),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Analisis y recomendaciones",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            MarkdownBody(
              data: analysisResult,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: const TextStyle(fontSize: 16, height: 1.5),
                    h3: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 2,
                      color: AppColors.primaryDarkBlue,
                    ),
                    h4: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 2,
                      color: AppColors.primaryDarkBlue,
                    ),
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                "Nota: Este es un análisis generado por IA y debe ser utilizado únicamente como una herramienta de apoyo. Verifique siempre los datos y consulte con un profesional antes de tomar decisiones financieras.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
