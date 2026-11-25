import 'package:flutter/material.dart';
import '../utils/time_input_formatter.dart';

class TimeInput extends StatelessWidget {
  const TimeInput({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
  });
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      inputFormatters: [TimeInputFormatter()],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      onChanged: onChanged,
    );
  }
}
