import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/features/home/data/dashboard_snapshot.dart';
import 'package:frontend/features/home/data/wallet_api.dart';
import 'package:frontend/features/home/presentation/widgets/trigger_status_card.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({
    required this.dashboard,
    super.key,
  });

  final DashboardSnapshot dashboard;

  static Widget route() {
    return const _HomeDashboardLoader();
  }

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  late final PageController _liveFeedPageController;
  int _liveFeedPageIndex = 0;

  DashboardSnapshot get dashboard => widget.dashboard;

  @override
  void initState() {
    super.initState();
    _liveFeedPageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _liveFeedPageController.dispose();
    super.dispose();
  }

  // ─── Layout ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 128),
          children: <Widget>[
            _buildHeader(context, theme),
            const SizedBox(height: 24),
            _buildSystemCard(context, theme),
            const SizedBox(height: 20),
            _buildSensorFeed(context, theme),
            const SizedBox(height: 20),
            _buildCreditsCard(context, theme),
            const SizedBox(height: 20),
            _buildSettlementCard(context, theme),
            const SizedBox(height: 20),
            _buildVerificationStream(context, theme),
          ],
        ),
      ),
    );
  }

  // ─── App header ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Logo mark
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shield_rounded,
            color: theme.colorScheme.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        // App name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'KavachNidhi',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              Text(
                dashboard.planName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        // Profile avatar placeholder
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                // Online indicator dot
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── System status card (Figma node 1:365) ───────────────────────────────

  Widget _buildSystemCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Left: status label + tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  dashboard.systemStatusLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dashboard.systemTagline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: live feed label + encrypted status + live dot
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                'Live Feed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    dashboard.systemStatusValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _LiveDot(color: theme.colorScheme.tertiary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sensor feed carousel (Figma node 1:380) ─────────────────────────────

  static const double _carouselHeight = 164;

  Widget _buildSensorFeed(BuildContext context, ThemeData theme) {
    final List<TriggerStatusCardModel> triggers = dashboard.triggers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                dashboard.sensorStatusLabel.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Row(
                children: <Widget>[
                  Text(
                    dashboard.sensorStatusValue,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF716C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (triggers.isEmpty)
          Text(
            'No live feed items.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...<Widget>[
          SizedBox(
            height: _carouselHeight,
            child: PageView.builder(
              controller: _liveFeedPageController,
              itemCount: triggers.length,
              onPageChanged: (int index) {
                setState(() => _liveFeedPageIndex = index);
              },
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TriggerStatusCard(trigger: triggers[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(triggers.length, (int i) {
              final bool active = i == _liveFeedPageIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // ─── Shield credits card (Figma node 1:428) ──────────────────────────────

  Widget _buildCreditsCard(BuildContext context, ThemeData theme) {
    final CurrencyFormat fmt = const CurrencyFormat();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // Ambient glow orb (top-right)
            Positioned(
              top: -48,
              right: -48,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      blurRadius: 48,
                      spreadRadius: 32,
                    ),
                  ],
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.stars_rounded,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dashboard.shieldCreditsHeader.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Big balance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '₹',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatNumber(dashboard.totalCredits),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -2.4,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Pending + Cleared tiles
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _creditTile(
                          theme: theme,
                          label: dashboard.pendingCreditsLabel,
                          value: fmt.format(dashboard.pendingCredits),
                          valueColor: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _creditTile(
                          theme: theme,
                          label: dashboard.clearedCreditsLabel,
                          value: fmt.format(dashboard.clearedCredits),
                          valueColor: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Gradient redeem button
                  _GradientButton(
                    label: dashboard.redeemCreditsLabel,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditTile({
    required ThemeData theme,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Weekly settlement card (Figma node 1:454) ───────────────────────────

  Widget _buildSettlementCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                dashboard.settlementStatusLabel.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                'NEXT: ${dashboard.nextSettlementDate}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Subtitle
          Center(
            child: Text(
              dashboard.settlementTime,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Inline countdown: 02 : 14 : 38
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _countdownUnit(theme, dashboard.countdownDays.toString(), dashboard.countdownDaysLabel),
              _colonSeparator(theme),
              _countdownUnit(theme, dashboard.countdownHours.toString(), dashboard.countdownHoursLabel),
              _colonSeparator(theme),
              _countdownUnit(theme, dashboard.countdownMinutes.toString(), dashboard.countdownMinutesLabel),
            ],
          ),
          const SizedBox(height: 20),
          // Progress labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                dashboard.cycleProgressLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${dashboard.cycleProgressPercent}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Amber gradient progress bar
          _GradientProgressBar(value: dashboard.cycleProgressPercent / 100),
          const SizedBox(height: 20),
          // Auto-transfer footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dashboard.autoTransferMessage,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownUnit(ThemeData theme, String value, String label) {
    return Column(
      children: <Widget>[
        Text(
          value.padLeft(2, '0'),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _colonSeparator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 12, right: 12),
      child: Text(
        ':',
        style: theme.textTheme.displaySmall?.copyWith(
          color: theme.colorScheme.outlineVariant,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }

  // ─── Verification stream (Figma node 1:502) ──────────────────────────────

  Widget _buildVerificationStream(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            dashboard.verificationStreamLabel.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...dashboard.verificationEvents.map(
          (VerificationEvent event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _verificationItem(context, event, theme),
          ),
        ),
      ],
    );
  }

  Widget _verificationItem(BuildContext context, VerificationEvent event, ThemeData theme) {
    final bool isPositive = event.impact.startsWith('+');
    final Color impactColor = isPositive
        ? theme.colorScheme.tertiary
        : theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              event.icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                event.impact,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: impactColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event.timeAgo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatNumber(int value) {
  final String s = value.toString();
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class CurrencyFormat {
  const CurrencyFormat();
  String format(int value) => '₹ ${_formatNumber(value)}';
}

// ─── Private widgets ─────────────────────────────────────────────────────────

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF0F6DF3), Color(0xFF89ACFF)],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF002053),
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: <Widget>[
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFFEB300), Color(0xFFFFC96F)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 1,
                  color: const Color(0x1AFFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loader ───────────────────────────────────────────────────────────────────

class _HomeDashboardLoader extends StatefulWidget {
  const _HomeDashboardLoader();

  @override
  State<_HomeDashboardLoader> createState() => _HomeDashboardLoaderState();
}

class _HomeDashboardLoaderState extends State<_HomeDashboardLoader> {
  Future<DashboardSnapshot>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadDashboard();
  }

  Future<DashboardSnapshot> _loadDashboard() async {
    final AuthController auth =
        Provider.of<AuthController>(context, listen: false);
    final DashboardSnapshot base = await loadDashboardSnapshot();
    if (!auth.isAuthenticated) {
      return base;
    }
    try {
      final Map<String, dynamic>? wallet =
          await fetchWalletBalance(auth.apiClient);
      if (wallet == null) {
        return base;
      }
      final Object? shieldRaw = wallet['shield_credits'];
      if (shieldRaw is num) {
        return base.copyWith(totalCredits: shieldRaw.round());
      }
    } catch (_) {}
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSnapshot>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<DashboardSnapshot> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                'Unable to load dashboard data.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        return HomeDashboardPage(dashboard: snapshot.data!);
      },
    );
  }
}
