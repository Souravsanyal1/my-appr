class AppUsageModel {
  final String packageName;
  final String appName;
  final int usageMillis;

  const AppUsageModel({
    required this.packageName,
    required this.appName,
    required this.usageMillis,
  });

  int get usageMinutes => (usageMillis / (1000 * 60)).round();

  String get formattedUsage {
    final mins = usageMinutes;
    if (mins < 60) {
      return '$mins m';
    }
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    return '${hrs}h ${remMins}m';
  }
}
