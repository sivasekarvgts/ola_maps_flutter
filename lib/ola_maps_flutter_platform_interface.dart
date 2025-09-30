import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ola_maps_flutter_method_channel.dart';

abstract class OlaMapsFlutterPlatform extends PlatformInterface {
  /// Constructs a OlaMapsFlutterPlatform.
  OlaMapsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static OlaMapsFlutterPlatform _instance = MethodChannelOlaMapsFlutter();

  /// The default instance of [OlaMapsFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelOlaMapsFlutter].
  static OlaMapsFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OlaMapsFlutterPlatform] when
  /// they register themselves.
  static set instance(OlaMapsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
