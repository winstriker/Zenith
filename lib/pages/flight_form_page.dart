import 'dart:async';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flight_providers.dart';
import '../services/database.dart';
import '../widgets/airport_search_dialog.dart';
import 'aircraft_select_page.dart';

enum TimezoneMode { utc, local, iana }

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(':', '');
    if (digits.length > 4) {
      return oldValue;
    }
    String formatted;
    if (digits.length <= 2) {
      formatted = digits;
    } else {
      formatted = '${digits.substring(0, 2)}:${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FlightFormPage extends ConsumerStatefulWidget {
  const FlightFormPage({super.key});

  @override
  ConsumerState<FlightFormPage> createState() => _FlightFormPageState();
}

class _FlightFormPageState extends ConsumerState<FlightFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _depTimeController = TextEditingController();
  final _arrTimeController = TextEditingController();
  final _remarksController = TextEditingController();

  Airport? _selectedDeparture;
  Airport? _selectedArrival;
  DateTime _departureDate = DateTime.now();
  DateTime? _arrivalDate;
  TimezoneMode _depTzMode = TimezoneMode.local;
  TimezoneMode _arrTzMode = TimezoneMode.local;
  String? _depIanaTz;
  String? _arrIanaTz;

  Aircraft? _selectedAircraft;
  String _approachType = 'VISUAL';
  int _nightLandings = 0;
  int _dayLandings = 1;
  String _flightRules = 'VFR';

  @override
  void initState() {
    super.initState();
    _depTimeController.text = _formatHHmm(TimeOfDay.now());
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _depTimeController.dispose();
    _arrTimeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickAirport({required bool isDeparture}) async {
    final airport = await showDialog<Airport>(
      context: context,
      builder: (_) => AirportSearchDialog(
        title: isDeparture ? 'Select Departure' : 'Select Arrival',
      ),
    );
    if (airport != null) {
      setState(() {
        final code = airport.ident ?? airport.icaoCode ?? airport.iataCode ?? airport.name ?? '';
        if (isDeparture) {
          _selectedDeparture = airport;
          _departureController.text = code;
        } else {
          _selectedArrival = airport;
          _arrivalController.text = code;
        }
      });
    }
  }

  Future<void> _pickDate({required bool isDeparture}) async {
    final current = isDeparture ? _departureDate : (_arrivalDate ?? _departureDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
        } else {
          _arrivalDate = picked;
        }
      });
    }
  }

  String _formatHHmm(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _parseHHmm(String text) {
    final cleaned = text.replaceAll(':', '').trim();
    if (cleaned.isEmpty) return TimeOfDay.now();
    final h = int.tryParse(cleaned.substring(0, cleaned.length.clamp(0, 2))) ?? 0;
    final m = cleaned.length > 2
        ? (int.tryParse(cleaned.substring(2, cleaned.length.clamp(2, 4))) ?? 0)
        : 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _formatDisplayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _tzLabel(TimezoneMode mode, String? iana, Airport? airport) {
    switch (mode) {
      case TimezoneMode.utc:
        return 'UTC';
      case TimezoneMode.local:
        return _airportTimezone(airport);
      case TimezoneMode.iana:
        return iana ?? _airportTimezone(airport);
    }
  }

  String _airportTimezone(Airport? airport) {
    if (airport == null) return 'LCL';
    final region = airport.isoRegion;
    if (region.length < 2) return 'LCL';
    final countryCode = region.length > 2 ? region.substring(0, 2) : region;
    final lon = airport.longitudeDeg;
    return _tzFromCountryAndLon(countryCode, lon);
  }

  static String _tzFromCountryAndLon(String countryCode, double? longitude) {
    final offset = longitude != null ? (longitude / 15).round().clamp(-12, 14) : 0;
    const tzByCountry = {
      'IT': {1: 'CET', 2: 'CEST'},
      'DE': {1: 'CET', 2: 'CEST'},
      'FR': {1: 'CET', 2: 'CEST'},
      'ES': {1: 'CET', 2: 'CEST'},
      'PT': {0: 'WET', 1: 'WEST'},
      'GB': {0: 'GMT', 1: 'BST'},
      'NL': {1: 'CET', 2: 'CEST'},
      'BE': {1: 'CET', 2: 'CEST'},
      'CH': {1: 'CET', 2: 'CEST'},
      'AT': {1: 'CET', 2: 'CEST'},
      'PL': {1: 'CET', 2: 'CEST'},
      'CZ': {1: 'CET', 2: 'CEST'},
      'SE': {1: 'CET', 2: 'CEST'},
      'NO': {1: 'CET', 2: 'CEST'},
      'DK': {1: 'CET', 2: 'CEST'},
      'FI': {2: 'EET', 3: 'EEST'},
      'UA': {2: 'EET', 3: 'EEST'},
      'BY': {3: 'MSK'},
      'RU': {3: 'MSK'},
      'TR': {3: 'TRT'},
      'US': {-5: 'EST', -6: 'CST', -7: 'MST', -8: 'PST', -9: 'AKST', -10: 'HST'},
      'CA': {-5: 'EST', -6: 'CST', -7: 'MST', -8: 'PST', -9: 'NST', -3: 'ADT'},
      'BR': {-3: 'BRT', -4: 'AMT'},
      'AR': {-3: 'ART'},
      'CL': {-4: 'CLT', -3: 'CLST'},
      'MX': {-6: 'CST', -7: 'MST', -8: 'PST'},
      'JP': {9: 'JST'},
      'CN': {8: 'CST'},
      'KR': {9: 'KST'},
      'IN': {5: 'IST'},
      'TH': {7: 'ICT'},
      'VN': {7: 'ICT'},
      'SG': {8: 'SGT'},
      'MY': {8: 'MYT'},
      'PH': {8: 'PHT'},
      'ID': {7: 'WIB', 8: 'WITA', 9: 'WIT'},
      'AU': {8: 'AWST', 9: 'ACST', 10: 'AEST'},
      'NZ': {12: 'NZST', 13: 'NZDT'},
      'ZA': {2: 'SAST'},
      'EG': {2: 'EET'},
      'MA': {0: 'WET', 1: 'WEST'},
      'NG': {1: 'WAT'},
      'KE': {3: 'EAT'},
      'AE': {4: 'GST'},
      'SA': {3: 'AST'},
      'IL': {2: 'IST'},
      'RO': {2: 'EET', 3: 'EEST'},
      'BG': {2: 'EET', 3: 'EEST'},
      'HU': {1: 'CET', 2: 'CEST'},
      'SK': {1: 'CET', 2: 'CEST'},
      'SI': {1: 'CET', 2: 'CEST'},
      'HR': {1: 'CET', 2: 'CEST'},
      'RS': {1: 'CET', 2: 'CEST'},
      'BA': {1: 'CET', 2: 'CEST'},
      'ME': {1: 'CET', 2: 'CEST'},
      'MK': {1: 'CET', 2: 'CEST'},
      'AL': {1: 'CET', 2: 'CEST'},
      'XK': {1: 'CET', 2: 'CEST'},
      'IE': {0: 'GMT', 1: 'IST'},
      'LT': {2: 'EET', 3: 'EEST'},
      'LV': {2: 'EET', 3: 'EEST'},
      'EE': {2: 'EET', 3: 'EEST'},
      'GR': {2: 'EET', 3: 'EEST'},
    };
    final countryTzs = tzByCountry[countryCode];
    if (countryTzs != null) {
      final tz = countryTzs[offset];
      if (tz != null) return tz;
    }
    return offset == 0 ? 'UTC' : 'UTC${offset > 0 ? '+' : ''}$offset';
  }

  void _showTzPicker({required bool isDeparture}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select Timezone',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('UTC'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (isDeparture) {
                      _depTzMode = TimezoneMode.utc;
                    } else {
                      _arrTzMode = TimezoneMode.utc;
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Local Time'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (isDeparture) {
                      _depTzMode = TimezoneMode.local;
                    } else {
                      _arrTzMode = TimezoneMode.local;
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Other (search world timezone...)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showIanaTzSearch(isDeparture: isDeparture);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showIanaTzSearch({required bool isDeparture}) {
    final controller = TextEditingController();
    final commonTzs = [
      'UTC', 'US/Eastern', 'US/Central', 'US/Mountain', 'US/Pacific',
      'Europe/London', 'Europe/Paris', 'Europe/Berlin', 'Europe/Rome',
      'Europe/Madrid', 'Europe/Amsterdam', 'Europe/Zurich', 'Europe/Vienna',
      'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata', 'Asia/Dubai',
      'Asia/Singapore', 'Asia/Hong_Kong', 'Asia/Seoul',
      'Australia/Sydney', 'Australia/Melbourne', 'Australia/Brisbane',
      'Pacific/Auckland', 'Pacific/Honolulu',
      'America/Sao_Paulo', 'America/Argentina/Buenos_Aires',
      'America/Mexico_City', 'America/Bogota', 'America/Lima',
      'Africa/Cairo', 'Africa/Johannesburg', 'Africa/Lagos',
    ];
    List<String> filtered = List.from(commonTzs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'World Timezones',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search timezone...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) {
                          setModalState(() {
                            filtered = commonTzs
                                .where((tz) => tz.toLowerCase().contains(v.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          return ListTile(
                            dense: true,
                            title: Text(filtered[i]),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                if (isDeparture) {
                                  _depTzMode = TimezoneMode.iana;
                                  _depIanaTz = filtered[i];
                                } else {
                                  _arrTzMode = TimezoneMode.iana;
                                  _arrIanaTz = filtered[i];
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final flightService = ref.read(flightServiceProvider);
    final depCode = _selectedDeparture?.ident ?? _departureController.text.trim();
    final arrCode = _selectedArrival?.ident ?? _arrivalController.text.trim();

    final depTime = _parseHHmm(_depTimeController.text);
    final depDateTime = DateTime(
      _departureDate.year, _departureDate.month, _departureDate.day,
      depTime.hour, depTime.minute,
    );

    DateTime? arrDateTime;
    if (_arrTimeController.text.isNotEmpty && _arrivalDate != null) {
      final arrTime = _parseHHmm(_arrTimeController.text);
      arrDateTime = DateTime(
        _arrivalDate!.year, _arrivalDate!.month, _arrivalDate!.day,
        arrTime.hour, arrTime.minute,
      );
    }

    await flightService.addFlight(
      departureId: _selectedDeparture?.id,
      arrivalId: _selectedArrival?.id,
      title: '$depCode → $arrCode',
      departureTime: depDateTime,
      arrivalTime: arrDateTime,
      aircraftId: _selectedAircraft?.id,
      approachType: _approachType,
      nightLandings: _nightLandings,
      dayLandings: _dayLandings,
      flightRules: _flightRules,
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
    );

    ref.read(flightListProvider.notifier).refresh();

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Flight'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFlightDetailsCard(theme, cs),
            const SizedBox(height: 16),
            _buildAircraftCard(theme, cs),
            const SizedBox(height: 16),
            _buildLandingsCard(theme, cs),
            const SizedBox(height: 16),
            _buildFlightRulesCard(theme, cs),
            const SizedBox(height: 16),
            _buildRemarksCard(theme, cs),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightDetailsCard(ThemeData theme, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'DEP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'LDG',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDateButton(theme, _departureDate, () => _pickDate(isDeparture: true))),
                const SizedBox(width: 8),
                _buildTzChip(theme, _tzLabel(_depTzMode, _depIanaTz, _selectedDeparture), () => _showTzPicker(isDeparture: true)),
                const SizedBox(width: 8),
                _buildTzChip(theme, _tzLabel(_arrTzMode, _arrIanaTz, _selectedArrival), () => _showTzPicker(isDeparture: false)),
                const SizedBox(width: 8),
                Expanded(child: _buildDateButton(theme, _arrivalDate ?? _departureDate, () => _pickDate(isDeparture: false), textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAirportField(
                    theme,
                    controller: _departureController,
                    label: 'Departure',
                    selectedAirport: _selectedDeparture,
                    onTap: () => _pickAirport(isDeparture: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.flight, color: cs.onSurfaceVariant, size: 20),
                ),
                Expanded(
                  child: _buildAirportField(
                    theme,
                    controller: _arrivalController,
                    label: 'Arrival',
                    selectedAirport: _selectedArrival,
                    onTap: () => _pickAirport(isDeparture: false),
                    isArrival: true,
                  ),
                ),
              ],
            ),
            if (_selectedDeparture?.name != null || _selectedArrival?.name != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDeparture?.name ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      _selectedArrival?.name ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInput(theme, _depTimeController, 'HH:mm'),
                ),
                const SizedBox(width: 8),
                _buildTzChip(theme, _tzLabel(_depTzMode, _depIanaTz, _selectedDeparture), null),
                const SizedBox(width: 8),
                _buildBlockTimePill(theme, cs),
                const SizedBox(width: 8),
                _buildTzChip(theme, _tzLabel(_arrTzMode, _arrIanaTz, _selectedArrival), null),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeInput(theme, _arrTimeController, 'HH:mm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirportField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required Airport? selectedAirport,
    required VoidCallback onTap,
    bool isArrival = false,
  }) {
    final cs = theme.colorScheme;
    final code = controller.text.isNotEmpty ? controller.text : '';
    final countryCode = selectedAirport?.isoCountry;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isArrival ? MainAxisAlignment.end : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code.isNotEmpty)
              Text(
                code,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildDateButton(ThemeData theme, DateTime date, VoidCallback onTap, {TextAlign textAlign = TextAlign.left}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          _formatDisplayDate(date),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          textAlign: textAlign,
        ),
      ),
    );
  }

  Widget _buildTzChip(ThemeData theme, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBlockTimePill(ThemeData theme, ColorScheme cs) {
    final depTime = _parseHHmm(_depTimeController.text);
    final arrTime = _parseHHmm(_arrTimeController.text);
    final hasArr = _arrTimeController.text.isNotEmpty && _arrivalDate != null;
    String blockTime = '0:00';
    if (hasArr) {
      final depMinutes = depTime.hour * 60 + depTime.minute;
      final arrMinutes = arrTime.hour * 60 + arrTime.minute;
      final diff = arrMinutes - depMinutes;
      if (diff >= 0) {
        final h = diff ~/ 60;
        final m = diff % 60;
        blockTime = '$h:${m.toString().padLeft(2, '0')}';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            blockTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
          Text(
            'BLOCK TIME',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(ThemeData theme, TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        _TimeInputFormatter(),
      ],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildAircraftCard(ThemeData theme, ColorScheme cs) {
    return Card(
      child: InkWell(
        onTap: _pickAircraft,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                cs.surface,
                cs.surfaceContainerHighest.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: _selectedAircraft != null
              ? _buildSelectedAircraft(theme, cs)
              : _buildAircraftPlaceholder(theme, cs),
        ),
      ),
    );
  }

  Widget _buildSelectedAircraft(ThemeData theme, ColorScheme cs) {
    final ac = _selectedAircraft!;
    return Row(
      children: [
        Container(
          width: 100,
          height: 70,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Icon(
            Icons.airplanemode_active,
            color: cs.onSecondaryContainer,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ac.tailNumber ?? ac.type,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (ac.model != null) ...[
                const SizedBox(height: 2),
                Text(
                  ac.model!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            ac.type,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
      ],
    );
  }

  Widget _buildAircraftPlaceholder(ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 100,
          height: 70,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.airplanemode_active,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Select Aircraft',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
      ],
    );
  }

  Future<void> _pickAircraft() async {
    final aircraft = await Navigator.push<Aircraft>(
      context,
      MaterialPageRoute(builder: (_) => const AircraftSelectPage()),
    );
    if (aircraft != null) {
      setState(() => _selectedAircraft = aircraft);
    }
  }

  Widget _buildLandingsCard(ThemeData theme, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.flight_land, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPROACH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _approachType,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'VISUAL', child: Text('VISUAL')),
                        DropdownMenuItem(value: 'ILS', child: Text('ILS')),
                        DropdownMenuItem(value: 'VOR', child: Text('VOR')),
                        DropdownMenuItem(value: 'NDB', child: Text('NDB')),
                        DropdownMenuItem(value: 'RNAV', child: Text('RNAV')),
                        DropdownMenuItem(value: 'GPS', child: Text('GPS')),
                        DropdownMenuItem(value: 'LOC', child: Text('LOC')),
                        DropdownMenuItem(value: 'TACAN', child: Text('TACAN')),
                      ],
                      onChanged: (v) => setState(() => _approachType = v ?? 'VISUAL'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildLandingCounter(theme, cs, 'NIGHT', _nightLandings, (v) {
              setState(() => _nightLandings = v);
            }),
            const SizedBox(width: 16),
            _buildLandingCounter(theme, cs, 'DAY', _dayLandings, (v) {
              setState(() => _dayLandings = v);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingCounter(ThemeData theme, ColorScheme cs, String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => onChanged((value - 1).clamp(0, 99)),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.remove, size: 16, color: cs.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add, size: 16, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlightRulesCard(ThemeData theme, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.rule, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLIGHT RULES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _flightRules,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'VFR', child: Text('VFR')),
                        DropdownMenuItem(value: 'IFR', child: Text('IFR')),
                        DropdownMenuItem(value: 'Y', child: Text('Y - IFR/VFR')),
                        DropdownMenuItem(value: 'Z', child: Text('Z - VFR/IFR')),
                        DropdownMenuItem(value: 'Z2', child: Text('Z2 - VFR/IFR')),
                      ],
                      onChanged: (v) => setState(() => _flightRules = v ?? 'VFR'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(ThemeData theme, ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Text(
                  'REMARKS & ENDORSEMENTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: TextField(
                controller: _remarksController,
                maxLines: 3,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add notes, endorsements, or remarks...',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
