import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:frontend/features/auth/presentation/widgets/primary_action_button.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    required this.phoneDigits,
    super.key,
  });

  /// 10-digit local number without country code.
  final String phoneDigits;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _otpValidator(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'Enter the OTP';
    }
    if (raw.length < 4) {
      return 'Enter the OTP you received';
    }
    return null;
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final AuthController auth = context.read<AuthController>();
      await auth.signInWithOtp(
        phoneDigits: widget.phoneDigits,
        otp: _otpController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homeRoute,
        (Route<dynamic> route) => false,
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
        setState(() => _submitting = false);
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
                        'Enter OTP',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a code to +91 ${widget.phoneDigits}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 28),
                      AuthTextField(
                        label: 'One-time password',
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        hintText: '123456',
                        validator: _otpValidator,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryActionButton(
                        label: _submitting ? 'Verifying…' : 'Verify & continue',
                        icon: Icons.verified_outlined,
                        onPressed: _submitting ? null : _verify,
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
