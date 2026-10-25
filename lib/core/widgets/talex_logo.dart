import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_assets.dart';

class TalexLogo extends StatelessWidget {
  const TalexLogo({
    super.key,
    this.width = 220,
    this.height = 64,
    this.forDarkBackground = false,
    this.asset,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'TaleX',
  });

  final double width;
  final double height;
  final bool forDarkBackground;
  final String? asset;
  final BoxFit fit;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRect(
      child: Image.asset(
        asset ??
            (forDarkBackground
                ? AppAssets.talexLogoHorizontalDark
                : AppAssets.talexLogoHorizontal),
        fit: fit,
        alignment: Alignment.center,
        semanticLabel: semanticLabel,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          forDarkBackground
              ? AppAssets.talexLogoHorizontalDarkOriginal
              : AppAssets.talexLogoHorizontalOriginal,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          semanticLabel: semanticLabel,
          filterQuality: FilterQuality.high,
        ),
      ),
    ),
  );
}

/// Isotipo de TaleX para TaleXito (botón, encabezado y mensajes).
class TaleXitoMark extends StatelessWidget {
  const TaleXitoMark({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    AppAssets.talexMarkLight,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'TaleXito',
    errorBuilder: (_, _, _) => Icon(
      Icons.chat_bubble_outline,
      size: size * 0.85,
    ),
  );
}
