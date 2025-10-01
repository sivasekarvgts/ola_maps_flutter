import 'package:flutter/services.dart';
import 'dart:typed_data';

void main() async {
  print('Testing asset loading...');

  try {
    // Test loading the pin.png asset
    final ByteData data = await rootBundle.load('pin.png');
    print('✅ Asset loaded successfully: ${data.lengthInBytes} bytes');

    // Convert to Uint8List
    final Uint8List bytes = data.buffer.asUint8List();
    print('✅ Converted to Uint8List: ${bytes.length} bytes');

    // Test if it's a valid image
    if (bytes.length > 0) {
      print('✅ Asset appears to be valid (non-zero length)');
    } else {
      print('❌ Asset is empty');
    }
  } catch (e) {
    print('❌ Error loading asset: $e');
  }
}
