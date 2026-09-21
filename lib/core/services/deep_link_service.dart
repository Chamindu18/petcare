import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  StreamSubscription<Uri>? _subscription;

  /// Starts listening for incoming app links.
  ///
  /// Returns the initial URI when the app was launched from a link.
  Future<Uri?> start({required ValueChanged<Uri> onLink}) async {
    await _subscription?.cancel();

    _subscription = _appLinks.uriLinkStream.listen(
      onLink,
      onError: (_) {
        // Ignore malformed/platform stream errors.
        // Individual URI handling is performed by the caller.
      },
    );

    return _appLinks.getInitialLink();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
