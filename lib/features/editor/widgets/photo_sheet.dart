import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';

/// Opens the photo picker, copies selected image to app documents,
/// returns the relative path (e.g. "photos/abc.jpg") or null.
/// Pass [existingPath] to offer a remove option.
Future<String?> showPhotoSheet(
  BuildContext context, {
  String? existingPath,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _PhotoSheet(existingPath: existingPath),
  );
}

class _PhotoSheet extends StatelessWidget {
  final String? existingPath;
  const _PhotoSheet({this.existingPath});

  Future<String> _resolvePath(String rel) async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$rel';
  }

  Future<String?> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    return image == null ? null : _copyToPhotos(image.path);
  }

  /// System document picker: surfaces Drive, Google Photos, Downloads, etc.
  Future<String?> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif'],
    );
    final path = result?.files.single.path;
    return path == null ? null : _copyToPhotos(path);
  }

  Future<String> _copyToPhotos(String srcPath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos'));
    await photosDir.create(recursive: true);

    final ext      = p.extension(srcPath);
    final fileName = '${const Uuid().v4()}$ext';
    final destPath = p.join(photosDir.path, fileName);
    await File(srcPath).copy(destPath);

    return 'photos/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElev,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: t.outline.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Show current photo preview when editing
          if (existingPath != null)
            FutureBuilder<String>(
              future: _resolvePath(existingPath!),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final file = File(snap.data!);
                if (!file.existsSync()) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file,
                        height: 160, width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                );
              },
            ),
          Text('Attach a photo',
              style: TextStyle(fontFamily: context.fonts.display,
                fontSize: 20, fontWeight: FontWeight.w600,
                color: t.onBackground)),
          const SizedBox(height: 4),
          Text('A visual memory for this entry.',
              style: TextStyle(fontFamily: context.fonts.accent,
                fontSize: 15, color: t.onSurfaceMuted)),
          const SizedBox(height: 24),
          _Option(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            t: t,
            onTap: () async {
              final path = await _pickImage(ImageSource.gallery);
              if (context.mounted) Navigator.of(context).pop(path);
            },
          ),
          const SizedBox(height: 12),
          _Option(
            icon: Icons.photo_camera_outlined,
            label: 'Take photo',
            t: t,
            onTap: () async {
              final path = await _pickImage(ImageSource.camera);
              if (context.mounted) Navigator.of(context).pop(path);
            },
          ),
          const SizedBox(height: 12),
          _Option(
            icon: Icons.folder_open_outlined,
            label: 'Browse files',
            t: t,
            onTap: () async {
              final path = await _pickFromFiles();
              if (context.mounted) Navigator.of(context).pop(path);
            },
          ),
          if (existingPath != null) ...[
            const SizedBox(height: 12),
            _Option(
              icon: Icons.delete_outline_rounded,
              label: 'Remove photo',
              t: t,
              danger: true,
              onTap: () => Navigator.of(context).pop(''),
            ),
          ],
          const SizedBox(height: 12),
          _Option(
            icon: Icons.close_rounded,
            label: 'Cancel',
            t: t,
            onTap: () => Navigator.of(context).pop(null),
            muted: true,
          ),
        ],
      ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final BakaTokens t;
  final VoidCallback onTap;
  final bool danger;
  final bool muted;
  const _Option({
    required this.icon, required this.label, required this.t,
    required this.onTap, this.danger = false, this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : muted ? t.onSurfaceMuted : t.onBackground;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(fontFamily: context.fonts.accent,
            fontSize: 18, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}
