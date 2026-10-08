import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Serviço de integração nativa com smartwatches e wearables usando Apple HealthKit e Google Health Connect.
class HealthConnectService {
  static final HealthConnectService _instance = HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  Future<bool> authorize() async {
    if (kIsWeb) {
      debugPrint('[HealthConnectService] Web não suporta HealthKit / Health Connect. Usando modo mock.');
      _isAuthorized = true;
      return true;
    }

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.SLEEP_SESSION,
    ];

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    try {
      final bool authorized = await _health.requestAuthorization(types, permissions: permissions);
      _isAuthorized = authorized;
      return authorized;
    } catch (e) {
      debugPrint('[HealthConnectService] Erro de autorização: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchDailySummary() async {
    if (!_isAuthorized) {
      final auth = await authorize();
      if (!auth) {
        return _getMockData();
      }
    }

    if (kIsWeb) {
      return _getMockData();
    }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      int? steps = await _health.getTotalStepsInInterval(midnight, now);
      
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE, HealthDataType.SLEEP_SESSION],
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );

      // Limpeza de duplicados
      final cleanData = Health().removeDuplicates(healthData);

      double averageHeartRate = 0.0;
      int heartRateCount = 0;
      int sleepMinutes = 0;

      for (var data in cleanData) {
        if (data.type == HealthDataType.HEART_RATE) {
          final value = data.value as NumericHealthValue;
          averageHeartRate += value.numericValue.toDouble();
          heartRateCount++;
        } else if (data.type == HealthDataType.SLEEP_SESSION) {
           final sessionDuration = data.dateTo.difference(data.dateFrom).inMinutes;
           sleepMinutes += sessionDuration;
        }
      }

      if (heartRateCount > 0) {
        averageHeartRate = averageHeartRate / heartRateCount;
      }

      return {
        'steps': steps ?? 0,
        'heartRate': averageHeartRate.round(),
        'sleepMinutes': sleepMinutes,
        'isRealData': true,
      };
    } catch (e) {
      debugPrint('[HealthConnectService] Erro ao buscar dados: $e');
      return _getMockData();
    }
  }

  Map<String, dynamic> _getMockData() {
    return {
      'steps': 6500,
      'heartRate': 72,
      'sleepMinutes': 420, // 7 hours
      'isRealData': false,
    };
  }
}
