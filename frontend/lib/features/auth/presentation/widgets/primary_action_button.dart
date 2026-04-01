import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  static const Color _primaryDim = Color(0xFF0F6DF3);
  static const Color _primary = Color(0xFF89ACFF);
  static const Color _onPrimaryFixed = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryDim, _primary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D0F6DF3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: _onPrimaryFixed,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              if (icon != null) ...<Widget>[
                const SizedBox(width: 12),
                Icon(icon, size: 18, color: _onPrimaryFixed),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}
