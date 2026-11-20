import 'package:url_launcher/url_launcher.dart';

/// Opens phone calls, WhatsApp and maps. Returns false if nothing handled it.
abstract class Launcher {
  Future<bool> open(Uri uri);
}

class UrlLauncher implements Launcher {
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
