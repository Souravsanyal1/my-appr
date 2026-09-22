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
  }) : _cachedIconBytes = cachedIconBytes ??
            _decodeBase64(iconBase64, packageName: packageName);

  static final Map<String, Uint8List> _globalIconCache = {};

  static Uint8List? _decodeBase64(String? base64Str, {String? packageName}) {
    if (base64Str == null || base64Str.isEmpty) return null;
    if (packageName != null && _globalIconCache.containsKey(packageName)) {
      return _globalIconCache[packageName];
    }
    try {
      var sanitized = base64Str.trim().replaceAll(RegExp(r'\s+'), '');
      if (sanitized.contains(',')) {
        sanitized = sanitized.split(',').last;
      }
      final decoded = base64Decode(sanitized);
      if (packageName != null) {
        _globalIconCache[packageName] = decoded;
      }
      return decoded;
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
    final pkgName = map['packageName'] as String? ?? '';
    return InstalledAppModel(
      packageName: pkgName,
      appName: map['appName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      iconBase64: rawBase64,
      isMonitored: isMonitored,
      category: map['category'] as String? ?? 'Social media',
      cachedIconBytes: _decodeBase64(rawBase64, packageName: pkgName),
    );
  }
}
