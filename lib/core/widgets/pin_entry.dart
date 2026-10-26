import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';

class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onComplete;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final count = InvitePin.length;
        final maxSide = 56.0;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : maxSide * count + gap * (count - 1);
        final side = ((available - gap * (count - 1)) / count).clamp(
          40.0,
          maxSide,
        );
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: side * count + gap * (count - 1),
            height: side,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: i == count - 1 ? 0 : gap,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: side,
                          height: side,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  widget.focusNode.hasFocus && value.length == i
                                  ? AppColors.green
                                  : AppColors.border,
                              width:
                                  widget.focusNode.hasFocus && value.length == i
                                  ? 1.5
                                  : 1,
                            ),
                          ),
                          child: Text(
                            i < value.length ? value[i] : '',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: InvitePin.length,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(InvitePin.length),
                    ],
                    style: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 22,
                    ),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (text) {
                      if (text.trim().length == InvitePin.length) {
                        widget.onComplete?.call();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
