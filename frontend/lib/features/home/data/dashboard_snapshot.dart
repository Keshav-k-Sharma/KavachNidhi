import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _dashboardSnapshotAssetPath = 'assets/data/dashboard_snapshot.json';

/// Parses JSON numbers into [double], using [double.nan] when missing or invalid.
double parseJsonDouble(dynamic value) {
  if (value == null) {
    return double.nan;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? double.nan;
  }
  return double.nan;
}

/// Coerces API/JSON values (often [int]) to [double] for dashboard fields.
double coerceToDouble(Object? value) {
  if (value == null) {
    return double.nan;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.nan;
}

double _mergeDouble(num? override, double current) =>
    coerceToDouble(override ?? current);

class DashboardSnapshot {
  DashboardSnapshot({
    required this.planName,
    required this.systemStatusLabel,
    required this.systemStatusValue,
    required this.sensorStatusLabel,
    required this.sensorStatusValue,
    required this.triggers,
    required num totalCredits,
    required num pendingCredits,
    required num clearedCredits,
    required this.shieldCreditsHeader,
    required this.pendingCreditsLabel,
    required this.pendingCreditsCaption,
    required this.clearedCreditsLabel,
    required this.clearedCreditsCaption,
    required this.redeemCreditsLabel,
    required this.nextSettlementDate,
    required this.settlementTime,
    required num countdownDays,
    required num countdownHours,
    required num countdownMinutes,
    required this.countdownDaysLabel,
    required this.countdownHoursLabel,
    required this.countdownMinutesLabel,
    required num cycleProgressPercent,
    required this.cycleProgressLabel,
    required this.verificationEvents,
    required this.settlementStatusLabel,
    required this.autoTransferMessage,
    required this.verificationStreamLabel,
    required this.systemTagline,
  })  : totalCredits = totalCredits.toDouble(),
        pendingCredits = pendingCredits.toDouble(),
        clearedCredits = clearedCredits.toDouble(),
        countdownDays = countdownDays.toDouble(),
        countdownHours = countdownHours.toDouble(),
        countdownMinutes = countdownMinutes.toDouble(),
        cycleProgressPercent = cycleProgressPercent.toDouble();

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return DashboardSnapshot(
      planName: json['planName'] as String,
      systemStatusLabel: json['systemStatusLabel'] as String,
      systemStatusValue: json['systemStatusValue'] as String,
      sensorStatusLabel: json['sensorStatusLabel'] as String,
      sensorStatusValue: json['sensorStatusValue'] as String,
      triggers: (json['triggers'] as List<dynamic>)
          .map(
            (Object? item) => TriggerStatusCardModel.fromJson(
              Map<String, dynamic>.from(item! as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false),
      totalCredits: parseJsonDouble(json['totalCredits']),
      pendingCredits: parseJsonDouble(json['pendingCredits']),
      clearedCredits: parseJsonDouble(json['clearedCredits']),
      shieldCreditsHeader: json['shieldCreditsHeader'] as String,
      pendingCreditsLabel: json['pendingCreditsLabel'] as String,
      pendingCreditsCaption: json['pendingCreditsCaption'] as String,
      clearedCreditsLabel: json['clearedCreditsLabel'] as String,
      clearedCreditsCaption: json['clearedCreditsCaption'] as String,
      redeemCreditsLabel: json['redeemCreditsLabel'] as String,
      nextSettlementDate: json['nextSettlementDate'] as String,
      settlementTime: json['settlementTime'] as String,
      countdownDays: parseJsonDouble(json['countdownDays']),
      countdownHours: parseJsonDouble(json['countdownHours']),
      countdownMinutes: parseJsonDouble(json['countdownMinutes']),
      countdownDaysLabel: json['countdownDaysLabel'] as String,
      countdownHoursLabel: json['countdownHoursLabel'] as String,
      countdownMinutesLabel: json['countdownMinutesLabel'] as String,
      cycleProgressPercent: parseJsonDouble(json['cycleProgressPercent']),
      cycleProgressLabel: json['cycleProgressLabel'] as String,
      verificationEvents: (json['verificationEvents'] as List<dynamic>)
          .map(
            (Object? item) => VerificationEvent.fromJson(
              Map<String, dynamic>.from(item! as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false),
      settlementStatusLabel: json['settlementStatusLabel'] as String,
      autoTransferMessage: json['autoTransferMessage'] as String,
      verificationStreamLabel: json['verificationStreamLabel'] as String,
      systemTagline: json['systemTagline'] as String,
    );
  }

  final String planName;
  final String systemStatusLabel;
  final String systemStatusValue;
  final String sensorStatusLabel;
  final String sensorStatusValue;
  final List<TriggerStatusCardModel> triggers;
  /// Shield credits balance — `double.nan` when unavailable.
  final double totalCredits;
  final double pendingCredits;
  final double clearedCredits;
  final String shieldCreditsHeader;
  final String pendingCreditsLabel;
  final String pendingCreditsCaption;
  final String clearedCreditsLabel;
  final String clearedCreditsCaption;
  final String redeemCreditsLabel;
  final String nextSettlementDate;
  final String settlementTime;
  final double countdownDays;
  final double countdownHours;
  final double countdownMinutes;
  final String countdownDaysLabel;
  final String countdownHoursLabel;
  final String countdownMinutesLabel;
  final double cycleProgressPercent;
  final String cycleProgressLabel;
  final List<VerificationEvent> verificationEvents;
  final String settlementStatusLabel;
  final String autoTransferMessage;
  final String verificationStreamLabel;
  final String systemTagline;

  /// When the user is not signed in, hide demo numerics for API-backed fields.
  DashboardSnapshot withProtectedFieldsNan() {
    return DashboardSnapshot(
      planName: planName,
      systemStatusLabel: systemStatusLabel,
      systemStatusValue: systemStatusValue,
      sensorStatusLabel: sensorStatusLabel,
      sensorStatusValue: sensorStatusValue,
      triggers: triggers
          .map(
            (TriggerStatusCardModel t) => TriggerStatusCardModel(
              title: t.title,
              condition: t.condition,
              detail: t.detail,
              icon: t.icon,
              intensity: t.intensity,
              color: t.color,
              isActive: t.isActive,
              progress: double.nan,
            ),
          )
          .toList(growable: false),
      totalCredits: double.nan,
      pendingCredits: double.nan,
      clearedCredits: double.nan,
      shieldCreditsHeader: shieldCreditsHeader,
      pendingCreditsLabel: pendingCreditsLabel,
      pendingCreditsCaption: pendingCreditsCaption,
      clearedCreditsLabel: clearedCreditsLabel,
      clearedCreditsCaption: clearedCreditsCaption,
      redeemCreditsLabel: redeemCreditsLabel,
      nextSettlementDate: nextSettlementDate,
      settlementTime: settlementTime,
      countdownDays: double.nan,
      countdownHours: double.nan,
      countdownMinutes: double.nan,
      countdownDaysLabel: countdownDaysLabel,
      countdownHoursLabel: countdownHoursLabel,
      countdownMinutesLabel: countdownMinutesLabel,
      cycleProgressPercent: double.nan,
      cycleProgressLabel: cycleProgressLabel,
      verificationEvents: const <VerificationEvent>[],
      settlementStatusLabel: settlementStatusLabel,
      autoTransferMessage: autoTransferMessage,
      verificationStreamLabel: verificationStreamLabel,
      systemTagline: systemTagline,
    );
  }

  DashboardSnapshot copyWith({
    String? planName,
    String? systemStatusLabel,
    String? systemStatusValue,
    String? sensorStatusLabel,
    String? sensorStatusValue,
    List<TriggerStatusCardModel>? triggers,
    num? totalCredits,
    num? pendingCredits,
    num? clearedCredits,
    String? shieldCreditsHeader,
    String? pendingCreditsLabel,
    String? pendingCreditsCaption,
    String? clearedCreditsLabel,
    String? clearedCreditsCaption,
    String? redeemCreditsLabel,
    String? nextSettlementDate,
    String? settlementTime,
    num? countdownDays,
    num? countdownHours,
    num? countdownMinutes,
    String? countdownDaysLabel,
    String? countdownHoursLabel,
    String? countdownMinutesLabel,
    num? cycleProgressPercent,
    String? cycleProgressLabel,
    List<VerificationEvent>? verificationEvents,
    String? settlementStatusLabel,
    String? autoTransferMessage,
    String? verificationStreamLabel,
    String? systemTagline,
  }) {
    return DashboardSnapshot(
      planName: planName ?? this.planName,
      systemStatusLabel: systemStatusLabel ?? this.systemStatusLabel,
      systemStatusValue: systemStatusValue ?? this.systemStatusValue,
      sensorStatusLabel: sensorStatusLabel ?? this.sensorStatusLabel,
      sensorStatusValue: sensorStatusValue ?? this.sensorStatusValue,
      triggers: triggers ?? this.triggers,
      totalCredits: _mergeDouble(totalCredits, this.totalCredits),
      pendingCredits: _mergeDouble(pendingCredits, this.pendingCredits),
      clearedCredits: _mergeDouble(clearedCredits, this.clearedCredits),
      shieldCreditsHeader: shieldCreditsHeader ?? this.shieldCreditsHeader,
      pendingCreditsLabel: pendingCreditsLabel ?? this.pendingCreditsLabel,
      pendingCreditsCaption: pendingCreditsCaption ?? this.pendingCreditsCaption,
      clearedCreditsLabel: clearedCreditsLabel ?? this.clearedCreditsLabel,
      clearedCreditsCaption: clearedCreditsCaption ?? this.clearedCreditsCaption,
      redeemCreditsLabel: redeemCreditsLabel ?? this.redeemCreditsLabel,
      nextSettlementDate: nextSettlementDate ?? this.nextSettlementDate,
      settlementTime: settlementTime ?? this.settlementTime,
      countdownDays: _mergeDouble(countdownDays, this.countdownDays),
      countdownHours: _mergeDouble(countdownHours, this.countdownHours),
      countdownMinutes: _mergeDouble(countdownMinutes, this.countdownMinutes),
      countdownDaysLabel: countdownDaysLabel ?? this.countdownDaysLabel,
      countdownHoursLabel: countdownHoursLabel ?? this.countdownHoursLabel,
      countdownMinutesLabel: countdownMinutesLabel ?? this.countdownMinutesLabel,
      cycleProgressPercent:
          _mergeDouble(cycleProgressPercent, this.cycleProgressPercent),
      cycleProgressLabel: cycleProgressLabel ?? this.cycleProgressLabel,
      verificationEvents: verificationEvents ?? this.verificationEvents,
      settlementStatusLabel: settlementStatusLabel ?? this.settlementStatusLabel,
      autoTransferMessage: autoTransferMessage ?? this.autoTransferMessage,
      verificationStreamLabel: verificationStreamLabel ?? this.verificationStreamLabel,
      systemTagline: systemTagline ?? this.systemTagline,
    );
  }
}

class TriggerStatusCardModel {
  TriggerStatusCardModel({
    required this.title,
    required this.condition,
    required this.detail,
    required this.icon,
    required this.intensity,
    required this.color,
    required this.isActive,
    required num progress,
  }) : progress = progress.toDouble();

  factory TriggerStatusCardModel.fromJson(Map<String, dynamic> json) {
    final Object? rawProgress = json['progress'];
    final double p =
        rawProgress == null ? 0.5 : parseJsonDouble(rawProgress);
    return TriggerStatusCardModel(
      title: json['title'] as String,
      condition: json['condition'] as String,
      detail: json['detail'] as String,
      icon: _parseIcon(json['icon'] as String),
      intensity: json['intensity'] as String,
      color: _parseColor(json['color'] as String),
      isActive: json['isActive'] as bool,
      progress: p.isNaN ? 0.5 : p,
    );
  }

  final String title;
  final String condition;
  final String detail;
  final IconData icon;
  final String intensity;
  final Color color;
  final bool isActive;
  /// No live trigger API — stitched dashboards use [double.nan] here.
  final double progress;
}

class VerificationEvent {
  const VerificationEvent({
    required this.title,
    required this.subtitle,
    required this.impact,
    required this.timeAgo,
    required this.icon,
  });

  factory VerificationEvent.fromJson(Map<String, dynamic> json) {
    return VerificationEvent(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      impact: json['impact'] as String,
      timeAgo: json['timeAgo'] as String,
      icon: _parseIcon(json['icon'] as String),
    );
  }

  final String title;
  final String subtitle;
  final String impact;
  final String timeAgo;
  final IconData icon;
}

Future<DashboardSnapshot> loadDashboardSnapshot() async {
  final String rawJson = await rootBundle.loadString(_dashboardSnapshotAssetPath);
  final Object? decoded = jsonDecode(rawJson);
  if (decoded is! Map<dynamic, dynamic>) {
    throw const FormatException('Dashboard snapshot JSON must be an object.');
  }
  return DashboardSnapshot.fromJson(Map<String, dynamic>.from(decoded));
}

const Map<String, IconData> _iconByKey = <String, IconData>{
  'warning_amber_rounded': Icons.warning_amber_rounded,
  'cloudy_snowing': Icons.cloudy_snowing,
  'traffic': Icons.traffic,
  'check_circle_outline': Icons.check_circle_outline,
  'pending_actions': Icons.pending_actions,
  'receipt_long': Icons.receipt_long,
  'payments': Icons.payments,
  'swap_horiz': Icons.swap_horiz,
  'account_balance_wallet': Icons.account_balance_wallet,
};

IconData _parseIcon(String key) {
  final IconData? icon = _iconByKey[key];
  if (icon == null) {
    throw FormatException('Unsupported icon key: $key');
  }
  return icon;
}

IconData parseDashboardIconKey(String key) => _parseIcon(key);

Color _parseColor(String value) {
  final String hex = value.replaceFirst('#', '');
  if (hex.length != 6 && hex.length != 8) {
    throw FormatException('Unsupported color hex: $value');
  }
  final String argb = hex.length == 6 ? 'FF$hex' : hex;
  return Color(int.parse(argb, radix: 16));
}
