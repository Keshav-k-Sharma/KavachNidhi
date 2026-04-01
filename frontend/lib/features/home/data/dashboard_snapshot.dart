import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _dashboardSnapshotAssetPath = 'assets/data/dashboard_snapshot.json';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.planName,
    required this.systemStatusLabel,
    required this.systemStatusValue,
    required this.sensorStatusLabel,
    required this.sensorStatusValue,
    required this.triggers,
    required this.totalCredits,
    required this.pendingCredits,
    required this.clearedCredits,
    required this.shieldCreditsHeader,
    required this.pendingCreditsLabel,
    required this.pendingCreditsCaption,
    required this.clearedCreditsLabel,
    required this.clearedCreditsCaption,
    required this.redeemCreditsLabel,
    required this.nextSettlementDate,
    required this.settlementTime,
    required this.countdownDays,
    required this.countdownHours,
    required this.countdownMinutes,
    required this.countdownDaysLabel,
    required this.countdownHoursLabel,
    required this.countdownMinutesLabel,
    required this.cycleProgressPercent,
    required this.cycleProgressLabel,
    required this.verificationEvents,
    required this.settlementStatusLabel,
    required this.autoTransferMessage,
    required this.verificationStreamLabel,
    required this.systemTagline,
  });

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
      totalCredits: json['totalCredits'] as int,
      pendingCredits: json['pendingCredits'] as int,
      clearedCredits: json['clearedCredits'] as int,
      shieldCreditsHeader: json['shieldCreditsHeader'] as String,
      pendingCreditsLabel: json['pendingCreditsLabel'] as String,
      pendingCreditsCaption: json['pendingCreditsCaption'] as String,
      clearedCreditsLabel: json['clearedCreditsLabel'] as String,
      clearedCreditsCaption: json['clearedCreditsCaption'] as String,
      redeemCreditsLabel: json['redeemCreditsLabel'] as String,
      nextSettlementDate: json['nextSettlementDate'] as String,
      settlementTime: json['settlementTime'] as String,
      countdownDays: json['countdownDays'] as int,
      countdownHours: json['countdownHours'] as int,
      countdownMinutes: json['countdownMinutes'] as int,
      countdownDaysLabel: json['countdownDaysLabel'] as String,
      countdownHoursLabel: json['countdownHoursLabel'] as String,
      countdownMinutesLabel: json['countdownMinutesLabel'] as String,
      cycleProgressPercent: json['cycleProgressPercent'] as int,
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
  final int totalCredits;
  final int pendingCredits;
  final int clearedCredits;
  final String shieldCreditsHeader;
  final String pendingCreditsLabel;
  final String pendingCreditsCaption;
  final String clearedCreditsLabel;
  final String clearedCreditsCaption;
  final String redeemCreditsLabel;
  final String nextSettlementDate;
  final String settlementTime;
  final int countdownDays;
  final int countdownHours;
  final int countdownMinutes;
  final String countdownDaysLabel;
  final String countdownHoursLabel;
  final String countdownMinutesLabel;
  final int cycleProgressPercent;
  final String cycleProgressLabel;
  final List<VerificationEvent> verificationEvents;
  final String settlementStatusLabel;
  final String autoTransferMessage;
  final String verificationStreamLabel;
  final String systemTagline;

  DashboardSnapshot copyWith({
    int? totalCredits,
    int? pendingCredits,
    int? clearedCredits,
  }) {
    return DashboardSnapshot(
      planName: planName,
      systemStatusLabel: systemStatusLabel,
      systemStatusValue: systemStatusValue,
      sensorStatusLabel: sensorStatusLabel,
      sensorStatusValue: sensorStatusValue,
      triggers: triggers,
      totalCredits: totalCredits ?? this.totalCredits,
      pendingCredits: pendingCredits ?? this.pendingCredits,
      clearedCredits: clearedCredits ?? this.clearedCredits,
      shieldCreditsHeader: shieldCreditsHeader,
      pendingCreditsLabel: pendingCreditsLabel,
      pendingCreditsCaption: pendingCreditsCaption,
      clearedCreditsLabel: clearedCreditsLabel,
      clearedCreditsCaption: clearedCreditsCaption,
      redeemCreditsLabel: redeemCreditsLabel,
      nextSettlementDate: nextSettlementDate,
      settlementTime: settlementTime,
      countdownDays: countdownDays,
      countdownHours: countdownHours,
      countdownMinutes: countdownMinutes,
      countdownDaysLabel: countdownDaysLabel,
      countdownHoursLabel: countdownHoursLabel,
      countdownMinutesLabel: countdownMinutesLabel,
      cycleProgressPercent: cycleProgressPercent,
      cycleProgressLabel: cycleProgressLabel,
      verificationEvents: verificationEvents,
      settlementStatusLabel: settlementStatusLabel,
      autoTransferMessage: autoTransferMessage,
      verificationStreamLabel: verificationStreamLabel,
      systemTagline: systemTagline,
    );
  }
}

class TriggerStatusCardModel {
  const TriggerStatusCardModel({
    required this.title,
    required this.condition,
    required this.detail,
    required this.icon,
    required this.intensity,
    required this.color,
    required this.isActive,
    required this.progress,
  });

  factory TriggerStatusCardModel.fromJson(Map<String, dynamic> json) {
    return TriggerStatusCardModel(
      title: json['title'] as String,
      condition: json['condition'] as String,
      detail: json['detail'] as String,
      icon: _parseIcon(json['icon'] as String),
      intensity: json['intensity'] as String,
      color: _parseColor(json['color'] as String),
      isActive: json['isActive'] as bool,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.5,
    );
  }

  final String title;
  final String condition;
  final String detail;
  final IconData icon;
  final String intensity;
  final Color color;
  final bool isActive;
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
};

IconData _parseIcon(String key) {
  final IconData? icon = _iconByKey[key];
  if (icon == null) {
    throw FormatException('Unsupported icon key: $key');
  }
  return icon;
}

Color _parseColor(String value) {
  final String hex = value.replaceFirst('#', '');
  if (hex.length != 6 && hex.length != 8) {
    throw FormatException('Unsupported color hex: $value');
  }
  final String argb = hex.length == 6 ? 'FF$hex' : hex;
  return Color(int.parse(argb, radix: 16));
}
