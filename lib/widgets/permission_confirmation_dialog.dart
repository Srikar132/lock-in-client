import 'package:flutter/material.dart';

/// Dialog shown to confirm if user has enabled permission after returning from settings
class PermissionConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirmed;
  final VoidCallback onNotYet;

  const PermissionConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirmed,
    required this.onNotYet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: onNotYet, child: const Text('Not Yet')),
        ElevatedButton(
          onPressed: onConfirmed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Yes, I enabled it'),
        ),
      ],
    );
  }

  /// Show permission confirmation dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirmed,
    required VoidCallback onNotYet,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PermissionConfirmationDialog(
        title: title,
        message: message,
        onConfirmed: onConfirmed,
        onNotYet: onNotYet,
      ),
    );
  }
}
