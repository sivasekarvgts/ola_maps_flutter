import Flutter
import UIKit
// I'm assuming the SDK is imported like this.
import OlaMaps

class OlaMapView: NSObject, FlutterPlatformView, OlaMapDelegate {
    private var _view: UIView
    private var _mapView: OlaMapView?
    private var _olaMap: OlaMap?
    private var _methodChannel: FlutterMethodChannel
    private var _markers = [String: OlaMarker]()

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        _methodChannel = FlutterMethodChannel(name: "ola_maps_flutter_\(viewId)", binaryMessenger: messenger)
        super.init()
        // The `create` method of the factory is not being called, so we need to create the view here.
        createNativeView(view: _view, args: args)
        _methodChannel.setMethodCallHandler(handle)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView, args: Any?){
        // This is a placeholder for the map initialization.
        // I will assume the API key is passed in the arguments.
        guard let args = args as? [String: Any],
              let apiKey = args["apiKey"] as? String else {
            return
        }

        // Assuming OlaMapView is the main view class for the map
        _mapView = OlaMapView(frame: _view.bounds)
        _mapView?.getMap(apiKey, delegate: self)
        _view.addSubview(_mapView!)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "addMarker":
            addMarker(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func addMarker(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let position = args["position"] as? [String: Double],
              let lat = position["latitude"],
              let lng = position["longitude"],
              let markerId = args["markerId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
            return
        }

        let coordinate = OlaLatLng(latitude: lat, longitude: lng)
        let marker = OlaMarker(position: coordinate)
        marker.markerId = markerId
        marker.title = args["title"] as? String
        marker.snippet = args["snippet"] as? String

        if let iconData = args["icon"] as? [String: Any] {
            if let iconImage = getMarkerIcon(iconData: iconData) {
                marker.icon = iconImage
            }
        }
        
        // Assuming the map object has an addMarker method
        _olaMap?.addMarker(marker)
        _markers[markerId] = marker
        result(markerId)
    }

    private func getMarkerIcon(iconData: [String: Any]) -> UIImage? {
        guard let type = iconData["type"] as? String else {
            return nil
        }

        if type == "asset" {
            guard let assetName = iconData["assetName"] as? String else {
                return nil
            }
            let key = FlutterDartProject.lookupKey(forAsset: assetName)
            let bundle = Bundle(for: type(of: self))
            return UIImage(named: key, in: bundle, compatibleWith: nil)
        } else if type == "bytes" {
            guard let bytes = iconData["bytes"] as? FlutterStandardTypedData else {
                return nil
            }
            return UIImage(data: bytes.data)
        }
        return nil
    }
    
    // MARK: - OlaMapDelegate
    
    func onMapReady(_ map: OlaMap) {
        _olaMap = map
        _methodChannel.invokeMethod("onMapReady", arguments: nil)
    }
    
    func onMapError(_ error: String) {
        _methodChannel.invokeMethod("onMapError", arguments: ["error": error])
    }
}
