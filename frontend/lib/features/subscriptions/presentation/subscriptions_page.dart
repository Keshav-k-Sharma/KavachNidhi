import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/subscriptions/data/subscriptions_api.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({
    this.onSubscriptionChanged,
    super.key,
  });

  final VoidCallback? onSubscriptionChanged;

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  static const Map<String, int> _tierOrder = <String, int>{
    'basic': 0,
    'plus': 1,
    'max': 2,
  };

  static const Map<String, _TierMeta> _tierMeta = <String, _TierMeta>{
    'basic': _TierMeta(
      icon: Icons.security_rounded,
      description: 'Essential protection for critical environmental shifts.',
      features: <_TierFeature>[
        _TierFeature(icon: Icons.check_circle, label: 'Unlock CycloneGuard'),
      ],
    ),
    'plus': _TierMeta(
      icon: Icons.verified_user_rounded,
      description:
          'Dual-layer protection for unpredictable climate risks.',
      features: <_TierFeature>[
        _TierFeature(
          icon: Icons.check_circle,
          label: 'CycloneGuard + FogBlock',
        ),
        _TierFeature(
          icon: Icons.check_circle,
          label: 'Instant Wallet Settlement',
        ),
      ],
    ),
    'max': _TierMeta(
      icon: Icons.workspace_premium_rounded,
      description:
          'Full ecosystem coverage with enhanced payout multiples.',
      features: <_TierFeature>[
        _TierFeature(icon: Icons.bolt, label: 'All 3 Triggers Unlocked'),
        _TierFeature(
          icon: Icons.trending_up,
          label: '1.2x Severity Multiplier',
        ),
      ],
    ),
  };

  bool _initialized = false;
  bool _loading = false;
  bool _mutating = false;
  String? _error;
  List<Map<String, dynamic>> _tiers = const <Map<String, dynamic>>[];
  Map<String, dynamic>? _activeSubscription;

  final TextEditingController _topUpController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _loadData();
  }

  @override
  void dispose() {
    _topUpController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ApiClient apiClient = context.read<AuthController>().apiClient;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        fetchSubscriptionTiers(apiClient),
        fetchActiveSubscription(apiClient).then<Object>(
          (Map<String, dynamic>? value) => value ?? <String, dynamic>{},
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _tiers = results[0] as List<Map<String, dynamic>>;
        final Map<String, dynamic> active =
            results[1] as Map<String, dynamic>;
        _activeSubscription = active.isEmpty ? null : active;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load subscription details right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _subscribe(String tier) async {
    await _runMutation(
      successMessage: 'Subscription activated.',
      action: (ApiClient apiClient) => subscribeTier(apiClient, tier: tier),
    );
  }

  Future<void> _upgrade(String tier) async {
    await _runMutation(
      successMessage: 'Subscription upgraded.',
      action: (ApiClient apiClient) => upgradeTier(apiClient, tier: tier),
    );
  }

  Future<void> _cancel() async {
    await _runMutation(
      successMessage: 'Subscription cancelled.',
      action: (ApiClient apiClient) => cancelTier(
        apiClient,
        reason: 'Cancelled from dashboard',
      ),
    );
  }

  Future<void> _runMutation({
    required String successMessage,
    required Future<Map<String, dynamic>?> Function(ApiClient apiClient)
        action,
  }) async {
    final ApiClient apiClient = context.read<AuthController>().apiClient;
    setState(() => _mutating = true);
    final Map<String, dynamic>? response = await action(apiClient);
    if (!mounted) {
      return;
    }
    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request failed. Please try again.')),
      );
      setState(() => _mutating = false);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    await _loadData();
    widget.onSubscriptionChanged?.call();
    if (!mounted) {
      return;
    }
    setState(() => _mutating = false);
  }

  // ─── Layout ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_loading && _tiers.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 128),
            children: <Widget>[
              _buildHeroSection(theme),
              const SizedBox(height: 24),
              if (_error != null) ...<Widget>[
                _buildErrorBanner(theme),
                const SizedBox(height: 16),
              ],
              _buildTierCards(theme),
              const SizedBox(height: 28),
              _buildMandatesSection(theme),
              const SizedBox(height: 28),
              _buildWalletControl(theme),
              const SizedBox(height: 28),
              _buildPayoutNotice(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero Section ───────────────────────────────────────────────────────

  Widget _buildHeroSection(ThemeData theme) {
    final Map<String, dynamic>? sub = _activeSubscription;
    final bool hasActive = sub != null;
    final String walletBalance =
        _moneyText(sub?['wallet_balance'] ?? sub?['cap_amount']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ACTIVE PROTECTION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly Sachet Plan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActive
                ? 'Your digital safety net is currently active. '
                    'Select a tier to adjust your weekly coverage and claim caps.'
                : 'Select a tier below to activate your weekly '
                    'coverage and claim caps.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: <Widget>[
                Text(
                  'NIDHI WALLET BALANCE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                      hasActive ? walletBalance : '0',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2.4,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasActive) ...<Widget>[
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _mutating ? null : _cancel,
                child: Text(
                  _mutating ? 'Please wait...' : 'Cancel subscription',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Error Banner ───────────────────────────────────────────────────────

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tier Cards ─────────────────────────────────────────────────────────

  Widget _buildTierCards(ThemeData theme) {
    if (_tiers.isEmpty) {
      return Text(
        'No tiers available right now.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: _tiers.map((Map<String, dynamic> tier) {
        final String tierKey = _asText(tier['tier']).toLowerCase();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSingleTierCard(theme, tier, tierKey),
        );
      }).toList(),
    );
  }

  Widget _buildSingleTierCard(
    ThemeData theme,
    Map<String, dynamic> tier,
    String tierKey,
  ) {
    final _TierAction action = _actionForTier(tierKey);
    final _TierMeta? meta = _tierMeta[tierKey];
    final bool isRecommended = tierKey == 'plus';
    final bool isCurrent = action.label == 'Current';
    final bool isUpgrade = action.type == _TierActionType.upgrade && !action.disabled;
    final String capAmount = _moneyText(tier['cap_amount']);
    final String baseRate = _moneyText(tier['base_rate']);

    Color iconColor;
    if (tierKey == 'basic') {
      iconColor = theme.colorScheme.secondary;
    } else if (tierKey == 'plus') {
      iconColor = theme.colorScheme.primary;
    } else {
      iconColor = theme.colorScheme.secondary;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: isRecommended
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Recommended badge row (above icon + price)
            if (isRecommended) ...<Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Icon + price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    meta?.icon ?? Icons.shield_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '₹$baseRate',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'PER WEEK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

                // Tier name
                Text(
                  'Kavach ${_prettyTier(tierKey)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  meta?.description ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Feature list
                if (meta != null)
                  ...meta.features.map((_TierFeature f) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            f.icon,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                // Payout cap row
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹$capAmount Payout Cap',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: _buildTierButton(
                    theme,
                    action: action,
                    tierKey: tierKey,
                    isCurrent: isCurrent,
                    isUpgrade: isUpgrade,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTierButton(
    ThemeData theme, {
    required _TierAction action,
    required String tierKey,
    required bool isCurrent,
    required bool isUpgrade,
  }) {
    if (isCurrent) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: theme.colorScheme.primary,
          disabledForegroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          'CURRENT PLAN',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 12,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (isUpgrade) {
      return FilledButton(
        onPressed: _mutating ? null : () => _upgrade(tierKey),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          _mutating ? 'PLEASE WAIT...' : 'UPGRADE NOW',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      );
    }

    // Subscribe / select plan (outlined style)
    return OutlinedButton(
      onPressed: (_mutating || action.disabled)
          ? null
          : () => _subscribe(tierKey),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        _mutating
            ? 'PLEASE WAIT...'
            : (action.disabled ? 'UNAVAILABLE' : 'SELECT PLAN'),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 12,
          color: action.disabled
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ─── Payment Mandates ───────────────────────────────────────────────────

  Widget _buildMandatesSection(ThemeData theme) {
    final String mandateStatus =
        _asText(_activeSubscription?['mandate_status']).toLowerCase();
    final bool upiActive =
        mandateStatus.contains('active') || mandateStatus.contains('live');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'PAYMENT MANDATES',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _buildMandateRow(
          theme,
          icon: Icons.account_balance_rounded,
          title: 'UPI AutoPay',
          subtitle: upiActive ? 'Active via PhonePe' : 'Not configured',
          trailing: upiActive
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 2),
        Divider(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          height: 1,
        ),
        const SizedBox(height: 2),
        _buildMandateRow(
          theme,
          icon: Icons.article_outlined,
          title: 'NACH Mandate',
          subtitle: 'Pending Bank Approval',
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildMandateRow(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22, color: theme.colorScheme.onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ─── Nidhi Wallet Control ───────────────────────────────────────────────

  Widget _buildWalletControl(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'NIDHI WALLET CONTROL',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'MANUAL TOP-UP AMOUNT',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        '₹',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _topUpController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                          isDense: true,
                          hintText: '500',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  'ADD',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <int>[100, 500, 1000].map((int amount) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _QuickChip(
                label: '+ ₹${_moneyText(amount)}',
                onTap: () {
                  _topUpController.text = amount.toString();
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Payout Reliability Notice ──────────────────────────────────────────

  Widget _buildPayoutNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.error,
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Payout Reliability Notice',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    children: const <TextSpan>[
                      TextSpan(
                        text: 'Due to standard banking maintenance, payout '
                            'failures occurring on ',
                      ),
                      TextSpan(
                        text: 'Sundays',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' will be automatically re-attempted on Monday '
                            'morning at 09:00 AM. Your protection coverage '
                            'remains unaffected during this window.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tier action logic ──────────────────────────────────────────────────

  _TierAction _actionForTier(String tierKey) {
    final String? activeTier =
        (_activeSubscription?['tier'] as String?)?.toLowerCase();
    if (activeTier == null) {
      return const _TierAction(
        label: 'Subscribe',
        type: _TierActionType.subscribe,
        disabled: false,
      );
    }
    if (activeTier == tierKey) {
      return const _TierAction(
        label: 'Current',
        type: _TierActionType.subscribe,
        disabled: true,
      );
    }
    final int activeRank = _tierOrder[activeTier] ?? -1;
    final int targetRank = _tierOrder[tierKey] ?? -1;
    if (targetRank <= activeRank) {
      return const _TierAction(
        label: 'Unavailable',
        type: _TierActionType.upgrade,
        disabled: true,
      );
    }
    return const _TierAction(
      label: 'Upgrade',
      type: _TierActionType.upgrade,
      disabled: false,
    );
  }
}

// ─── Quick-add chip ─────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data helpers ───────────────────────────────────────────────────────────

String _prettyTier(String? value) {
  if (value == null || value.isEmpty) {
    return '—';
  }
  if (value.length == 1) {
    return value.toUpperCase();
  }
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String _moneyText(Object? raw) {
  if (raw == null) {
    return '0';
  }
  if (raw is num) {
    if (raw.toDouble() == raw.toInt()) {
      return raw.toInt().toString();
    }
    return raw.toStringAsFixed(2);
  }
  return raw.toString();
}

String _asText(Object? value) {
  if (value == null) {
    return '—';
  }
  final String text = value.toString().trim();
  if (text.isEmpty) {
    return '—';
  }
  return text;
}

// ─── Models ─────────────────────────────────────────────────────────────────

enum _TierActionType { subscribe, upgrade }

class _TierAction {
  const _TierAction({
    required this.label,
    required this.type,
    required this.disabled,
  });

  final String label;
  final _TierActionType type;
  final bool disabled;
}

class _TierMeta {
  const _TierMeta({
    required this.icon,
    required this.description,
    required this.features,
  });

  final IconData icon;
  final String description;
  final List<_TierFeature> features;
}

class _TierFeature {
  const _TierFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
