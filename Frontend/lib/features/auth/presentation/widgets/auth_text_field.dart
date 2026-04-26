import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

  const AuthTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.strokeLight),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.greyText,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
