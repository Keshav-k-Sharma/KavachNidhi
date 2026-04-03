import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/home/presentation/home_dashboard_page.dart';
import 'package:frontend/features/subscriptions/presentation/subscriptions_tab.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  static Widget route() => const MainShellPage();

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          _DashboardTab(),
          SubscriptionsTab(),
          _ProfileTab(),
          _PlaceholderTab(title: 'Wallet', icon: Icons.account_balance_wallet_rounded),
        ],
      ),
      bottomNavigationBar: _KavachBottomNav(
        currentIndex: _currentIndex,
        onTap: (int i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom nav bar ───────────────────────────────────────────────────────────

class _KavachBottomNav extends StatelessWidget {
  const _KavachBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(label: 'Dashboard', icon: Icons.grid_view_rounded, iconSize: 18),
    _NavItem(label: 'Subscriptions', icon: Icons.loyalty_outlined, iconSize: 20),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, iconSize: 16),
    _NavItem(label: 'Wallet', icon: Icons.account_balance_wallet_outlined, iconSize: 18),
  ];

  @override
  Widget build(BuildContext context) {
    const Color navSurface = Color(0xFF0E0E0E);
    const Color navOutline = Color(0xFF484847);
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: navSurface,
        border: Border(
          top: BorderSide(
            color: navOutline.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F89ACFF),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(26, 13, 26, 24 + safeBottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            _items.length,
            (int i) => _NavTile(
              item: _items[i],
              active: i == currentIndex,
              onTap: () => onTap(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF89ACFF);
    const Color inactiveColor = Color(0xFF484847);
    const Color activeBg = Color(0xFF1A1A1A);
    final Color itemColor = active ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                item.icon,
                size: item.iconSize,
                color: itemColor,
              ),
              const SizedBox(height: 4),
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  height: 1.5,
                  color: itemColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconSize,
  });

  final String label;
  final IconData icon;
  final double iconSize;
}

// ─── Tab pages ────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) => HomeDashboardPage.route();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Profile',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Log out',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                subtitle: Text(
                  'Sign out on this device',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () async {
                  await context.read<AuthController>().logout();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.loginRoute,
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
