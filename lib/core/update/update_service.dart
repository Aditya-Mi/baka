import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart' show OpenFile, ResultType;
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:baka/core/fonts/font_theme.dart';

class UpdateService {
  static const _gistUrl =
      'https://gist.githubusercontent.com/Aditya-Mi/844910fd9ae91b00392be0d64dc6453e/raw/gistfile1.txt';

  static bool _checked = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (_checked) return;
    _checked = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final resp = await http
          .get(Uri.parse(_gistUrl))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return;

      final data    = jsonDecode(resp.body) as Map<String, dynamic>;
      final latest  = data['latest_version'] as String;
      final minimum = data['min_version']     as String;
      final force   = data['force_update']    as bool;
      final message = data['message']         as String;
      final url     = 'https://github.com/Aditya-Mi/Baka/releases/download/v$latest/app-release.apk';

      final current  = info.version;
      final outdated = _isOlder(current, latest);
      final mustUpdate = _isOlder(current, minimum);

      if (!outdated) return;
      if (!context.mounted) return;

      _showDialog(
        context,
        message: message,
        url: url,
        force: force || mustUpdate,
      );
    } catch (_) {}
  }

  static void _showDialog(
    BuildContext context, {
    required String message,
    required String url,
    required bool force,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => _UpdateDialog(
        message: message,
        url: url,
        force: force,
      ),
    );
  }

  static bool _isOlder(String a, String b) {
    final av = a.split('.').map(int.parse).toList();
    final bv = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (av[i] < bv[i]) return true;
      if (av[i] > bv[i]) return false;
    }
    return false;
  }
}

class _UpdateDialog extends StatefulWidget {
  final String message;
  final String url;
  final bool force;

  const _UpdateDialog({
    required this.message,
    required this.url,
    required this.force,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress; // null = idle, 0.0–1.0 = downloading
  String? _error;

  void _showInstallPermissionDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Permission needed',
            style: TextStyle(fontFamily: context.fonts.display,
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Allow Baka to install apps.\nSettings → Apps → Baka → Install unknown apps',
          style: TextStyle(fontFamily: context.fonts.accent, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(fontFamily: context.fonts.accent, fontSize: 15)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Open Settings',
                style: TextStyle(fontFamily: context.fonts.accent,
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _download() async {
    setState(() { _progress = 0; _error = null; });
    try {
      final request  = http.Request('GET', Uri.parse(widget.url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        setState(() { _progress = null; _error = 'Download failed (${response.statusCode})'; });
        return;
      }

      final total    = response.contentLength ?? 0;
      final dir      = await getTemporaryDirectory();
      final file     = File('${dir.path}/baka_update.apk');
      final sink     = file.openWrite();
      int received   = 0;

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && mounted) {
          setState(() => _progress = received / total);
        }
      });
      await sink.close();

      if (!mounted) return;

      // Check "Install unknown apps" permission (Android 8+)
      final canInstall = await Permission.requestInstallPackages.isGranted;
      if (!canInstall && mounted) {
        Navigator.of(context).pop();
        _showInstallPermissionDialog(context);
        return;
      }

      Navigator.of(context).pop();
      final result = await OpenFile.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open installer: ${result.message}',
              style: TextStyle(fontFamily: context.fonts.accent))),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _progress = null; _error = 'Download failed. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null;

    return AlertDialog(
      title: Text('Update available',
          style: TextStyle(fontFamily: context.fonts.display,
              fontSize: 18, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message,
              style: TextStyle(fontFamily: context.fonts.accent, fontSize: 16)),
          if (downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 6),
            Text(
              _progress == 0 || _progress == null
                  ? 'Starting download…'
                  : '${(_progress! * 100).toInt()}%',
              style: TextStyle(fontFamily: context.fonts.accent, fontSize: 13),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: TextStyle(
                    fontFamily: context.fonts.accent, fontSize: 13, color: Colors.red)),
          ],
        ],
      ),
      actions: [
        if (!widget.force && !downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Later',
                style: TextStyle(fontFamily: context.fonts.accent, fontSize: 16)),
          ),
        if (!downloading)
          TextButton(
            onPressed: _download,
            child: Text(_error != null ? 'Retry' : 'Download',
                style: TextStyle(
                    fontFamily: context.fonts.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
