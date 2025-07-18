import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/data/models/account_payable.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class PayableDetailScreen extends StatelessWidget {
  final AccountPayable accountPayable;

  const PayableDetailScreen({super.key, required this.accountPayable});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = getDeviceLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle CxP ${accountPayable.docNumber}'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailCard(
            title: 'Información del Documento',
            icon: Icons.receipt_long,
            children: [
              _buildDetailRow('Número de Documento:', accountPayable.docNumber),
              _buildDetailRow('Tipo de Operación:', accountPayable.type),
              _buildDetailRow(
                'Fecha de Emisión:',
                DateFormat('yyyy-MM-dd').format(accountPayable.emissionDate),
              ),
              _buildDetailRow(
                'Fecha de Vencimiento:',
                DateFormat('yyyy-MM-dd').format(accountPayable.dueDate),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: 'Montos',
            icon: Icons.monetization_on,
            children: [
              _buildDetailRow(
                'Monto Total:',
                formatNumber(accountPayable.amount, deviceLocale),
              ),
              const Divider(),
              _buildDetailRow(
                'Comisión:',
                formatNumber(accountPayable.comission, deviceLocale),
              ),
              _buildDetailRow(
                'Saldo Pendiente:',
                formatNumber(accountPayable.balance, deviceLocale),
                isBold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
