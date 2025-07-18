import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saint_bi/core/data/sources/local/database_service.dart';
import 'package:saint_bi/core/data/repositories/connection_repository.dart';
import 'package:saint_bi/core/utils/security_service.dart';
import 'package:saint_bi/ui/theme/app_colors.dart';

Future<bool?> showAdminPasswordDialog(BuildContext context) {
  final passController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      final isLoadingNotifier = ValueNotifier<bool>(false);
      final errorTextNotifier = ValueNotifier<String?>(null);

      return ValueListenableBuilder<bool>(
        valueListenable: isLoadingNotifier,
        builder: (context, isLoading, child) {
          return AlertDialog(
            backgroundColor: AppColors.dialogBackground,
            title: const Text('Acceso de Administrador'),
            content: Form(
              key: formKey,
              child: ValueListenableBuilder<String?>(
                valueListenable: errorTextNotifier,
                builder: (context, errorText, child) {
                  return TextFormField(
                    controller: passController,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      errorText: errorText,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese la contraseña';
                      }
                      return null;
                    },
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          isLoadingNotifier.value = true;
                          errorTextNotifier.value = null;

                          try {
                            final repo = dialogContext
                                .read<ConnectionRepository>();
                            final settings = await repo.getAppSettings();
                            final storedHash =
                                settings[DatabaseService
                                    .columnAdminPasswordHash];

                            if (storedHash == null || storedHash.isEmpty) {
                              errorTextNotifier.value =
                                  'Error: No hay contraseña configurada.';
                            } else {
                              final isValid = SecurityService.verifyPassword(
                                passController.text,
                                storedHash,
                              );
                              if (isValid) {
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop(true);
                                }
                                return;
                              } else {
                                errorTextNotifier.value =
                                    'Contraseña incorrecta.';
                              }
                            }
                          } catch (e) {
                            errorTextNotifier.value = 'Error: ${e.toString()}';
                          }
                          isLoadingNotifier.value = false;
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Ingresar'),
              ),
            ],
          );
        },
      );
    },
  );
}
