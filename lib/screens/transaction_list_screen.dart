import 'package:flutter/material.dart';
import 'package:saint_intelligence/config/app_colors.dart';

typedef ItemWidgetBuilder<T> = Widget Function(BuildContext context, T item);

class TransactionListScreen<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final ItemWidgetBuilder<T> itemBuilder;
  const TransactionListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.appBarForeground,
        ),
        body: items.isEmpty
            ? const Center(
                child: Text("No hay datos para mostrar."),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return itemBuilder(context, item);
                },
              ));
  }
}
