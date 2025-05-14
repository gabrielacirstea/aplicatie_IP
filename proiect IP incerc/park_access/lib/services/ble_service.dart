import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';

class BLEService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<void> sendCodeOverBLE(String code) async {
    // Cancel any existing subscription
    await _scanSubscription?.cancel();

    // Start scanning for BLE devices
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Store the subscription
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == AppConstants.bleDeviceName) {
          await FlutterBluePlus.stopScan();
          await _scanSubscription?.cancel();
          _scanSubscription = null;

          if (r.device.connectionState != BluetoothDeviceState.connected) {
            await r.device.connect();
          }

          List<BluetoothService> services = await r.device.discoverServices();
          for (BluetoothService service in services) {
            for (BluetoothCharacteristic c in service.characteristics) {
              if (c.uuid.toString().toLowerCase() ==
                      AppConstants.bleCharacteristicUuid.toLowerCase() &&
                  c.properties.write) {
                await c.write(utf8.encode(code));
              }
            }
          }

          await r.device.disconnect();
          break;
        }
      }
    });
  }

  void dispose() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}
