class PairedDevice {
  final String deviceId;
  final String deviceName;
  final String sharedSecretBase64;
  final String pairedAt;

  PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.sharedSecretBase64,
    required this.pairedAt,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'sharedSecretBase64': sharedSecretBase64,
        'pairedAt': pairedAt,
      };

  factory PairedDevice.fromJson(Map<String, dynamic> json) => PairedDevice(
        deviceId: json['deviceId'] as String,
        deviceName: json['deviceName'] as String,
        sharedSecretBase64: json['sharedSecretBase64'] as String,
        pairedAt: json['pairedAt'] as String,
      );
}
