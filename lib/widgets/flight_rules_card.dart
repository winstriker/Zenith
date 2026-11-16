import 'package:flutter/material.dart';

import '../models/logbook_entry.dart';
import '../utils/duration_formatter.dart';
import 'duration_field.dart';
import 'overridden_icon.dart';

/// Flight rules, and the time flown under IFR, under VFR and at night.
///
/// IFR and VFR time can only be typed in for flights that change rules on
/// the way: the one follows from the other and the block time. Night time is
/// always worked out.
class FlightRulesCard extends StatelessWidget {
  const FlightRulesCard({
    super.key,
    required this.flightRules,
    this.onFlightRulesChanged,
    this.instrumentTime,
    this.visualTime,
    this.nightTime,
    this.onInstrumentTimeChanged,
    this.onVisualTimeChanged,
    this.blockTimeKnown = true,
    this.timeError,
    this.instrumentOverridden = false,
    this.visualOverridden = false,
    this.nightOverridden = false,
  });

  final String flightRules;
  final ValueChanged<String>? onFlightRulesChanged;
  final Duration? instrumentTime;
  final Duration? visualTime;
  final Duration? nightTime;
  final ValueChanged<Duration?>? onInstrumentTimeChanged;
  final ValueChanged<Duration?>? onVisualTimeChanged;

  /// Without a block time the VFR time can't give the IFR time.
  final bool blockTimeKnown;
  final String? timeError;

  /// Which of the times shown are logbook overrides rather than the flight's.
  final bool instrumentOverridden;
  final bool visualOverridden;
  final bool nightOverridden;

  bool get _editable => onFlightRulesChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final mixed =
        _editable && FlightRulesKind.of(flightRules) == FlightRulesKind.mixed;

    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FLIGHT RULES', style: labelStyle),
                      const SizedBox(height: 2),
                      if (!_editable)
                        Text(
                          flightRules,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        )
                      else
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: flightRules,
                            isDense: true,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'VFR',
                                child: Text('VFR'),
                              ),
                              DropdownMenuItem(
                                value: 'IFR',
                                child: Text('IFR'),
                              ),
                              DropdownMenuItem(
                                value: 'Y',
                                child: Text('Y - IFR/VFR'),
                              ),
                              DropdownMenuItem(
                                value: 'Z',
                                child: Text('Z - VFR/IFR'),
                              ),
                              DropdownMenuItem(
                                value: 'Z2',
                                child: Text('Z2 - VFR/IFR'),
                              ),
                            ],
                            onChanged: (v) => onFlightRulesChanged!(v ?? 'VFR'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimeCell(
                    label: 'IFR',
                    labelStyle: labelStyle,
                    child: mixed
                        ? _input(
                            context,
                            instrumentTime,
                            onInstrumentTimeChanged,
                          )
                        : _value(context, instrumentTime, instrumentOverridden),
                  ),
                  _TimeCell(
                    label: 'VFR',
                    labelStyle: labelStyle,
                    child: mixed
                        ? _input(
                            context,
                            visualTime,
                            onVisualTimeChanged,
                            enabled: blockTimeKnown,
                          )
                        : _value(context, visualTime, visualOverridden),
                  ),
                  _TimeCell(
                    label: 'NIGHT',
                    labelStyle: labelStyle,
                    child: _value(context, nightTime, nightOverridden),
                  ),
                ],
              ),
            ),
            if (timeError != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(
                  timeError!,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static TextStyle? _valueStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

  Widget _value(BuildContext context, Duration? d, bool overridden) => Row(
    children: [
      Text(
        d == null ? '--:--' : DurationFormatter.hm(d),
        style: _valueStyle(context),
      ),
      if (overridden) ...[const SizedBox(width: 2), const OverriddenIcon()],
    ],
  );

  Widget _input(
    BuildContext context,
    Duration? value,
    ValueChanged<Duration?>? onChanged, {
    bool enabled = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    return DurationField(
      value: value,
      enabled: enabled && onChanged != null,
      onChanged: onChanged ?? (_) {},
      style: _valueStyle(context),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          fontWeight: FontWeight.w500,
        ),
        border: const UnderlineInputBorder(),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.label,
    required this.labelStyle,
    required this.child,
  });

  final String label;
  final TextStyle? labelStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 2),
            child,
          ],
        ),
      ),
    );
  }
}
