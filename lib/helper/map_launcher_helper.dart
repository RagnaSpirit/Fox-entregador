import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';

class MapLauncherHelper {
  const MapLauncherHelper._();

  static Future<void> openMap({
    required double latitude,
    required double longitude,
  }) async {
    final TargetPlatform platform = defaultTargetPlatform;
    final String url = kIsWeb
        ? 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&mode=d'
        : platform == TargetPlatform.iOS
            ? 'http://maps.apple.com/?daddr=$latitude,$longitude'
            : 'geo:$latitude,$longitude?q=$latitude,$longitude';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('could_not_launch'.tr);
    }
  }
}
