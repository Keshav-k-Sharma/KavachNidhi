import 'package:flutter/material.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_feature_tile.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:frontend/features/auth/presentation/widgets/primary_action_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _platformIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _platformIdController.dispose();
    super.dispose();
  }

  String? _nameValidator(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'Enter your full name';
    }
    if (raw.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'Enter your phone number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(raw)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String? _platformIdValidator(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'Enter your platform ID';
    }
    if (raw.length < 4) {
      return 'Platform ID is too short';
    }
    return null;
  }

  void _createAccount() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created locally. Please log in.')),
    );
    Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
  }

  void _goToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: AuthBrandHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VAJRA SHIELD PROTECTION',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.headlineMedium,
                          children: <InlineSpan>[
                            const TextSpan(text: 'Join '),
                            TextSpan(
                              text: 'KavachNidhi',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Securing the future of India's gig workforce with resilience and architectural depth.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        hintText: 'Suhas Kumar',
                        validator: _nameValidator,
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hintText: '9876543210',
                        validator: _phoneValidator,
                        icon: Icons.smartphone_outlined,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Platform ID',
                        controller: _platformIdController,
                        hintText: 'Swiggy-1234',
                        validator: _platformIdValidator,
                        icon: Icons.work_outline,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Used to verify your Shield Credit eligibility',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryActionButton(
                        label: 'Create Account',
                        icon: Icons.arrow_forward,
                        onPressed: _createAccount,
                      ),
                      const SizedBox(height: 16),
                      AuthFooterLink(
                        prompt: 'Already have an account?',
                        actionLabel: 'Log in',
                        onTap: _goToLogin,
                      ),
                      const SizedBox(height: 24),
                      const AuthFeatureTile(
                        icon: Icons.security_outlined,
                        title: 'Safe Deposit',
                        subtitle: 'Secured by Vault-Grade Encryption',
                      ),
                      const SizedBox(height: 12),
                      const AuthFeatureTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Shield Credits',
                        subtitle: 'Instant benefits for gig workers',
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Resilient Monolith v1.0',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
