import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.label,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
    this.height = 48,
    this.iconColor,
    this.borderColor,
    this.focusedBorderColor,
    this.fillColor,
    this.textStyle,
    this.hintStyle,
    this.decoration,
  });
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final double height;
  final Color? iconColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? fillColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      style:
          widget.textStyle ??
          TextStyle(color: AppColors.text, fontSize: 15),
      decoration:
          widget.decoration ??
          InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            hintStyle:
                widget.hintStyle ??
                TextStyle(color: AppColors.textDimmer, fontSize: 15),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, color: (widget.iconColor ?? AppColors.textDimmer), size: 21),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() {
                      _obscureText = !_obscureText;
                    }),
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: (widget.iconColor ?? AppColors.textDimmer),
                      size: 20,
                    ),
                    tooltip: _passwordTooltip(context),
                  )
                : null,
            filled: true,
            fillColor: widget.fillColor ?? AppColors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.icon == null ? 16 : 0,
              vertical: 13,
            ),
            border: _border((widget.borderColor ?? AppColors.border)),
            enabledBorder: _border((widget.borderColor ?? AppColors.border)),
            focusedBorder: _border((widget.focusedBorderColor ?? AppColors.blue), 1.5),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
    ),
  );

  String _passwordTooltip(BuildContext context) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    if (_obscureText) return isSpanish ? 'Mostrar contraseña' : 'Show password';
    return isSpanish ? 'Ocultar contraseña' : 'Hide password';
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadii.border,
        borderSide: BorderSide(color: color, width: width),
      );
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style:
        style ??
        TextStyle(
          color: AppColors.textMuted,
          fontSize: 13.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
  );
}
