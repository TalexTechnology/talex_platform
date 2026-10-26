import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/l10n/l10n.dart';

class LogoSelection {
  const LogoSelection({this.url, this.bytes, this.contentType});
  final String? url;
  final Uint8List? bytes;
  final String? contentType;
}

class LogoField extends StatefulWidget {
  const LogoField({super.key, required this.onChanged, this.initialUrl});
  final String? initialUrl;
  final ValueChanged<LogoSelection> onChanged;

  @override
  State<LogoField> createState() => _LogoFieldState();
}

class _LogoFieldState extends State<LogoField> {
  late final TextEditingController _url;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    final extension = file.extension;
    final contentType = extension == 'jpg' || extension == 'jpeg'
        ? 'image/jpeg'
        : extension == 'gif'
        ? 'image/gif'
        : extension == 'webp'
        ? 'image/webp'
        : 'image/png';
    setState(() => _bytes = bytes);
    widget.onChanged(
      LogoSelection(
        url: _url.text.trim().isEmpty ? null : _url.text.trim(),
        bytes: bytes,
        contentType: contentType,
      ),
    );
  }

  void _onUrl(String value) {
    widget.onChanged(
      LogoSelection(url: value.trim().isEmpty ? null : value.trim(), bytes: _bytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = _url.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _url,
            onChanged: _onUrl,
            decoration: InputDecoration(
              labelText: l10n.pasteLogoUrl,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(l10n.selectLogoFile),
          ),
          const SizedBox(height: 8),
          Text(l10n.logoPreview, style: TextStyle(color: AppColors.textDimmer)),
          const SizedBox(height: 8),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderStrong),
              borderRadius: AppRadii.border,
              color: AppColors.logoBackdrop,
            ),
            clipBehavior: Clip.antiAlias,
            child: _bytes != null
                ? Image.memory(_bytes!, fit: BoxFit.contain)
                : url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                  )
                : Icon(Icons.apartment_outlined, color: AppColors.textDimmer),
          ),
        ],
      ),
    );
  }
}
