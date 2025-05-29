import 'beacon_broadcast_permission_status.dart';

class BeaconBroadcastPermissionResult {
  final BeaconBroadcastPermissionStatus location;
  final BeaconBroadcastPermissionStatus bluetooth;
  final BeaconBroadcastPermissionStatus bluetoothConnect;
  final BeaconBroadcastPermissionStatus bluetoothAdvertise;

  const BeaconBroadcastPermissionResult({
    required this.location,
    required this.bluetooth,
    required this.bluetoothConnect,
    required this.bluetoothAdvertise,
  });

  bool get locationIsGranted =>
      location == BeaconBroadcastPermissionStatus.authorizedAlways &&
      location == BeaconBroadcastPermissionStatus.authorizedWhenInUse;

  bool get locationAlwaysGranted =>
      location == BeaconBroadcastPermissionStatus.authorizedAlways;

  bool get bluetoothIsGranted =>
      bluetooth == BeaconBroadcastPermissionStatus.authorized ||
      bluetooth == BeaconBroadcastPermissionStatus.poweredOff;

  bool get bluetoothConnectIsGranted =>
      bluetoothConnect == BeaconBroadcastPermissionStatus.authorized;

  bool get bluetoothAdvertiseIsGranted =>
      bluetoothAdvertise == BeaconBroadcastPermissionStatus.authorized;

  @override
  String toString() => 'BeaconBroadcastPermissionResult('
      'location: $location, '
      'bluetooth: $bluetooth, '
      'bluetoothConnect: $bluetoothConnect, '
      'bluetoothAdvertise: $bluetoothAdvertise'
      ')';
}
