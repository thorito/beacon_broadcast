import 'package:beacon_broadcast/beacon_broadcast.dart';

class BeaconConfig {
  final String uuid;
  final int majorId;
  final int minorId;
  final int transmissionPower;
  final AdvertiseMode advertiseMode;
  final String layout;
  final String? identifier;
  final int? manufacturerId;
  final List<int>? extraData;

  BeaconConfig({
    required this.uuid,
    required this.majorId,
    required this.minorId,
    required this.transmissionPower,
    required this.advertiseMode,
    required this.layout,
    this.identifier,
    this.manufacturerId,
    this.extraData,
  });
}
