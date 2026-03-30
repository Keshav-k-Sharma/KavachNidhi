import 'package:flutter/material.dart';

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
  });

  final String title;
  final String condition;
  final String detail;
  final IconData icon;
  final String intensity;
  final Color color;
  final bool isActive;
}

class VerificationEvent {
  const VerificationEvent({
    required this.title,
    required this.subtitle,
    required this.impact,
    required this.timeAgo,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String impact;
  final String timeAgo;
  final IconData icon;
}

DashboardSnapshot getMockDashboardData() {
  return DashboardSnapshot(
    planName: 'Kavach Max Active',
    systemStatusLabel: 'System Status',
    systemStatusValue: 'ENCRYPTED',
    sensorStatusLabel: 'Environmental Sensors',
    sensorStatusValue: 'LIVE',
    triggers: const <TriggerStatusCardModel>[
      TriggerStatusCardModel(
        title: 'CycloneGuard',
        condition: 'cyclone HIGH ALERT',
        detail: 'Wind: 84 km/h • North-East',
        icon: Icons.warning_amber_rounded,
        intensity: 'HIGH',
        color: Color(0xFFFF6D6D),
        isActive: true,
      ),
      TriggerStatusCardModel(
        title: 'FogBlock',
        condition: 'visibility_off MODERATE',
        detail: 'Visibility: 450m • Low-Beam Req.',
        icon: Icons.cloudy_snowing,
        intensity: 'MODERATE',
        color: Color(0xFFFFC107),
        isActive: true,
      ),
      TriggerStatusCardModel(
        title: 'GridlockGain',
        condition: 'traffic OPTIMAL',
        detail: 'Avg Speed: 42 km/h • Free Flow',
        icon: Icons.traffic,
        intensity: 'OPTIMAL',
        color: Color(0xFF7CFFB2),
        isActive: true,
      ),
    ],
    totalCredits: 1480,
    pendingCredits: 320,
    clearedCredits: 1160,
    shieldCreditsHeader: 'Shield Credits',
    pendingCreditsLabel: 'Pending Validation',
    pendingCreditsCaption: 'Awaiting verification',
    clearedCreditsLabel: 'Cleared Balance',
    clearedCreditsCaption: 'Ready to pay',
    redeemCreditsLabel: 'REDEEM CREDITS',
    nextSettlementDate: '12 MAY',
    settlementTime: 'Sunday Settlement @ 6:00 PM IST',
    countdownDays: 2,
    countdownHours: 14,
    countdownMinutes: 38,
    countdownDaysLabel: 'Days',
    countdownHoursLabel: 'Hours',
    countdownMinutesLabel: 'Mins',
    cycleProgressPercent: 78,
    cycleProgressLabel: 'Cycle Progress',
    verificationEvents: const <VerificationEvent>[
      VerificationEvent(
        title: 'Route Validation Success',
        subtitle: 'FogBlock active during NH-44 Transit',
        impact: '+₹ 45',
        timeAgo: '2h ago',
        icon: Icons.check_circle_outline,
      ),
      VerificationEvent(
        title: 'Gridlock Bonus Pending',
        subtitle: 'Traffic density verification in progress',
        impact: '₹ 12',
        timeAgo: '4h ago',
        icon: Icons.pending_actions,
      ),
    ],
    settlementStatusLabel: 'Weekly Settlement',
    autoTransferMessage: 'Automated bank transfer enabled',
    verificationStreamLabel: 'Verification Stream',
    systemTagline: 'Kavach Max Active',
  );
}
