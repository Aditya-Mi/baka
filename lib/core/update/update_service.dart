import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final latest  = data['latest_version']  as String;
      final minimum = data['min_version']      as String;
      final force   = data['force_update']     as bool;
      final url     = data['download_url']     as String;
      final message = data['message']          as String;

      final current = info.version; // e.g. "1.0.0"

      final outdated   = _isOlder(current, latest);
      final mustUpdate = _isOlder(current, minimum);

      if (!outdated) return;
      if (!context.mounted) return;

      _showDialog(
        context,
        message: message,
        url: url,
        force: force || mustUpdate,
      );
    } catch (_) {
      // Network error — silent fail, don't block user
    }
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
      builder: (ctx) => AlertDialog(
        title: const Text('Update available',
            style: TextStyle(fontFamily: 'PlayfairDisplay',
                fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text(message,
            style: const TextStyle(fontFamily: 'Caveat', fontSize: 16)),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later',
                  style: TextStyle(fontFamily: 'Caveat', fontSize: 16)),
            ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication),
            child: const Text('Download',
                style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Returns true if [a] is older than [b] (semver: "1.0.0" < "1.1.0")
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