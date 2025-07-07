import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  
  static bool get canDownloadFiles => !kIsWeb;
  static bool get canShareFiles => !kIsWeb;
  
  static String get platformName {
    if (kIsWeb) return 'Web';
    return 'Mobile';
  }
}