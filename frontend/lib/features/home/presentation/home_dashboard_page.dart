import 'package:flutter/material.dart';

import 'package:frontend/features/home/data/dashboard_mock_data.dart';
import 'package:frontend/features/home/presentation/widgets/home_kpi_card.dart';
import 'package:frontend/features/home/presentation/widgets/trigger_status_card.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    required this.dashboard,
    super.key,
  });

  final DashboardSnapshot dashboard;

  static Widget route() {
    return HomeDashboardPage(dashboard: getMockDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: <Widget>[
            _buildHeader(context, theme),
            const SizedBox(height: 24),
            _buildSystemCard(context, theme),
            const SizedBox(height: 20),
            _buildCreditsCard(context, theme),
            const SizedBox(height: 20),
            _buildTriggerFeed(context, theme),
            const SizedBox(height: 20),
            _buildSettlementCard(context, theme),
            const SizedBox(height: 20),
            _buildVerificationStream(context, theme),
            const SizedBox(height: 32), // Bottom breathing room
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            'KavachNidhi',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dashboard.systemStatusValue,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            dashboard.systemStatusLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dashboard.systemTagline,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                dashboard.sensorStatusLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dashboard.sensorStatusValue,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsCard(BuildContext context, ThemeData theme) {
    final CurrencyFormat currencyFormat = const CurrencyFormat();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.stars_rounded,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              dashboard.shieldCreditsHeader,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          currencyFormat.format(dashboard.totalCredits),
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.secondary,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Available Balance',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: HomeKpiCard(
                title: dashboard.pendingCreditsLabel,
                value: currencyFormat.format(dashboard.pendingCredits),
                subtitle: dashboard.pendingCreditsCaption,
                accentColor: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HomeKpiCard(
                title: dashboard.clearedCreditsLabel,
                value: currencyFormat.format(dashboard.clearedCredits),
                subtitle: dashboard.clearedCreditsCaption,
                accentColor: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              dashboard.redeemCreditsLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerFeed(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Live Feed',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 16),
        ...dashboard.triggers.map(
          (TriggerStatusCardModel trigger) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TriggerStatusCard(trigger: trigger),
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.timer_sharp,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Weekly Settlement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'NEXT: ${dashboard.nextSettlementDate}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dashboard.settlementTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _countdownTile(
                  context,
                  value: dashboard.countdownDays.toString(),
                label: dashboard.countdownDaysLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _countdownTile(
                  context,
                  value: dashboard.countdownHours.toString(),
                label: dashboard.countdownHoursLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _countdownTile(
                  context,
                  value: dashboard.countdownMinutes.toString(),
                label: dashboard.countdownMinutesLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: dashboard.cycleProgressPercent / 100,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                dashboard.cycleProgressLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${dashboard.cycleProgressPercent}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dashboard.autoTransferMessage,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownTile(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value.padLeft(2, '0'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStream(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          dashboard.verificationStreamLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 16),
        ...dashboard.verificationEvents.map(
          (VerificationEvent event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _verificationItem(context, event),
          ),
        ),
      ],
    );
  }

  Widget _verificationItem(BuildContext context, VerificationEvent event) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            event.icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                event.impact,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.timeAgo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrencyFormat {
  const CurrencyFormat();

  String format(int value) {
    return '₹ ${value.toString()}';
  }
}
