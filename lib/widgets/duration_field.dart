import 'package:flutter/material.dart';

import '../utils/duration_formatter.dart';
import '../utils/time_input_formatter.dart';

/// A duration typed as HH:MM.
///
/// [onChanged] gets the duration once it is complete, or null when the field
/// is emptied; half-typed values are left to the validator. When [value]
/// changes from outside (another field worked it out), the text follows,
/// unless the field is being typed in.
class DurationField extends StatefulWidget {
  const DurationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = '00:00',
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.style,
    this.textAlign = TextAlign.start,
  });

  final Duration? value;
  final ValueChanged<Duration?> onChanged;
  final String hintText;
  final bool enabled;
  final InputDecoration decoration;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  late final _controller = TextEditingController(text: _format(widget.value));
  final _focus = FocusNode();

  static String _format(Duration? d) =>
      d == null ? '' : DurationFormatter.hm(d);

  @override
  void didUpdateWidget(DurationField old) {
    super.didUpdateWidget(old);
    if (!_isStale) return;
    // Not now: changing the text tells the enclosing Form, which can't be
    // rebuilt while this field is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isStale) _controller.text = _format(widget.value);
    });
  }

  /// Whether the text shows something else than [DurationField.value], and
  /// isn't being typed in.
  bool get _isStale =>
      !_focus.hasFocus &&
      DurationFormatter.parseHm(_controller.text) != widget.value;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [TimeInputFormatter()],
      textAlign: widget.textAlign,
      style: widget.style,
      decoration: widget.decoration.copyWith(hintText: widget.hintText),
      validator: (text) =>
          text != null &&
              text.isNotEmpty &&
              DurationFormatter.parseHm(text) == null
          ? 'HH:MM'
          : null,
      onChanged: (text) {
        if (text.isEmpty) {
          widget.onChanged(null);
        } else if (DurationFormatter.parseHm(text) case final d?) {
          widget.onChanged(d);
        }
      },
    );
  }
}
