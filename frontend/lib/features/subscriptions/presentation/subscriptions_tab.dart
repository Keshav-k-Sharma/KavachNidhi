import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/subscriptions/data/subscriptions_api.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  bool _initialized = false;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];

  String? _subscribing; // tier name currently being subscribed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ApiClient client =
          context.read<AuthController>().apiClient;
      final Map<String, dynamic>? sub = await fetchMySubscription(client);
      final List<Map<String, dynamic>> tiers = await fetchTiers(client);
      setState(() {
        _subscription = sub;
        _tiers = tiers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _subscribe(String tier) async {
    setState(() => _subscribing = tier);
    try {
      final ApiClient client =
          context.read<AuthController>().apiClient;
      final Map<String, dynamic> sub = await subscribeToTier(client, tier);
      setState(() {
        _subscription = sub;
        _subscribing = null;
      });
    } catch (e) {
      setState(() => _subscribing = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(theme)
                : _subscription != null
                    ? _buildActiveView(theme)
                    : _buildTierPicker(theme),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tier picker (no active subscription) ─────────────────────────────────

  Widget _buildTierPicker(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 128),
      children: <Widget>[
        _buildHeader(theme),
        const SizedBox(height: 8),
        Text(
          'Choose the plan that fits your risk profile. Your actual weekly premium is calculated based on your risk score.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        ..._tiers.map(
          (Map<String, dynamic> tier) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _TierCard(
              tier: tier,
              isSubscribing: _subscribing == tier['tier'],
              anySubscribing: _subscribing != null,
              onSubscribe: () => _subscribe(tier['tier'] as String),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Active subscription view ─────────────────────────────────────────────

  Widget _buildActiveView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 128),
      children: <Widget>[
        _buildHeader(theme),
        const SizedBox(height: 28),
        _ActiveSubscriptionCard(
          subscription: _subscription!,
          onSetupPayment: () {
            // Wired in Step 3 (Razorpay mandate setup)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment setup coming in the next step.'),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Page header ─────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'SUBSCRIPTION',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subscription != null ? 'Your Plan' : 'Pick a Plan',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Tier card ─────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isSubscribing,
    required this.anySubscribing,
    required this.onSubscribe,
  });

  final Map<String, dynamic> tier;
  final bool isSubscribing;
  final bool anySubscribing;
  final VoidCallback onSubscribe;

  static const Map<String, Color> _accentColors = <String, Color>{
    'basic': Color(0xFF89ACFF),
    'plus': Color(0xFFFEB300),
    'max': Color(0xFFB5FFC2),
  };

  static const Map<String, String> _tierLabels = <String, String>{
    'basic': 'BASIC',
    'plus': 'PLUS',
    'max': 'MAX',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String tierKey = tier['tier'] as String? ?? '';
    final double baseRate = (tier['base_rate'] as num?)?.toDouble() ?? 0;
    final double capAmount = (tier['cap_amount'] as num?)?.toDouble() ?? 0;
    final Color accent = _accentColors[tierKey] ?? theme.colorScheme.primary;

    return Container(
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
          // Tier accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Tier label
                Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tierLabels[tierKey] ?? tierKey.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Premium row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '₹',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      baseRate.toStringAsFixed(0),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/ week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Cap badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Cap ₹${capAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Base rate · actual premium varies by risk score',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 20),
                // Subscribe button
                _SubscribeButton(
                  accent: accent,
                  label: 'Subscribe to ${_tierLabels[tierKey] ?? tierKey}',
                  loading: isSubscribing,
                  disabled: anySubscribing,
                  onTap: onSubscribe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subscribe button ─────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.accent,
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  final Color accent;
  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool active = !disabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              : Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: active
                        ? accent
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Active subscription card ──────────────────────────────────────────────────

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({
    required this.subscription,
    required this.onSetupPayment,
  });

  final Map<String, dynamic> subscription;
  final VoidCallback onSetupPayment;

  static const Map<String, Color> _accentColors = <String, Color>{
    'basic': Color(0xFF89ACFF),
    'plus': Color(0xFFFEB300),
    'max': Color(0xFFB5FFC2),
  };

  static const Map<String, String> _tierLabels = <String, String>{
    'basic': 'BASIC',
    'plus': 'PLUS',
    'max': 'MAX',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final String tierKey = subscription['tier'] as String? ?? '';
    final double actualPremium =
        (subscription['actual_premium'] as num?)?.toDouble() ?? 0;
    final double capAmount =
        (subscription['cap_amount'] as num?)?.toDouble() ?? 0;
    final String mandateStatus =
        subscription['mandate_status'] as String? ?? 'pending';
    final Color accent = _accentColors[tierKey] ?? theme.colorScheme.primary;
    final bool mandateActive = mandateStatus == 'active';
    final bool mandateFailed = mandateStatus == 'failed';

    final Color mandateColor = mandateActive
        ? theme.colorScheme.tertiary
        : mandateFailed
            ? theme.colorScheme.error
            : theme.colorScheme.secondary;

    final String mandateLabel = mandateActive
        ? 'PAYMENT ACTIVE'
        : mandateFailed
            ? 'PAYMENT FAILED'
            : 'PAYMENT PENDING';

    return Container(
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
          // Accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'YOUR PLAN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 2.4,
                      ),
                    ),
                    // Mandate status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: mandateColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: mandateColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: mandateColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mandateLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mandateColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tier name
                Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tierLabels[tierKey] ?? tierKey.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actual premium
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '₹',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      actualPremium.toStringAsFixed(2),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/ week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your actual premium based on risk score',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 20),
                // Stats row
                Row(
                  children: <Widget>[
                    _statTile(
                      theme: theme,
                      label: 'INSURED UP TO',
                      value: '₹${capAmount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 12),
                    _statTile(
                      theme: theme,
                      label: 'STATUS',
                      value: 'Active',
                      valueColor: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
                // Setup payment button (only if mandate not yet active)
                if (!mandateActive) ...<Widget>[
                  const SizedBox(height: 24),
                  _GradientButton(
                    label: mandateFailed
                        ? 'Retry Payment Setup'
                        : 'Set Up Weekly Payment',
                    onTap: onSetupPayment,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set up UPI AutoPay to activate your plan. You\'ll be charged ₹${actualPremium.toStringAsFixed(2)} for the first week.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.1,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required ThemeData theme,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient button (matches dashboard style) ────────────────────────────────

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
            ],
          ),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF002053),
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
