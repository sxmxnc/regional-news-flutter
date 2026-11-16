import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String?> currentDeviceContext() async {
  try {
    final PackageInfo package = await PackageInfo.fromPlatform();
    final String device = await _deviceDescription();
    return '${package.appName} ${package.version} '
        '(${package.buildNumber}) · $device';
  } on Object catch (error) {
    developer.log(
      'App-Version nicht lesbar: $error',
      name: 'currentDeviceContext',
    );
    return null;
  }
}

Future<String> _deviceDescription() async {
  final DeviceInfoPlugin plugin = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await plugin.androidInfo;
      return '${info.manufacturer} ${info.model}, '
          'Android ${info.version.release}';
    }
    if (Platform.isIOS) {
      final IosDeviceInfo info = await plugin.iosInfo;
      return '${info.utsname.machine}, iOS ${info.systemVersion}';
    }
  } on Object catch (error) {
    // Fällt auf die Betriebssystemkennung zurück.
    developer.log(
      'Geräteangabe nicht lesbar: $error',
      name: 'currentDeviceContext',
    );
  }
  return Platform.operatingSystem;
}
