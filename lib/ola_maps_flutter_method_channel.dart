import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ola_maps_flutter_platform_interface.dart';

/// An implementation of [OlaMapsFlutterPlatform] that uses method channels.
class MethodChannelOlaMapsFlutter extends OlaMapsFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ola_maps_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
