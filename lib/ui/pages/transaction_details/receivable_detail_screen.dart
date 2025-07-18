import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saint_bi/core/data/models/account_receivable.dart';
import 'package:saint_bi/core/utils/formatters.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

class ReceivableDetailScreen extends StatelessWidget {
  final AccountReceivable accountReceivable;

  const ReceivableDetailScreen({super.key, required this.accountReceivable});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = getDeviceLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle CxC ${accountReceivable.docNumber}'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDetailCard(
            title: 'Informacion del documento',
            icon: Icons.receipt_long,
            children: [
              _buildDetailRow(
                'Numero de documento:',
                accountReceivable.docNumber,
              ),
              _buildDetailRow('Tipo de operacion:', accountReceivable.type),
              _buildDetailRow(
                'Emision:',
                DateFormat('yyyy-MM-dd').format(accountReceivable.emissionDate),
              ),
              _buildDetailRow(
                'Vencimiento:',
                DateFormat('yyyy-MM-dd').format(accountReceivable.dueDate),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: 'Detalle',
            icon: Icons.monetization_on,
            children: [
              _buildDetailRow(
                'Monto total:',
                formatNumber(accountReceivable.amount, deviceLocale),
              ),
              _buildDetailRow(
                'Monto neto:',
                formatNumber(accountReceivable.netAmount, deviceLocale),
              ),
              _buildDetailRow(
                'Impuestos:',
                formatNumber(accountReceivable.taxAmount, deviceLocale),
              ),
              _buildDetailRow(
                'Comision:',
                formatNumber(accountReceivable.commission, deviceLocale),
              ),
              _buildDetailRow(
                'Saldo pendiente:',
                formatNumber(accountReceivable.balance, deviceLocale),
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
