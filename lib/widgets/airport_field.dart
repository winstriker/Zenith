import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import '../services/database.dart';

class AirportField extends StatelessWidget {
  final String code;
  final String label;
  final Airport? selectedAirport;
  final VoidCallback onTap;
  final bool isArrival;

  const AirportField({
    super.key,
    required this.code,
    required this.label,
    required this.selectedAirport,
    required this.onTap,
    this.isArrival = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayCode = code.isNotEmpty ? code : '';
    final countryCode = selectedAirport?.isoCountry;

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
            if (displayCode.isNotEmpty)
              Text(
                displayCode,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            if (countryCode != null && countryCode.length == 2) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                height: 20,
                child: CountryFlag.fromCountryCode(
                  countryCode,
                  theme: const ImageTheme(shape: RoundedRectangle(4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}