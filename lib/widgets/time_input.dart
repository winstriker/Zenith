import 'package:flutter/material.dart';
import '../utils/time_input_formatter.dart';

class TimeInput extends StatelessWidget {
  const TimeInput({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.textAlign = TextAlign.center,
  });
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The room the text leaves for the cursor after it.
    final caret = textAlign == TextAlign.end ? 3.0 : 0.0;

    return Transform.translate(
      offset: Offset(caret, 0),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        inputFormatters: [TimeInputFormatter()],
        textAlign: textAlign,
        decoration: InputDecoration(
          // On the baseline of the larger input: up to its centre.
          hint: Transform.translate(
            offset: Offset(-caret, -1.5),
            child: Text(
              hint,
              textAlign: textAlign,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 1),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
