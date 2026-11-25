import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import '../services/database.dart';

class AirportField extends StatelessWidget {
  const AirportField({
    super.key,
    required this.code,
    required this.label,
    required this.selectedAirport,
    required this.onTap,
    this.isArrival = false,
  });
  final String code;
  final String label;
  final Airport? selectedAirport;
  final VoidCallback onTap;
  final bool isArrival;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayCode = code.isNotEmpty ? code : '';
    final countryCode = selectedAirport?.isoCountry;

    final flag = countryCode != null && countryCode.length == 2
        ? SizedBox(
            width: 28,
            height: 20,
            child: CountryFlag.fromCountryCode(
              countryCode,
              theme: const ImageTheme(shape: RoundedRectangle(4)),
            ),
          )
        : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isArrival
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flag != null && !isArrival) ...[flag, const SizedBox(width: 8)],
            if (displayCode.isNotEmpty)
              Flexible(
                child: Text(
                  displayCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            if (flag != null && isArrival) ...[const SizedBox(width: 8), flag],
          ],
        ),
      ),
    );
  }
}
