import 'package:flutter/material.dart';

ButtonStyle pillButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  return ElevatedButton.styleFrom(
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    elevation: 0,
    backgroundColor: theme.colorScheme.surfaceVariant,
    foregroundColor: theme.colorScheme.onSurface,
    side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
    textStyle: const TextStyle(fontSize: 16),
  );
}
