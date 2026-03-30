import 'package:flutter/material.dart';

/// Top brand row from Stitch: filled shield + KAVACHNIDHI in primary blue.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final Color wordmark = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 56,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.shield_rounded,
            size: 26,
            color: wordmark,
            fill: 1,
          ),
          const SizedBox(width: 8),
          Text(
            'KAVACHNIDHI',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: wordmark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  fontSize: 20,
                ),
          ),
        ],
      ),
    );
  }
}
