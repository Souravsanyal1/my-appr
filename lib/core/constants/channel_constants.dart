class ChannelConstants {
  static const String methodChannel = "com.focusdeen.app/methods";
  static const String eventChannel = "com.focusdeen.app/events";

  // Methods
  static const String getInstalledApps = "getInstalledApps";
  static const String getAppUsage = "getAppUsage";
  static const String checkPermissions = "checkPermissions";
  static const String requestPermission = "requestPermission";
  static const String syncLimits = "syncLimits";
  static const String setTemporaryUnlock = "setTemporaryUnlock";
  static const String removeTemporaryUnlock = "removeTemporaryUnlock";
  static const String getUnlockSessions = "getUnlockSessions";
  static const String closeForegroundApp = "closeForegroundApp";
  static const String playAudio = "playAudio";
  static const String stopAudio = "stopAudio";
  static const String speak = "speak";
  static const String stopSpeaking = "stopSpeaking";
  static const String isSpeaking = "isSpeaking";

  // Events
  static const String eventForegroundAppChanged = "foregroundAppChanged";
  static const String eventAppBlocked = "appBlocked";
  static const String eventLimitWarning = "limitWarning";
}
