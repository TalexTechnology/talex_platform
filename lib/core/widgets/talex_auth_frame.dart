import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/theme_toggle_button.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';

// Marco de las pantallas de acceso secundarias: fondo noche con el brillo
// del hero, logo arriba y el contenido en un panel elevado.
class TalexAuthFrame extends StatelessWidget {
  const TalexAuthFrame({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 560,
    this.showBack = true,
    this.onBack,
    this.eyebrow,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final bool showBack;
  final VoidCallback? onBack;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final canGoBack =
        showBack && (onBack != null || Navigator.of(context).canPop());
    return Scaffold(
      body: TalexGlow(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (canGoBack)
                          IconButton(
                            onPressed:
                                onBack ?? () => Navigator.of(context).pop(),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            icon: const Icon(Icons.arrow_back),
                          )
                        else
                          const SizedBox(width: 48),
                        const Expanded(
                          child: Center(
                            child: TalexLogo(width: 132, height: 40),
                          ),
                        ),
                        const LanguageSelector(compact: true),
                        const SizedBox(width: 12),
                        const ThemeToggleButton(size: 36),
                      ],
                    ),
                    const SizedBox(height: 28),
                    TalexPanel(
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (eyebrow != null) ...[
                            TalexEyebrow(eyebrow!),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 28,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.9,
                            ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
