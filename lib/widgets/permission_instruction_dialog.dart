import 'package:flutter/material.dart';

/// Custom bottom sheet widget for showing permission instructions
class PermissionInstructionDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<String> steps;
  final VoidCallback onAllowPressed;
  final String allowButtonText;

  const PermissionInstructionDialog({
    super.key,
    required this.title,
    required this.description,
    required this.steps,
    required this.onAllowPressed,
    this.allowButtonText = 'Allow',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 20),

          // Steps
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(step, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAllowPressed();
                  },
                  child: Text(allowButtonText),
                ),
              ),
            ],
          ),

          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  /// Show the permission instruction dialog as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> steps,
    required VoidCallback onAllowPressed,
    String allowButtonText = 'Allow',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionInstructionDialog(
        title: title,
        description: description,
        steps: steps,
        onAllowPressed: onAllowPressed,
        allowButtonText: allowButtonText,
      ),
    );
  }
}
