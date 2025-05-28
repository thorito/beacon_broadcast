import 'dart:async';

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'beacon_config.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BeaconBroadcast beaconBroadcast = BeaconBroadcast();
  bool _hasPermissions = false;
  bool _isAdvertising = false;
  String _selectedBeaconType = 'iBeacon';
  BeaconStatus? _isTransmissionSupported;
  StreamSubscription<bool>? _isAdvertisingSubscription;

  final Map<String, BeaconConfig> _beaconConfigs = {
    'iBeacon': BeaconConfig(
      uuid: '39ED98FF-2000-441A-802F-9C398FC199D2',
      majorId: 1,
      minorId: 100,
      transmissionPower: -59,
      identifier: 'com.example.iBeacon',
      advertiseMode: AdvertiseMode.lowPower,
      layout: BeaconBroadcast.IBEACON_LAYOUT,
      manufacturerId: 0x004C,
      extraData: [],
    ),
    'AltBeacon': BeaconConfig(
      uuid: '39ED98FF-3000-441A-802F-9C398FC199D2',
      majorId: 1,
      minorId: 100,
      transmissionPower: -59,
      identifier: 'com.example.altBeacon',
      advertiseMode: AdvertiseMode.lowPower,
      layout: BeaconBroadcast.ALTBEACON_LAYOUT,
      manufacturerId: 0x0118,
      extraData: [100],
    ),
    'Eddystone UID': BeaconConfig(
      uuid: '20c48f75868d55aabb6e', // Eddystone Service UUID
      majorId: 0x2a02,
      minorId: 0x1a01,
      transmissionPower: -59,
      identifier: '02e11a024a11',
      advertiseMode: AdvertiseMode.lowPower,
      layout: BeaconBroadcast.EDDYSTONE_UID_LAYOUT,
    ),
  };

  @override
  void initState() {
    super.initState();
    _initializeBeacon();
  }

  @override
  void dispose() {
    _isAdvertisingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _beaconConfigs[_selectedBeaconType]!;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Beacon Broadcast'),
          backgroundColor: Colors.blue,
          elevation: 2,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Status',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.bluetooth,
                                color: _getStatusColor(
                                    _isTransmissionSupported ==
                                        BeaconStatus.supported)),
                            SizedBox(width: 8),
                            Text(
                                'Supported transmission: $_isTransmissionSupported'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.security,
                                color: _getStatusColor(_hasPermissions)),
                            SizedBox(width: 8),
                            Text(
                                'Permissions: ${_hasPermissions ? "Granted" : "Missing"}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.broadcast_on_personal,
                                color: _getStatusColor(_isAdvertising)),
                            SizedBox(width: 8),
                            Text(
                                'Beacon active: ${_isAdvertising ? "Yes" : "No"}'),
                          ],
                        ),
                        if (!_hasPermissions) ...[
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _requestPermissions,
                            icon: Icon(Icons.settings),
                            label: Text('Request permissions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Beacon Type',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedBeaconType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: _beaconConfigs.keys.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: _isAdvertising
                              ? null
                              : (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedBeaconType = newValue;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Controls',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _canStartBeacon() ? _startBeacon : null,
                          icon: Icon(Icons.play_arrow),
                          label: Text('START BEACON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isAdvertising ? _stopBeacon : null,
                          icon: Icon(Icons.stop),
                          label: Text('STOP BEACON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Configuration ($_selectedBeaconType)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        if (_selectedBeaconType != 'Eddystone UID') ...[
                          _buildConfigRow('UUID', currentConfig.uuid),
                          _buildConfigRow(
                              'Major ID', currentConfig.majorId.toString()),
                          _buildConfigRow(
                              'Minor ID', currentConfig.minorId.toString()),
                        ],
                        if (_selectedBeaconType == 'Eddystone UID') ...[
                          _buildConfigRow('Instance', currentConfig.uuid),
                        ],
                        _buildConfigRow(
                            'Identifier', currentConfig.identifier ?? '-'),
                        _buildConfigRow('Power TX',
                            '${currentConfig.transmissionPower} dBm'),
                        _buildConfigRow('Layout', currentConfig.layout),
                        if (currentConfig.manufacturerId != null)
                          _buildConfigRow('Manufacturer ID',
                              '0x${currentConfig.manufacturerId!.toRadixString(16).toUpperCase()}'),
                        if (currentConfig.extraData?.isNotEmpty == true)
                          _buildConfigRow(
                              'Extra Data', currentConfig.extraData.toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child:
                Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeBeacon() async {
    final isTransmissionSupported =
        await beaconBroadcast.checkTransmissionSupported();

    await _checkPermissions();

    setState(() {
      _isTransmissionSupported = isTransmissionSupported;
    });

    _isAdvertisingSubscription =
        beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
      setState(() {
        _isAdvertising = isAdvertising;
      });
    });
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) =>
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited);

    setState(() {
      _hasPermissions = allGranted;
    });
  }

  Future<void> _requestPermissions() async {
    await _checkPermissions();

    if (!_hasPermissions) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Necessary permissions'),
          content: Text(
              'This app requires Bluetooth and location permissions to function properly.'
              'Please enable permissions in the app settings.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _startBeacon() {
    if (!_hasPermissions || !_canStartBeacon()) return;

    final config = _beaconConfigs[_selectedBeaconType]!;

    if (_selectedBeaconType == 'Eddystone UID') {
      beaconBroadcast
          .setUUID(config.uuid)
          .setMajorId(config.majorId)
          .setLayout(config.layout)
          .setTransmissionPower(config.transmissionPower);

      if (config.identifier?.isNotEmpty == true) {
        beaconBroadcast.setIdentifier(config.identifier!);
      }
      if (config.manufacturerId != null) {
        beaconBroadcast.setManufacturerId(config.manufacturerId!);
      }
      if (config.extraData != null) {
        beaconBroadcast.setExtraData(config.extraData!);
      }
    } else {
      beaconBroadcast
          .setUUID(config.uuid)
          .setMajorId(config.majorId)
          .setMinorId(config.minorId)
          .setTransmissionPower(config.transmissionPower)
          .setLayout(config.layout);

      if (config.identifier?.isNotEmpty == true) {
        beaconBroadcast.setIdentifier(config.identifier!);
      }
      if (config.manufacturerId != null) {
        beaconBroadcast.setManufacturerId(config.manufacturerId!);
      }
      if (config.extraData != null) {
        beaconBroadcast.setExtraData(config.extraData!);
      }
    }

    beaconBroadcast.start();
  }

  void _stopBeacon() {
    beaconBroadcast.stop();
  }

  bool _canStartBeacon() {
    return _hasPermissions &&
        _isTransmissionSupported == BeaconStatus.supported &&
        !_isAdvertising;
  }

  Color _getStatusColor(bool condition) {
    return condition ? Colors.green : Colors.red;
  }
}
