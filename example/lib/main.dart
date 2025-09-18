import 'dart:async';

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

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
  BeaconStatus? _isTransmissionSupported;
  StreamSubscription<bool>? _isAdvertisingSubscription;

  @override
  void initState() {
    super.initState();
    beaconBroadcast
        .checkTransmissionSupported()
        .then((isTransmissionSupported) {
      setState(() {
        _isTransmissionSupported = isTransmissionSupported;
      });
    });

    _isAdvertisingSubscription =
        beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
      setState(() {
        _isAdvertising = isAdvertising;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Is transmission supported?',
                            style:
                                Theme.of(scaffoldContext).textTheme.bodyMedium),
                        Text('$_isTransmissionSupported',
                            style:
                                Theme.of(scaffoldContext).textTheme.bodySmall),
                        Container(height: 16.0),
                        Text('Has beacon started?',
                            style:
                                Theme.of(scaffoldContext).textTheme.bodyMedium),
                        Text('$_isAdvertising',
                            style:
                                Theme.of(scaffoldContext).textTheme.bodySmall),
                        Container(height: 16.0),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
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

                                if (scaffoldContext.mounted) {
                                  ScaffoldMessenger.of(scaffoldContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Beacon broadcast started successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
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
                            child: Text('START'),
                          ),
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              beaconBroadcast.stop();
                            },
                            child: Text('STOP'),
                          ),
                        ),
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
  }

  @override
  void dispose() {
    _isAdvertisingSubscription?.cancel();
    super.dispose();
  }
}
