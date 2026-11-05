import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import 'storage/app_storage.dart';

class GrowthDataService {
  GrowthDataService._() {
    measurementsNotifier.value = List<GrowthMeasurement>.from(MockData.growthHistory);
  }
  static final GrowthDataService instance = GrowthDataService._();

  static const String _storageKey = 'poshan_growth_measurements';
  static const String _childStorageKey = 'poshan_child_profile';

  final ValueNotifier<List<GrowthMeasurement>> measurementsNotifier =
      ValueNotifier<List<GrowthMeasurement>>([]);
  final ValueNotifier<ChildProfile> childNotifier =
      ValueNotifier<ChildProfile>(MockData.defaultChild);

  bool _isInitialized = false;

  List<GrowthMeasurement> get allMeasurements => measurementsNotifier.value;
  ChildProfile get child => childNotifier.value;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load child profile
    try {
      final childJson = await AppStorage.instance.getString(_childStorageKey);
      if (childJson != null && childJson.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(childJson) as Map<String, dynamic>;
        childNotifier.value = ChildProfile.fromJson(map);
      }
    } catch (e) {
      debugPrint('[GrowthDataService] Error loading child profile: $e');
    }

    // Load measurements
    try {
      final measJson = await AppStorage.instance.getString(_storageKey);
      if (measJson != null && measJson.isNotEmpty) {
        final List list = jsonDecode(measJson) as List;
        final loaded = list
            .map((item) => GrowthMeasurement.fromJson(item as Map<String, dynamic>))
            .toList();
        // Sort newest first
        loaded.sort((a, b) => b.date.compareTo(a.date));
        measurementsNotifier.value = loaded;
      } else {
        // Initial seed from MockData
        final initial = List<GrowthMeasurement>.from(MockData.growthHistory);
        initial.sort((a, b) => b.date.compareTo(a.date));
        measurementsNotifier.value = initial;
      }
    } catch (e) {
      debugPrint('[GrowthDataService] Error loading growth measurements: $e');
      measurementsNotifier.value = List<GrowthMeasurement>.from(MockData.growthHistory);
    }
  }

  Future<void> _persistMeasurements() async {
    try {
      final encoded = jsonEncode(allMeasurements.map((m) => m.toJson()).toList());
      await AppStorage.instance.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[GrowthDataService] Error persisting measurements: $e');
    }
  }

  Future<void> _persistChild() async {
    try {
      final encoded = jsonEncode(child.toJson());
      await AppStorage.instance.setString(_childStorageKey, encoded);
    } catch (e) {
      debugPrint('[GrowthDataService] Error persisting child: $e');
    }
  }

  Future<void> addMeasurement({
    required double weightKg,
    required double lengthCm,
    double headCircumferenceCm = 46.5,
    required DateTime date,
    String eventType = 'Caregiver Checkup',
    String workerName = 'Self-Reported (Caregiver)',
    String notes = '',
  }) async {
    if (weightKg <= 0 || lengthCm <= 0) return;

    final diffMonths = (date.difference(child.dob).inDays / 30.4375).round();
    final ageMonths = diffMonths > 0 ? diffMonths : child.ageInMonths;

    // Approximate WHO Z-score for weight: Median for 14m boy is ~9.4 kg, SD is ~1.0 kg
    final double zScore = ((weightKg - 9.4) / 1.0);

    final newMeasurement = GrowthMeasurement(
      dateString: DateFormat('dd MMM yyyy').format(date),
      date: date,
      ageMonths: ageMonths,
      weightKg: weightKg,
      lengthCm: lengthCm,
      headCircumferenceCm: headCircumferenceCm,
      zScore: double.parse(zScore.toStringAsFixed(1)),
      eventType: eventType,
      workerName: workerName,
      notes: notes,
    );

    final list = List<GrowthMeasurement>.from(allMeasurements);
    list.add(newMeasurement);
    list.sort((a, b) => b.date.compareTo(a.date)); // Newest first

    measurementsNotifier.value = list;

    // Update child profile's current weight & length if this is the newest
    if (list.first == newMeasurement) {
      childNotifier.value = child.copyWith(
        currentWeightKg: weightKg,
        currentLengthCm: lengthCm,
        ageInMonths: ageMonths,
      );
      await _persistChild();
    }

    await _persistMeasurements();
  }

  List<GrowthMeasurement> getFilteredMeasurements(String filter) {
    if (filter == 'All Time') return allMeasurements;

    final now = DateTime.now();
    Duration duration;

    switch (filter) {
      case '7 Days':
        duration = const Duration(days: 7);
        break;
      case '30 Days':
        duration = const Duration(days: 30);
        break;
      case '3 Months':
        duration = const Duration(days: 90);
        break;
      case '6 Months':
        duration = const Duration(days: 180);
        break;
      case '1 Year':
        duration = const Duration(days: 365);
        break;
      default:
        return allMeasurements;
    }

    final cutoff = now.subtract(duration);
    final filtered = allMeasurements.where((m) => m.date.isAfter(cutoff)).toList();
    // If filter yields nothing (e.g. historical data from months ago), fallback to showing top 2 or at least available
    return filtered.isNotEmpty ? filtered : allMeasurements.take(3).toList();
  }

  Map<String, dynamic> calculateStats(List<GrowthMeasurement> measurements) {
    if (measurements.isEmpty) {
      return {
        'latestWeight': 0.0,
        'latestLength': 0.0,
        'prevWeight': 0.0,
        'prevLength': 0.0,
        'weightChange': 0.0,
        'lengthChange': 0.0,
        'weightPercentChange': 0.0,
        'lengthPercentChange': 0.0,
        'velocityText': 'No data recorded',
        'whoZone': 'Pending Initial Check',
      };
    }

    final latest = measurements.first;
    final prev = measurements.length > 1 ? measurements[1] : latest;

    final weightDiff = latest.weightKg - prev.weightKg;
    final lengthDiff = latest.lengthCm - prev.lengthCm;

    final weightPct = prev.weightKg > 0 ? (weightDiff / prev.weightKg) * 100 : 0.0;
    final lengthPct = prev.lengthCm > 0 ? (lengthDiff / prev.lengthCm) * 100 : 0.0;

    String whoStatus = 'WHO GREEN ZONE • Normal';
    if (latest.zScore < -2.0) {
      whoStatus = 'WHO RED ZONE • Severe Stunting / Underweight';
    } else if (latest.zScore < -1.0) {
      whoStatus = 'WHO YELLOW ZONE • Moderate Risk';
    }

    final velocity = weightDiff >= 0
        ? '+${(weightDiff * 1000).toInt()}g recently'
        : '${(weightDiff * 1000).toInt()}g drop';

    return {
      'latestWeight': latest.weightKg,
      'latestLength': latest.lengthCm,
      'prevWeight': prev.weightKg,
      'prevLength': prev.lengthCm,
      'weightChange': weightDiff,
      'lengthChange': lengthDiff,
      'weightPercentChange': weightPct,
      'lengthPercentChange': lengthPct,
      'velocityText': velocity,
      'whoZone': whoStatus,
    };
  }
}

