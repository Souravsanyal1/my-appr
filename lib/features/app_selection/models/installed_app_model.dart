import 'dart:convert';
import 'dart:typed_data';

class InstalledAppModel {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final String? iconBase64;
  final bool isMonitored;

  const InstalledAppModel({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.iconBase64,
    this.isMonitored = false,
  });

  Uint8List? get iconBytes {
    if (iconBase64 == null || iconBase64!.isEmpty) return null;
    try {
      return base64Decode(iconBase64!);
    } catch (_) {
      return null;
    }
  }

  InstalledAppModel copyWith({
    String? packageName,
    String? appName,
    bool? isSystemApp,
    String? iconBase64,
    bool? isMonitored,
  }) {
    return InstalledAppModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      iconBase64: iconBase64 ?? this.iconBase64,
      isMonitored: isMonitored ?? this.isMonitored,
    );
  }

  factory InstalledAppModel.fromMap(Map<String, dynamic> map, {bool isMonitored = false}) {
    return InstalledAppModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      iconBase64: map['iconBase64'] as String?,
      isMonitored: isMonitored,
    );
  }
}
