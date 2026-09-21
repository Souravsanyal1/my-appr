import 'dart:convert';
import 'dart:typed_data';

class InstalledAppModel {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final String? iconBase64;
  final bool isMonitored;
  final String category;
  final Uint8List? _cachedIconBytes;

  InstalledAppModel({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.iconBase64,
    this.isMonitored = false,
    this.category = 'Social media',
    Uint8List? cachedIconBytes,
  }) : _cachedIconBytes = cachedIconBytes ?? _decodeBase64(iconBase64);

  static Uint8List? _decodeBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  /// Fast cached access to decoded launcher icon bytes (0 decoding on scroll)
  Uint8List? get iconBytes => _cachedIconBytes;

  InstalledAppModel copyWith({
    String? packageName,
    String? appName,
    bool? isSystemApp,
    String? iconBase64,
    bool? isMonitored,
    String? category,
    Uint8List? cachedIconBytes,
  }) {
    return InstalledAppModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      iconBase64: iconBase64 ?? this.iconBase64,
      isMonitored: isMonitored ?? this.isMonitored,
      category: category ?? this.category,
      cachedIconBytes: cachedIconBytes ?? _cachedIconBytes,
    );
  }

  factory InstalledAppModel.fromMap(
    Map<String, dynamic> map, {
    bool isMonitored = false,
  }) {
    final rawBase64 = map['iconBase64'] as String?;
    return InstalledAppModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      iconBase64: rawBase64,
      isMonitored: isMonitored,
      category: map['category'] as String? ?? 'Social media',
      cachedIconBytes: _decodeBase64(rawBase64),
    );
  }
}
