import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_intelligence/config/app_colors.dart';
import 'package:saint_intelligence/models/invoice.dart';
import 'package:saint_intelligence/models/invoice_item.dart';
import 'package:saint_intelligence/models/product.dart';
import 'package:saint_intelligence/providers/managment_summary_notifier.dart';
import 'package:saint_intelligence/utils/formatters.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = getDeviceLocale(context);

    final notifier =
        Provider.of<ManagementSummaryNotifier>(context, listen: false);

    final List<InvoiceItem> items = notifier.allInvoiceItems
        .where((item) =>
            item.docNumber == invoice.docnumber && item.type == invoice.type)
        .toList();

    final isReturned = invoice.sign == -1;

    final List<Product> allProducts = notifier.allProducts;

    return Scaffold(
      appBar: AppBar(
        title: isReturned
            ? Text('Detalle Devolución ${invoice.docnumber}')
            : Text('Detalle Factura ${invoice.docnumber}'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (isReturned)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DEVOLUCIÓN',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          _buildDetailCard(
            title: 'Informacion del Cliente',
            icon: Icons.person,
            children: [
              _buildDetailRow('Cliente:', invoice.client),
              _buildDetailRow('Vendedor:', invoice.salesperson),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: isReturned
                ? 'Totales de la devolución'
                : 'Totales de la factura',
            icon: Icons.monetization_on,
            children: [
              _buildDetailRow(
                  'Total Neto:', formatNumber(invoice.amount, deviceLocale)),
              _buildDetailRow(
                  'Impuestos:', formatNumber(invoice.amounttax, deviceLocale)),
              _buildDetailRow(
                  'Total General:',
                  formatNumber(
                      (invoice.amount + invoice.amounttax), deviceLocale)),
              const Divider(),
              _buildDetailRow(
                  'A Credito:', formatNumber(invoice.credit, deviceLocale)),
              _buildDetailRow(
                  'De Contado:', formatNumber(invoice.cash, deviceLocale)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: isReturned ? 'Productos Devueltos' : 'Productos Facturados',
            icon: Icons.inventory,
            children: items.expand((item) {
              final product = allProducts.firstWhere(
                (p) => p.code == item.productCode,
                orElse: () => Product(
                    code: item.productCode,
                    description: 'Producto no encontrado.',
                    cost: 0,
                    stock: 0),
              );

              return [
                _buildDetailRow('Codigo:', product.code),
                _buildDetailRow('Nombre:', product.description),
                _buildDetailRow(
                    isReturned ? 'Cantidad devuelta:' : 'Cantidad facturada:',
                    formatNumber(item.qty, deviceLocale)),
                _buildDetailRow('Costo del producto:',
                    formatNumber(item.cost, deviceLocale)),
                _buildDetailRow(
                    'Precio de venta:', formatNumber(item.price, deviceLocale)),
                _buildDetailRow(
                    'Impuesto en venta:', formatNumber(item.tax, deviceLocale)),
                const Divider(thickness: 0.5, color: AppColors.primaryOrange),
              ];
            }).toList(),
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
                      color: AppColors.primaryBlue),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
