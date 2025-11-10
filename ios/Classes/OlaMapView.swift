import Flutter
import UIKit
import OlaMapCore

// Helper to convert ARGB integer to UIColor
extension UIColor {
    convenience init(argb: UInt32) {
        let a = CGFloat((argb & 0xFF000000) >> 24) / 255.0
        let r = CGFloat((argb & 0x00FF0000) >> 16) / 255.0
        let g = CGFloat((argb & 0x0000FF00) >> 8) / 255.0
        let b = CGFloat(argb & 0x000000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// To store marker data
struct MarkerInfo {
    let coordinate: OlaCoordinate
    let title: String?
    let snippet: String?
}

// Factory to create OlaMapView instances
class OlaMapFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var registrar: FlutterPluginRegistrar // Add registrar

    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) { // Update init
        self.messenger = messenger
        self.registrar = registrar // Store registrar
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return OlaMapView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            registrar: registrar) // Pass registrar
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// The main PlatformView class using OlaMapService
class OlaMapView: NSObject, FlutterPlatformView, OlaMapServiceDelegate {
    private var mapView: UIView
    private var olaMap: OlaMapService?
    private var methodChannel: FlutterMethodChannel
    private var markers = [String: MarkerInfo]()
    private var polylineIds = Set<String>()
    private var polygonIds = Set<String>()
    private var initialCoordinate: OlaCoordinate?
    private var initialZoom: Double?
    private var mapLoaded = false
    private var mapReady = false
    private var styleLoaded = false
    private var setupDone = false
    private var registrar: FlutterPluginRegistrar // Add registrar property

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger,
        registrar: FlutterPluginRegistrar // Add registrar parameter
    ) {
        mapView = UIView(frame: frame)
        // Ensure the view has proper autoresizing for Flutter
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.backgroundColor = .systemGray6 // Temporary background to see if view exists
        mapView.clipsToBounds = true
        mapView.isHidden = false
        mapView.alpha = 1.0
        print("🗺️ Creating OlaMapView with frame: \(frame)")
        methodChannel = FlutterMethodChannel(name: "ola_maps_flutter_\(viewId)", binaryMessenger: messenger)
        self.registrar = registrar // Store registrar
        super.init()

        methodChannel.setMethodCallHandler(handle)

        guard let arguments = args as? [String: Any],
              let apiKey = arguments["apiKey"] as? String,
              let tileURLString = arguments["tileURL"] as? String,
              let projectId = arguments["projectId"] as? String else {
            print("❌ Error: Missing required arguments for OlaMapService initialization.")
            return
        }
        
        // Process tileURL - ensure it's a valid style.json URL
        var processedTileURLString = tileURLString
        // If the URL doesn't end with .json, try to append /style.json or convert style editor URL
        if !tileURLString.hasSuffix(".json") {
            // Check if it's a style editor URL and convert it
            if tileURLString.contains("styleEditor/v1/styleEdit/styles/") {
                // Convert style editor URL to style.json URL
                // Example: https://api.olamaps.io/styleEditor/v1/styleEdit/styles/9aace31c-8c34-401d-90f5-eafff6e1c518/field-force-old
                // Should become: https://api.olamaps.io/tiles/vector/v1/styles/9aace31c-8c34-401d-90f5-eafff6e1c518/style.json
                if let styleIdRange = tileURLString.range(of: "styles/") {
                    let afterStyles = String(tileURLString[styleIdRange.upperBound...])
                    let components = afterStyles.split(separator: "/")
                    if components.count >= 1 {
                        let styleId = String(components[0])
                        // Extract base URL (everything before styleEditor)
                        if let baseRange = tileURLString.range(of: "styleEditor") {
                            let baseURL = String(tileURLString[..<baseRange.lowerBound])
                            // Construct the proper style.json URL
                            processedTileURLString = "\(baseURL)tiles/vector/v1/styles/\(styleId)/style.json"
                            print("🔄 Converted style editor URL:")
                            print("   From: \(tileURLString)")
                            print("   To: \(processedTileURLString)")
                        }
                    }
                }
            } else if !tileURLString.hasSuffix("/style.json") {
                // Try appending /style.json if it looks like a base URL
                processedTileURLString = tileURLString.hasSuffix("/") ? tileURLString + "style.json" : tileURLString + "/style.json"
                print("🔄 Appended /style.json to URL: \(processedTileURLString)")
            }
        }
        
        guard let tileURL = URL(string: processedTileURLString) else {
            print("❌ Error: Invalid tileURL format: \(processedTileURLString)")
            return
        }
        
        print("📍 Initializing OlaMapService with:")
        print("   API Key: \(apiKey.prefix(10))...")
        print("   Tile URL: \(processedTileURLString)")
        print("   Project ID: \(projectId)")

        // Initialize OlaMapService
        let olaMapInstance = OlaMapService(
            auth: .apiKey(key: apiKey),
            tileURL: tileURL,
            projectId: projectId
        )
        self.olaMap = olaMapInstance
        
        // Set delegate BEFORE loading the map
        olaMapInstance.delegate = self
        
        print("🗺️ OlaMapView received arguments: \(arguments)")
        // Store initial camera position and zoom to apply after map is ready (like Android's setupMap)
        if let initialCameraPositionArgs = arguments["initialCameraPosition"] {
            print("🔍 Raw initialCameraPosition argument: \(initialCameraPositionArgs)")
            if let cameraPosition = initialCameraPositionArgs as? [AnyHashable: Any] { // Changed to AnyHashable
                if let targetDict = cameraPosition["target"] as? [AnyHashable: Any] {
                    print("🔍 targetDict: \(targetDict)")
                    if let lat = targetDict["latitude"] as? Double {
                        print("🔍 lat (Double): \(lat)")
                        if let lng = targetDict["longitude"] as? Double {
                            print("🔍 lng (Double): \(lng)")
                            self.initialCoordinate = OlaCoordinate(latitude: lat, longitude: lng)
                            print("✅ Successfully parsed initialCoordinate: \(self.initialCoordinate!)")
                        } else {
                            print("❌ 'longitude' key not found or not a Double in targetDict: \(targetDict["longitude"] ?? "nil")")
                        }
                    } else {
                        print("❌ 'latitude' key not found or not a Double in targetDict: \(targetDict["latitude"] ?? "nil")")
                    }
                } else {
                    print("❌ 'target' key not found or not a [AnyHashable: Any] in cameraPosition: \(cameraPosition["target"] ?? "nil")")
                }

                if let zoomValue = cameraPosition["zoom"] {
                    if let zoom = zoomValue as? Double {
                        self.initialZoom = zoom
                        print("✅ Successfully parsed initialZoom: \(self.initialZoom!)")
                    } else if let zoomInt = zoomValue as? Int {
                        self.initialZoom = Double(zoomInt)
                        print("✅ Successfully parsed initialZoom (from Int): \(self.initialZoom!)")
                    } else {
                        print("❌ Failed to parse 'zoom' from initialCameraPosition: \(zoomValue)")
                    }
                } else {
                    print("❌ 'zoom' key not found in initialCameraPosition.")
                }
            } else {
                print("❌ initialCameraPosition argument is not a [AnyHashable: Any]: \(initialCameraPositionArgs)")
            }
        } else {
            print("❌ 'initialCameraPosition' key not found in arguments.")
        }
        
        // Delay map loading to ensure view has proper frame
        // Flutter sets the frame during layout, so we wait a bit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadMapIfReady()
        }
        
        if let myLocationEnabled = arguments["myLocationEnabled"] as? Bool, myLocationEnabled {
            setMyLocationEnabled(olaMap: olaMapInstance, enabled: myLocationEnabled)
        }
    }

    // Return the native view to Flutter
    func view() -> UIView {
        print("🗺️ view() method called, returning mapView with frame: \(mapView.frame)")
        // Check if we need to load the map now that view is being returned
        if !mapLoaded && mapView.frame.width > 0 && mapView.frame.height > 0 {
            loadMapIfReady()
        }
        return mapView
    }
    
    // Load map when view has proper frame
    private func loadMapIfReady() {
        guard let olaMap = self.olaMap, !mapLoaded else { return }
        
        // Check if view has a valid frame
        if mapView.frame.width > 0 && mapView.frame.height > 0 {
            print("🗺️ Loading map on view with frame: \(mapView.frame)")
            print("🗺️ Map view bounds: \(mapView.bounds)")
            olaMap.loadMap(onView: mapView, coordinate: initialCoordinate, showCurrentLocationIcon: false)
            mapLoaded = true
            print("🗺️ Map loadMap called, waiting for delegate callbacks...")
        } else {
            print("⚠️ Map view frame is still zero, retrying in 0.1s...")
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loadMapIfReady()
            }
        }
    }

    // Handle method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let olaMap = self.olaMap else {
            result(FlutterError(code: "mapNotInitialized", message: "OlaMapService is not initialized", details: nil))
            return
        }

        switch call.method {
        // Marker Methods
        case "addMarker":
            addMarker(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "removeMarker":
            removeMarker(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "clearMarkers":
            clearMarkers(olaMap: olaMap)
            result(nil)
        
        // Polyline Methods
        case "addPolyline":
            addPolyline(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "removePolyline":
            removePolyline(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "clearPolylines":
            clearPolylines(olaMap: olaMap)
            result(nil)
            
        // Polygon Methods
        case "addPolygon":
            addPolygon(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "removePolygon":
            removePolygon(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "clearPolygons":
            clearPolygons(olaMap: olaMap)
            result(nil)

        // Camera Methods
        case "animateCamera":
            moveCamera(olaMap: olaMap, arguments: call.arguments) // `setCamera` is not animated by default
            result(nil)
        case "moveCamera":
            moveCamera(olaMap: olaMap, arguments: call.arguments)
            result(nil)
        case "getCameraPosition":
            result(getCameraPosition(olaMap: olaMap))
            
        // Map Settings
        case "setMyLocationEnabled":
            guard let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "invalidArgs", message: "Invalid arguments for setMyLocationEnabled", details: nil))
                return
            }
            setMyLocationEnabled(olaMap: olaMap, enabled: enabled)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Implementations

    private func addMarker(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let markerId = args["markerId"] as? String,
              let positionData = args["position"] as? [String: Any],
              let lat = positionData["latitude"] as? Double,
              let lng = positionData["longitude"] as? Double else {
            print("❌ Error: Missing required marker arguments")
            return
        }
        
        let coordinate = OlaCoordinate(latitude: lat, longitude: lng)
        let title = args["title"] as? String
        let snippet = args["snippet"] as? String
        
        let markerInfo = MarkerInfo(coordinate: coordinate, title: title, snippet: snippet)
        markers[markerId] = markerInfo
        
        // Get icon data if provided
        var markerImage: UIImage? = nil
        var iconWidth: CGFloat = 80  // Default size matching Android
        var iconHeight: CGFloat = 80
        
        if let iconData = args["icon"] as? [String: Any] {
            markerImage = getMarkerIcon(iconData: iconData)
            // Get custom width/height if provided
            if let width = iconData["width"] as? Double {
                iconWidth = CGFloat(width)
            }
            if let height = iconData["height"] as? Double {
                iconHeight = CGFloat(height)
            }
        }
        
        // Use default icon if no custom icon provided or loading failed
        if markerImage == nil {
            markerImage = createDefaultMarkerIcon(size: CGSize(width: iconWidth, height: iconHeight))
        }
        
        let annotationView = CustomAnnotationView(identifier: markerId, image: markerImage ?? UIImage())
        annotationView.bounds = CGRect(x: 0, y: 0, width: iconWidth, height: iconHeight)
        
        print("📍 Adding marker \(markerId) at (\(lat), \(lng)) with icon size: \(iconWidth)x\(iconHeight). Marker image is nil: \(markerImage == nil)")
        olaMap.setAnnotationMarker(at: coordinate, annotationView: annotationView, identifier: markerId)
    }
    
    // Get marker icon from icon data
    private func getMarkerIcon(iconData: [String: Any]) -> UIImage? {
        guard let type = iconData["type"] as? String else {
            print("⚠️ Marker icon type not specified")
            return nil
        }
        
        print("🖼️ Loading marker icon type: \(type)")
        
        switch type {
        case "asset":
            if let assetName = iconData["assetName"] as? String {
                print("🖼️ Loading asset: \(assetName)")
                return loadAssetImage(assetName: assetName)
            }
            
        case "bytes":
            if let bytes = iconData["bytes"] as? FlutterStandardTypedData {
                print("🖼️ Loading bytes icon: \(bytes.data.count) bytes")
                return UIImage(data: bytes.data)
            } else if let bytesArray = iconData["bytes"] as? [UInt8] {
                print("🖼️ Loading bytes icon from array: \(bytesArray.count) bytes")
                let data = Data(bytesArray)
                return UIImage(data: data)
            }
            
        case "defaultIcon":
            print("🖼️ Using default icon")
            // Get size from icon data if provided, otherwise use default
            let width = (iconData["width"] as? Double).map { CGFloat($0) } ?? 80
            let height = (iconData["height"] as? Double).map { CGFloat($0) } ?? 80
            return createDefaultMarkerIcon(size: CGSize(width: width, height: height))
            
        default:
            print("⚠️ Unknown icon type: \(type)")
        }
        
        return nil
    }
    
    // Load asset image from Flutter assets
    private func loadAssetImage(assetName: String) -> UIImage? {
        // Use the registrar to lookup the asset path
        let key = registrar.lookupKey(forAsset: assetName)
        if let path = Bundle.main.path(forResource: key, ofType: nil) {
            if let image = UIImage(contentsOfFile: path) {
                print("✅ Loaded asset from Flutter asset bundle: \(assetName)")
                return image
            }
        }
        
        print("❌ Failed to load asset: \(assetName) using registrar. Looked for key: \(key)")
        return nil
    }
    
    // Create a default marker icon (matching Android style and size)
    private func createDefaultMarkerIcon(size: CGSize = CGSize(width: 80, height: 80)) -> UIImage? {
        let width = size.width
        let height = size.height
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: width * scale, height: height * scale)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Scale context to match device scale
        context.scaleBy(x: scale, y: scale)
        
        // Draw a standard map pin marker similar to Android
        // Pin head (circle)
        let pinHeadRadius = width * 0.2
        let pinHeadCenter = CGPoint(x: width / 2, y: pinHeadRadius + 2)
        
        // Pin body (pointed bottom)
        let pinPath = UIBezierPath()
        
        // Start from top center
        pinPath.move(to: CGPoint(x: width / 2, y: 0))
        
        // Draw circle for pin head
        pinPath.addArc(
            withCenter: pinHeadCenter,
            radius: pinHeadRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        
        // Draw pin body (pointed shape)
        let bodyTop = pinHeadCenter.y + pinHeadRadius
        let bodyBottom = height
        let bodyWidth = width * 0.15
        
        pinPath.move(to: CGPoint(x: width / 2, y: bodyTop))
        pinPath.addLine(to: CGPoint(x: width / 2 - bodyWidth, y: bodyBottom - width * 0.1))
        pinPath.addLine(to: CGPoint(x: width / 2, y: bodyBottom))
        pinPath.addLine(to: CGPoint(x: width / 2 + bodyWidth, y: bodyBottom - width * 0.1))
        pinPath.close()
        
        // Fill with red color (standard map marker color)
        let redColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        context.setFillColor(redColor.cgColor)
        context.addPath(pinPath.cgPath)
        context.fillPath()
        
        // Add a white circle in the center for better visibility
        let innerCircleRadius = pinHeadRadius * 0.5
        let innerCirclePath = UIBezierPath(
            arcCenter: pinHeadCenter,
            radius: innerCircleRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(innerCirclePath.cgPath)
        context.fillPath()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func removeMarker(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let markerId = args["markerId"] as? String else {
            return
        }
        olaMap.removeAnnotation(by: markerId)
        markers.removeValue(forKey: markerId)
    }
    
    private func clearMarkers(olaMap: OlaMapService) {
        for markerId in markers.keys {
            olaMap.removeAnnotation(by: markerId)
        }
        markers.removeAll()
    }
    
    // Info Window functionality is not directly supported by OlaMapCore SDK on marker tap.
        // A custom Flutter overlay or a custom marker view with embedded info would be needed.
        // Removing these methods as they are not functioning as intended for info windows.
    
    private func addPolyline(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let polylineId = args["polylineId"] as? String,
              let points = args["points"] as? [[String: Any]] else {
            return
        }
        
        let coordinates = points.compactMap { point -> OlaCoordinate? in
            guard let lat = point["latitude"] as? Double, let lng = point["longitude"] as? Double else { return nil }
            return OlaCoordinate(latitude: lat, longitude: lng)
        }
        
        let color = (args["color"] as? UInt32).map { UIColor(argb: $0) } ?? .darkGray
        
        olaMap.showPolyline(identifier: polylineId, .solid, coordinates, color)
        polylineIds.insert(polylineId)
    }

    private func removePolyline(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let polylineId = args["polylineId"] as? String else {
            return
        }
        olaMap.deletePolyline(polylineId)
        polylineIds.remove(polylineId)
    }

    private func clearPolylines(olaMap: OlaMapService) {
        for polylineId in polylineIds {
            olaMap.deletePolyline(polylineId)
        }
        polylineIds.removeAll()
    }
    
    private func addPolygon(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let polygonId = args["polygonId"] as? String,
              let points = args["points"] as? [[String: Any]] else {
            return
        }
        
        let coordinates = points.compactMap { point -> OlaCoordinate? in
            guard let lat = point["latitude"] as? Double, let lng = point["longitude"] as? Double else { return nil }
            return OlaCoordinate(latitude: lat, longitude: lng)
        }
        
        let fillColor = (args["fillColor"] as? UInt32).map { UIColor(argb: $0) } ?? .systemGreen.withAlphaComponent(0.25)
        let strokeColor = (args["strokeColor"] as? UInt32).map { UIColor(argb: $0) } ?? .black
        let strokeWidth = args["strokeWidth"] as? CGFloat ?? 2.5
        
        olaMap.drawPolygon(identifier: polygonId, coordinates, zoneColor: fillColor, strokeColor: strokeColor, storkeWidth: strokeWidth)
        polygonIds.insert(polygonId)
    }

    private func removePolygon(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let polygonId = args["polygonId"] as? String else {
            return
        }
        olaMap.deletePolygon(polygonId)
        polygonIds.remove(polygonId)
    }

    private func clearPolygons(olaMap: OlaMapService) {
        for polygonId in polygonIds {
            olaMap.deletePolygon(polygonId)
        }
        polygonIds.removeAll()
    }
    
    private func moveCamera(olaMap: OlaMapService, arguments: Any?) {
        guard let args = arguments as? [String: Any],
              let targetData = args["target"] as? [String: Any],
              let lat = targetData["latitude"] as? Double,
              let lng = targetData["longitude"] as? Double,
              let zoom = args["zoom"] as? Double else {
            return
        }
        
        let coordinate = OlaCoordinate(latitude: lat, longitude: lng)
        olaMap.setCamera(at: coordinate, zoomLevel: zoom)
    }

    private func getCameraPosition(olaMap: OlaMapService) -> [String: Any]? {
        // The underlying map object is not exposed, so we cannot get the position directly.
        // This would need to be exposed by the OlaMapService SDK.
        // Returning nil for now.
        return nil
    }
    
    private func setMyLocationEnabled(olaMap: OlaMapService, enabled: Bool) {
        if enabled {
            olaMap.addCurrentLocationButton(mapView)
        } else {
            // The SDK documentation does not provide a way to remove the current location button.
            // This is a limitation of the current SDK.
            print("Warning: OlaMapService SDK does not provide a way to disable the 'My Location' button once enabled.")
        }
    }

    // MARK: - OlaMapServiceDelegate Methods

    func didTapOnMap(_ coordinate: OlaCoordinate) {
        // Check if a marker was tapped
        if let tappedMarkerId = findTappedMarker(at: coordinate) {
            methodChannel.invokeMethod("onMarkerTap", arguments: ["markerId": tappedMarkerId])
        } else {
            // If no marker was tapped, invoke the general map click event
            let latLng: [String: Double] = ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
            methodChannel.invokeMethod("onMapClick", arguments: latLng)
        }
    }
    
    // Helper to find if a marker was tapped within a certain radius
    private func findTappedMarker(at tappedCoordinate: OlaCoordinate) -> String? {
        let tapRadius: Double = 0.0005 // Adjust this value as needed (e.g., 0.0005 degrees is approx 50 meters)
        
        for (markerId, markerInfo) in markers {
            let distance = calculateDistance(coord1: tappedCoordinate, coord2: markerInfo.coordinate)
            if distance < tapRadius {
                return markerId
            }
        }
        return nil
    }
    
    // Very basic distance calculation (approximation for small distances)
    private func calculateDistance(coord1: OlaCoordinate, coord2: OlaCoordinate) -> Double {
        let latDiff = coord1.latitude - coord2.latitude
        let lonDiff = coord1.longitude - coord2.longitude
        return sqrt(latDiff * latDiff + lonDiff * lonDiff)
    }
    
    func didTapOnMap(feature: POIModel) {
        // This is a required delegate method.
        // Currently, there is no equivalent event in the Flutter controller.
        print("Tapped on POI: \(feature.name ?? "Unknown")")
    }
    
    func didLongTapOnMap(_ coordinate: OlaCoordinate) {
        // Commented out to isolate the protocol conformance issue.
        // let latLng: [String: Double] = ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
        // methodChannel.invokeMethod("onMapLongClick", arguments: latLng)
    }
    
    func didChangeCamera() {
        // The new camera position is not provided in the delegate.
        // We can't send the updated position back.
        methodChannel.invokeMethod("onCameraMove", arguments: nil)
    }
    
    func mapSuccessfullyLoaded() {
        print("✅ Map Loaded Successfully")
        print("✅ Map view frame: \(mapView.frame)")
        print("✅ Map view bounds: \(mapView.bounds)")
        print("✅ Map view subviews count: \(mapView.subviews.count)")
        
        // Mark map as ready
        mapReady = true
        
        // Ensure the map view is visible
        DispatchQueue.main.async {
            self.mapView.isHidden = false
            self.mapView.alpha = 1.0
            self.mapView.backgroundColor = .clear // Remove temporary background
            // Force layout update
            self.mapView.setNeedsLayout()
            self.mapView.layoutIfNeeded()
            print("✅ Map view visibility updated")
            
            // Setup map after both map and style are loaded
            self.setupMapAfterReady()
        }
    }
    
    // Setup map after it's fully loaded (similar to Android's setupMap)
    // According to iOS SDK docs: setCamera(at:zoomLevel:) should be called after map is ready
    private func setupMapAfterReady() {
        guard let olaMap = self.olaMap, mapReady, styleLoaded else {
            // Wait for both map and style to be loaded before setting camera
            if !mapReady {
                print("⚠️ Cannot setup map - map not ready yet")
            }
            if !styleLoaded {
                print("⚠️ Cannot setup map - style not loaded yet")
            }
            return
        }
        
        // Only setup once
        if setupDone {
            return
        }
        setupDone = true
        
        print("🔧 Setting up map after ready (map and style both loaded)...")
        
        // Set initial camera position if provided
        // According to iOS SDK docs: olaMap.setCamera(at: OlaCoordinate, zoomLevel: Double)
        if let coordinate = initialCoordinate, let zoom = initialZoom {
            print("📍 Setting initial camera position: (\(coordinate.getLatitude), \(coordinate.getLongitude)) at zoom: \(zoom)")
            olaMap.setCamera(at: coordinate, zoomLevel: zoom)
        } else if let coordinate = initialCoordinate {
            // If no zoom specified, use default zoom level
            print("📍 Setting initial camera position: (\(coordinate.getLatitude), \(coordinate.getLongitude)) at default zoom: 12.0")
            olaMap.setCamera(at: coordinate, zoomLevel: 12.0)
        } else {
            print("ℹ️ No initial camera position provided")
        }
    }
    
    func mapSuccessfullyLoadedStyle() {
        // This is a required delegate method.
        print("✅ Map Style Loaded Successfully")
        
        // Mark style as loaded
        styleLoaded = true
        
        DispatchQueue.main.async {
            self.mapView.backgroundColor = .clear // Ensure background is clear after style loads
            
            // Setup map after both map and style are loaded
            self.setupMapAfterReady()
        }
    }
    
    func regionIsChanging(_ gesture: OlaMapGesture) {
        // This is a required delegate method.
        // Called when the map region is changing due to a gesture.
        print("Map region is changing with gesture: \(gesture)")
    }
    
    func didRouteSelected(_ overviewPolyline: String) {
        // This is a required delegate method.
        // Called when a route is selected.
        print("Route selected: \(overviewPolyline)")
    }
    
    func mapFailedToLoad(_ error: Error) {
        // This is a required delegate method.
        // Called when the map fails to load.
        print("❌ Map failed to load with error: \(error.localizedDescription)")
        print("❌ Error details: \(error)")
        print("❌ Map view frame at error: \(mapView.frame)")
        print("❌ Map view bounds at error: \(mapView.bounds)")
        // Keep gray background to show error state
        DispatchQueue.main.async {
            self.mapView.backgroundColor = .systemRed.withAlphaComponent(0.1)
        }
        methodChannel.invokeMethod("onMapError", arguments: ["error": error.localizedDescription])
    }
}