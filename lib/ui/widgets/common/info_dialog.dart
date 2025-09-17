import 'package:flutter/material.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

void showInfoDialog({
  required BuildContext context,
  required String title,
  required String content,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info, color: AppColors.accentColor),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBlue,
                ),
              ),
            ),
          ],
        ),
        content: Text(content, style: TextStyle(fontSize: 15, height: 1.4)),
        actions: <Widget>[
          TextButton(
            child: const Text("Entendido"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
