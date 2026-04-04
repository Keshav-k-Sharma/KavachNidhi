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

  bool _initialized = false;
  bool _loading = false;
  bool _mutating = false;
  String? _error;
  List<Map<String, dynamic>> _tiers = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _history = const <Map<String, dynamic>>[];
  Map<String, dynamic>? _activeSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _loadData();
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
        fetchSubscriptionHistory(apiClient),
        fetchActiveSubscription(apiClient).then<Object>(
          (Map<String, dynamic>? value) => value ?? <String, dynamic>{},
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _tiers = results[0] as List<Map<String, dynamic>>;
        _history = results[1] as List<Map<String, dynamic>>;
        final Map<String, dynamic> active = results[2] as Map<String, dynamic>;
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
    required Future<Map<String, dynamic>?> Function(ApiClient apiClient) action,
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: <Widget>[
              Text(
                'Subscriptions',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your active plan and coverage tier.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _buildCurrentPlanCard(theme),
              const SizedBox(height: 20),
              if (_error != null) ...<Widget>[
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildTierCards(theme),
              const SizedBox(height: 20),
              _buildHistorySection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(ThemeData theme) {
    final Map<String, dynamic>? sub = _activeSubscription;
    final bool hasActive = sub != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Current Plan',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActive
                ? 'Kavach ${_prettyTier(sub['tier'] as String?)}'
                : 'No active subscription',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (hasActive)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: <Widget>[
                _infoPair(
                  theme,
                  'Premium',
                  '₹ ${_moneyText(sub['actual_premium'])}',
                ),
                _infoPair(
                  theme,
                  'Coverage cap',
                  '₹ ${_moneyText(sub['cap_amount'])}',
                ),
                _infoPair(
                  theme,
                  'Mandate',
                  _asText(sub['mandate_status']),
                ),
              ],
            )
          else
            Text(
              'Choose a tier below to start coverage.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (hasActive) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _mutating ? null : _cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(_mutating ? 'Please wait...' : 'Cancel subscription'),
            ),
          ],
        ],
      ),
    );
  }

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Available Tiers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._tiers.map((Map<String, dynamic> tier) {
          final String tierKey = _asText(tier['tier']).toLowerCase();
          final _TierAction action = _actionForTier(tierKey);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kavach ${_prettyTier(tierKey)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Base rate ₹ ${_moneyText(tier['base_rate'])} • Cap ₹ ${_moneyText(tier['cap_amount'])}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: (_mutating || action.disabled)
                        ? null
                        : () {
                            if (action.type == _TierActionType.subscribe) {
                              _subscribe(tierKey);
                            } else {
                              _upgrade(tierKey);
                            }
                          },
                    child: Text(action.label),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Recent History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Text(
            'No subscription history yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ..._history.take(8).map((Map<String, dynamic> entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _asText(entry['action']),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _asText(entry['created_at']),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _infoPair(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  _TierAction _actionForTier(String tierKey) {
    final String? activeTier = (_activeSubscription?['tier'] as String?)?.toLowerCase();
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
