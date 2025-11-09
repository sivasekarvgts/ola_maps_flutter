
library ola_maps_flutter;

import 'package:flutter/services.dart';

// Export main widget
export 'src/ola_map.dart';

// Export controller
export 'src/ola_map_controller.dart';

// Export models
export 'src/models/camera_position.dart';
export 'src/models/lat_lng.dart';
export 'src/models/marker.dart';
export 'src/models/polyline.dart';
export 'src/models/polygon.dart';


// Main plugin class for initialization
class OlaMapsFlutter {
  static const MethodChannel _channel = MethodChannel('ola_maps_flutter');

  static Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
