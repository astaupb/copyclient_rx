import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<int> getDeviceId(BuildContext context) async {
  int deviceId;
  String device;

  try {
    print('scanning qr code');
    device = await BarcodeScanner.scan();
    print('qr code scanned: $device');
  } catch (e) {
    print('exception while scanning barcode: $e');
    if (e is PlatformException) {
      print('PlatformException: ${e.code} ${e.details} ${e.message}');
      if (e.code == 'PERMISSION_NOT_GRANTED') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: Duration(seconds: 5),
            content: Text(
                'Keine Berechtigung zum Nutzen der Kamera. Bitte erlaube dies in den Einstellungen um den Druck per QR-Code zu nutzen.')));
      }
    } else if (e is FormatException) {
      print('FormatException: ${e.message} ${e.offset} ${e.source}');
      if (e.message == 'Invalid envelope') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            duration: Duration(seconds: 3), content: Text('QR-Code Scan wurde abgebrochen')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            duration: Duration(seconds: 5),
            content: Text(
                'Es wurde kein gültiger QR-Code gescannt. Bitte nutze die QR Codes auf den Displays der Drucker.')));
      }
      return null;
    }
  }

  if (device != null && device.isNotEmpty && device.length == 5) deviceId = int.tryParse(device);

  if (deviceId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 5),
        content: Text(
            'Es wurde kein gültiger QR-Code gescannt. Bitte nutze die QR Codes auf den Displays der Drucker.'),
      ),
    );
  }

  return deviceId;
}
