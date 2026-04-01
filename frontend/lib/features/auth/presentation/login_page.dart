import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/auth/phone_format.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_feature_tile.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:frontend/features/auth/presentation/widgets/primary_action_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  String? _mobileValidator(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'Enter your mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(raw)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  Future<void> _requestOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _sending = true);
    final String digits = _mobileController.text.trim();
    final String e164 = indiaMobileToE164(digits);
    try {
      await context.read<AuthController>().requestOtp(e164);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushNamed(
        AppRouter.otpRoute,
        arguments: digits,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure your hard-earned savings today.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 28),
                      AuthTextField(
                        label: 'Mobile Number',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        hintText: '9876543210',
                        prefixText: '+91 ',
                        validator: _mobileValidator,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OTP will be sent to this number for verification',
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
                        label: _sending ? 'Sending…' : 'Request OTP',
                        icon: Icons.arrow_forward,
                        onPressed: _sending ? null : _requestOtp,
                      ),
                      const SizedBox(height: 16),
                      AuthFooterLink(
                        prompt: "Don't have an account?",
                        actionLabel: 'Sign up',
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRouter.signupRoute);
                        },
                      ),
                      const SizedBox(height: 24),
                      const AuthFeatureTile(
                        icon: Icons.lock_outline,
                        title: 'Bank-Grade Protection',
                        subtitle:
                            'Your money is secured with Vajra-Shield encryption.',
                      ),
                      const SizedBox(height: 12),
                      const AuthFeatureTile(
                        icon: Icons.currency_rupee,
                        title: 'Instant Withdrawals',
                        subtitle:
                            'Access your daily wages 24/7 without delays.',
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
