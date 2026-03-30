import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hintText,
    this.prefixText,
    this.validator,
    this.icon,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final String? prefixText;
  final FormFieldValidator<String>? validator;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixIcon: icon == null ? null : Icon(icon),
          ),
        ),
      ],
    );
  }
}
