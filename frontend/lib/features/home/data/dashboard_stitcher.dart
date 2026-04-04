import 'package:flutter/material.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/home/data/dashboard_api.dart';
import 'package:frontend/features/home/data/dashboard_snapshot.dart';

/// Composes [DashboardSnapshot] from the static asset plus existing API endpoints.
/// Fields with no backend mapping use [double.nan] (see plan).
Future<DashboardSnapshot> stitchDashboardSnapshot({
  required DashboardSnapshot base,
  required ApiClient apiClient,
  required bool isAuthenticated,
}) async {
  if (!isAuthenticated) {
    return base.withProtectedFieldsNan();
  }

  final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
    fetchWalletBalance(apiClient),
    fetchRiskScore(apiClient),
    fetchActiveSubscription(apiClient),
    fetchNextSettlement(apiClient),
    fetchWalletTransactions(apiClient, page: 1, limit: 15),
  ]);

  final Map<String, dynamic>? wallet = results[0] as Map<String, dynamic>?;
  final Map<String, dynamic>? risk = results[1] as Map<String, dynamic>?;
  final Map<String, dynamic>? subscription = results[2] as Map<String, dynamic>?;
  final Map<String, dynamic>? settlement = results[3] as Map<String, dynamic>?;
  final List<dynamic>? transactions = results[4] as List<dynamic>?;

  final List<TriggerStatusCardModel> triggersWithNan = base.triggers
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
      .toList(growable: false);

  final double shield = _pickWalletDouble(wallet, const <String>[
    'shield_credits',
    'shieldCredits',
  ]);
  final double pending = _pickWalletDouble(wallet, const <String>[
    'pending_credits',
    'pendingCredits',
    'pending_validation_credits',
  ]);
  final double cleared = _pickWalletDouble(wallet, const <String>[
    'cleared_credits',
    'clearedCredits',
    'cleared_balance',
  ]);

  final String planLabel = _subscriptionPlanLabel(subscription) ?? base.planName;
  final String tagline = _subscriptionTagline(subscription) ?? base.systemTagline;

  final String systemValue = risk != null
      ? _formatRiskDisplay(_readDouble(risk['risk_score']))
      : '—';

  String nextDate = base.nextSettlementDate;
  String settlementLine = base.settlementTime;
  String autoMsg = base.autoTransferMessage;
  if (settlement != null) {
    final String? day = settlement['settlement_day'] as String?;
    final String? time = settlement['settlement_time'] as String?;
    if (day != null && day.isNotEmpty) {
      nextDate = _compactDay(day);
    }
    if (day != null && time != null) {
      settlementLine = '$day Settlement @ $time';
    }
    final double est = _readDouble(settlement['estimated_amount']);
    if (!est.isNaN) {
      autoMsg = 'Estimated next payout: ₹${_formatIntish(est)}';
    }
  }

  final List<VerificationEvent> events = _verificationFromTransactions(transactions);

  return base.copyWith(
    planName: planLabel,
    systemTagline: tagline,
    systemStatusValue: systemValue,
    triggers: triggersWithNan,
    totalCredits: wallet == null ? double.nan : shield,
    pendingCredits: wallet == null ? double.nan : pending,
    clearedCredits: wallet == null ? double.nan : cleared,
    nextSettlementDate: nextDate,
    settlementTime: settlementLine,
    autoTransferMessage: autoMsg,
    countdownDays: double.nan,
    countdownHours: double.nan,
    countdownMinutes: double.nan,
    cycleProgressPercent: double.nan,
    verificationEvents: events,
  );
}

double _pickWalletDouble(Map<String, dynamic>? wallet, List<String> keys) {
  if (wallet == null) {
    return double.nan;
  }
  for (final String k in keys) {
    if (wallet.containsKey(k) && wallet[k] != null) {
      final double v = _readDouble(wallet[k]);
      if (!v.isNaN) {
        return v;
      }
    }
  }
  return double.nan;
}

double _readDouble(Object? raw) {
  if (raw == null) {
    return double.nan;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw) ?? double.nan;
  }
  return double.nan;
}

String _formatRiskDisplay(double score) {
  if (score.isNaN) {
    return '—';
  }
  final int pct = (score.clamp(0.0, 1.0) * 100).round();
  return '$pct% RISK';
}

String? _subscriptionPlanLabel(Map<String, dynamic>? sub) {
  if (sub == null) {
    return null;
  }
  final String? tier = sub['tier'] as String?;
  if (tier == null || tier.isEmpty) {
    return null;
  }
  final String t = tier.length == 1
      ? tier.toUpperCase()
      : '${tier[0].toUpperCase()}${tier.substring(1)}';
  return 'Kavach $t Active';
}

String? _subscriptionTagline(Map<String, dynamic>? sub) {
  if (sub == null) {
    return null;
  }
  final String? tier = sub['tier'] as String?;
  if (tier == null) {
    return null;
  }
  return 'Plan tier: $tier';
}

String _compactDay(String day) {
  final String s = day.trim();
  if (s.length <= 6) {
    return s.toUpperCase();
  }
  return s.substring(0, 3).toUpperCase();
}

String _formatIntish(double v) {
  if (v.isNaN) {
    return '—';
  }
  if (v == v.roundToDouble()) {
    return v.round().toString();
  }
  return v.toStringAsFixed(2);
}

List<VerificationEvent> _verificationFromTransactions(List<dynamic>? rows) {
  if (rows == null || rows.isEmpty) {
    return const <VerificationEvent>[];
  }
  final List<VerificationEvent> out = <VerificationEvent>[];
  for (final Object? raw in rows) {
    if (raw is! Map<String, dynamic>) {
      continue;
    }
    final Map<String, dynamic> m = raw;
    final String type = (m['type'] as String?) ?? 'transaction';
    final String title = _titleForTransactionType(type);
    final String subtitle = (m['description'] as String?) ?? type;
    final double amount = _readDouble(m['amount']);
    final String impact = amount.isNaN ? '—' : '₹ ${_formatIntish(amount)}';
    final String timeAgo = _relativeTime(m['created_at']);
    final String iconKey = _iconKeyForTransactionType(type);
    out.add(
      VerificationEvent(
        title: title,
        subtitle: subtitle,
        impact: impact,
        timeAgo: timeAgo,
        icon: _safeIcon(iconKey),
      ),
    );
    if (out.length >= 10) {
      break;
    }
  }
  return out;
}

String _titleForTransactionType(String type) {
  switch (type) {
    case 'settlement':
      return 'Settlement';
    case 'credit':
    case 'shield_credit':
      return 'Credit';
    case 'debit':
      return 'Debit';
    default:
      return 'Wallet activity';
  }
}

String _iconKeyForTransactionType(String type) {
  switch (type) {
    case 'settlement':
      return 'payments';
    case 'debit':
      return 'swap_horiz';
    default:
      return 'receipt_long';
  }
}

IconData _safeIcon(String key) {
  try {
    return parseDashboardIconKey(key);
  } catch (_) {
    return parseDashboardIconKey('receipt_long');
  }
}

String _relativeTime(Object? raw) {
  if (raw == null) {
    return '—';
  }
  DateTime? dt;
  if (raw is String) {
    dt = DateTime.tryParse(raw);
  }
  if (dt == null) {
    return '—';
  }
  final DateTime now = DateTime.now().toUtc();
  final DateTime t = dt.toUtc();
  final Duration d = now.difference(t);
  if (d.inMinutes < 1) {
    return 'just now';
  }
  if (d.inHours < 1) {
    return '${d.inMinutes}m ago';
  }
  if (d.inHours < 48) {
    return '${d.inHours}h ago';
  }
  return '${d.inDays}d ago';
}
