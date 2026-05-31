import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flight_session.dart';
import '../models/flight_point.dart';

class FlightService {
  static final FlightService _instance = FlightService._();
  factory FlightService() => _instance;
  FlightService._();

  static const String _storageKey = 'logbook_flight_sessions';

  final List<FlightSession> _sessions = [];
  String? _activeSessionId;
  Timer? _saveDebounce;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
      _sessions.clear();
      for (final item in decoded) {
        _sessions.add(FlightSession.fromJson(item as Map<String, dynamic>));
      }
    }
    final active = _sessions.where((s) => s.status == FlightStatus.inProgress).toList();
    if (active.isNotEmpty) {
      _activeSessionId = active.first.sessionId;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () {
      _save();
    });
  }

  UnmodifiableListView<FlightSession> get sessions => UnmodifiableListView(_sessions);

  List<FlightSession> get recordedSessions => _sessions
      .where((s) => s.status == FlightStatus.recorded)
      .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

  FlightSession? get activeSession {
    if (_activeSessionId == null) return null;
    try {
      return _sessions.firstWhere((s) => s.sessionId == _activeSessionId);
    } catch (_) {
      return null;
    }
  }

  FlightSession? getSession(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.sessionId == sessionId);
    } catch (_) {
      return null;
    }
  }

  String startSession({
    String title = 'New Flight',
    String? aircraftType,
    String? departure,
    String? arrival,
  }) {
    final session = FlightSession(
      sessionId: _generateId(),
      title: title,
      aircraftType: aircraftType,
      departure: departure,
      arrival: arrival,
      startTime: DateTime.now(),
      status: FlightStatus.inProgress,
    );
    _sessions.add(session);
    _activeSessionId = session.sessionId;
    _save();
    return session.sessionId;
  }

  void addPoint(double latitude, double longitude, double altitude, {double? speed, double? heading}) {
    if (_activeSessionId == null) return;
    final index = _sessions.indexWhere((s) => s.sessionId == _activeSessionId);
    if (index == -1) return;
    final session = _sessions[index];
    final point = FlightPoint(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      timestamp: DateTime.now(),
      speed: speed,
      heading: heading,
    );
    _sessions[index] = session.copyWith(points: [...session.points, point]);
    _debouncedSave();
  }

  Future<void> endSession() async {
    if (_activeSessionId == null) return;
    final index = _sessions.indexWhere((s) => s.sessionId == _activeSessionId);
    if (index == -1) return;
    _sessions[index] = _sessions[index].copyWith(
      status: FlightStatus.recorded,
      endTime: DateTime.now(),
    );
    _activeSessionId = null;
    _saveDebounce?.cancel();
    await _save();
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.sessionId == sessionId);
    await _save();
  }

  List<FlightSession> searchByDate(DateTime date) {
    return _sessions.where((s) =>
      s.startTime.year == date.year &&
      s.startTime.month == date.month &&
      s.startTime.day == date.day &&
      s.status == FlightStatus.recorded
    ).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<FlightSession> searchByDateRange(DateTime start, DateTime end) {
    return _sessions.where((s) =>
      s.startTime.isAfter(start) &&
      s.startTime.isBefore(end.add(const Duration(days: 1))) &&
      s.status == FlightStatus.recorded
    ).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  String _generateId() {
    final now = DateTime.now();
    return 'FL${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }
}
