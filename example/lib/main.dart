import 'dart:async';
import 'dart:io' show Platform;

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // UUID can be provided with or without hyphens
  // Both formats are valid and will be automatically formatted:
  // With hyphens: 'DA123456-7899-8765-4da8-97da654da987'
  // Without hyphens: 'DA123456789987654da897da654da987'
  static const String uuid =
      'DA123456789987654da897da654da987'; // Without hyphens example
  static const int majorId = 1;
  static const int minorId = 100;
  static const int transmissionPower = -59;
  static const String identifier = 'com.example.myDeviceRegion';
  static const AdvertiseMode advertiseMode = AdvertiseMode.lowPower;
  static const String layout = BeaconBroadcast.ALTBEACON_LAYOUT;
  static const int manufacturerId = 0x0118;
  static const List<int> extraData = [100];

  BeaconBroadcast beaconBroadcast = BeaconBroadcast();

  bool _isAdvertising = false;
  bool _isTransmissionSupported = true;
  StreamSubscription<bool>? _isAdvertisingSubscription;

  @override
  void initState() {
    super.initState();

    try {
      beaconBroadcast
          .checkTransmissionSupported()
          .then((isTransmissionSupported) {
        setState(() {
          _isTransmissionSupported = true;
        });
      });
    } catch (e) {
      print('Error checking transmission support: $e');
      setState(() {
        _isTransmissionSupported = false;
      });
    }

    if (!_isTransmissionSupported) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              'Beacon transmission unsupported on this device'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      _isAdvertisingSubscription =
          beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
            setState(() {
              _isAdvertising = isAdvertising;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Beacon Broadcast'),
        ),
        body: Builder(
            builder: (scaffoldContext) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAdvertising ? Colors.green : Colors.grey.shade300,
                          ),
                          child: Icon(
                            _isAdvertising ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdvertising ? 'Broadcasting' : 'Idle',
                          style: Theme.of(scaffoldContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isAdvertising ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isTransmissionSupported)

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isAdvertising
                                  ? null
                                  : () async {
                                      if (Platform.isAndroid) {
                                        final permissions = [
                                          Permission.bluetoothAdvertise,
                                          Permission.bluetoothConnect,
                                          Permission.bluetoothScan,
                                          Permission.locationWhenInUse,
                                        ];
                                        final statuses = await permissions.request();
                                        final allGranted = statuses.values
                                            .every((s) => s.isGranted);

                                        if (!allGranted) {
                                          if (scaffoldContext.mounted) {
                                            ScaffoldMessenger.of(scaffoldContext)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Permissions denied'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      try {
                                        final isEddystone = layout ==
                                                BeaconBroadcast.EDDYSTONE_TLM_LAYOUT ||
                                            layout ==
                                                BeaconBroadcast.EDDYSTONE_UID_LAYOUT ||
                                            layout ==
                                                BeaconBroadcast.EDDYSTONE_URL_LAYOUT;

                                        await beaconBroadcast
                                            .setUUID(uuid, isEddystone)
                                            .setMajorId(majorId)
                                            .setMinorId(minorId)
                                            .setTransmissionPower(transmissionPower)
                                            .setAdvertiseMode(advertiseMode)
                                            .setIdentifier(identifier)
                                            .setLayout(layout)
                                            .setManufacturerId(manufacturerId)
                                            .setExtraData(extraData)
                                            .start();
                                      } catch (e) {
                                        if (scaffoldContext.mounted) {
                                          ScaffoldMessenger.of(scaffoldContext)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Error: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 5),
                                            ),
                                          );
                                        }
                                        print('Error starting beacon: $e');
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey,
                              ),
                              child: const Text('START'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isAdvertising
                                  ? () {
                                      beaconBroadcast.stop();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey,
                              ),
                              child: const Text('STOP'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        Text('Beacon Data',
                            style:
                                Theme.of(scaffoldContext).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text('Beacon Data',
                            style:
                                Theme.of(scaffoldContext).textTheme.bodySmall),
                        Text('UUID: $uuid'),
                        Text('Major id: $majorId'),
                        Text('Minor id: $minorId'),
                        Text('Tx Power: $transmissionPower'),
                        Text('Advertise Mode Value: $advertiseMode'),
                        Text('Identifier: $identifier'),
                        Text('Layout: $layout'),
                        Text('Manufacturer Id: $manufacturerId'),
                        Text('Extra data: $extraData'),
                      ],
                    ),
                  ),
                )),
      ),
    );

  @override
  void dispose() {
    _isAdvertisingSubscription?.cancel();
    super.dispose();
  }
}
