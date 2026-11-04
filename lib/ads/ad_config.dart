import 'dart:io';

import 'package:flutter/foundation.dart';

class AdConfig {
  static const androidBannerAdUnitId = 'ca-app-pub-4516135061366181/8164441689';
  static const androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';

  static bool get shouldInitialize => !kIsWeb && Platform.isAndroid;

  static String? get bannerAdUnitId {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      return kDebugMode ? androidTestBannerAdUnitId : androidBannerAdUnitId;
    }
    if (Platform.isIOS) return null;
    return null;
  }
}
