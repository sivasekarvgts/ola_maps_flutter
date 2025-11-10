import Flutter
import UIKit
import OlaMapCore

public class OlaMapsFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = OlaMapFactory(messenger: registrar.messenger(), registrar: registrar)
    registrar.register(factory, withId: "ola_maps_flutter/map_view")
  }
}
