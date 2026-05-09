import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // paperclip-jam via Tailscale — plain HTTP on IP (DNS/TLS problematic in Flutter)
  static const _base = 'http://100.123.60.12:5677';
  static const _timeout = Duration(seconds: 8);

  static final _client = http.Client();

  // ── Ingest ─────────────────────────────────────────────────────────────────

  static Future<void> ingest({
    int? hr,
    double? hrv,
    double? spo2,
    double? tempC,
    double? batteryPct,
    bool? charging,
    double? accelMag,
    bool? wristOn,
  }) async {
    final body = <String, dynamic>{};
    if (hr != null) body['hr'] = hr;
    if (hrv != null) body['hrv'] = hrv;
    if (spo2 != null) body['spo2'] = spo2;
    if (tempC != null) body['temp_c'] = tempC;
    if (batteryPct != null) body['battery_pct'] = batteryPct;
    if (charging != null) body['charging'] = charging;
    if (accelMag != null) body['accel_mag'] = accelMag;
    if (wristOn != null) body['wrist_on'] = wristOn;
    if (body.isEmpty) return;

    try {
      await _client
          .post(
            Uri.parse('$_base/api/ingest'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('[WHOOP] ingest error: $e');
    }
  }

  // ── Insights ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchTodayInsights() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/api/insights/today'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('[WHOOP] fetchTodayInsights: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('[WHOOP] fetchTodayInsights error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchRecovery() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/api/insights/recovery'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('[WHOOP] fetchRecovery: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('[WHOOP] fetchRecovery error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchHrHistory(
      {int hours = 24}) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/api/metrics/hr?hours=$hours'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map;
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      debugPrint('[WHOOP] fetchHrHistory: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('[WHOOP] fetchHrHistory error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchHistory(
      {int days = 7}) async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/api/insights/history?days=$days'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map;
        return (data['history'] as List).cast<Map<String, dynamic>>();
      }
      debugPrint('[WHOOP] fetchHistory: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('[WHOOP] fetchHistory error: $e');
    }
    return [];
  }

  // ── Health ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchAlarm() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/api/alarm'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map;
        return data['alarm'] as Map<String, dynamic>?;
      }
      debugPrint('[WHOOP] fetchAlarm: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('[WHOOP] fetchAlarm error: $e');
    }
    return null;
  }

  static Future<bool> isReachable() async {
    try {
      debugPrint('[WHOOP] isReachable: trying $_base/health');
      final res = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 4));
      debugPrint('[WHOOP] isReachable: HTTP ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[WHOOP] isReachable ERROR: $e');
      return false;
    }
  }
}
