import Foundation

public enum StarOracleDebug {
  public static let verboseLogsKey = "staro.debug.verboseLogs"

  public static var verboseLogsEnabled: Bool {
#if DEBUG
    return UserDefaults.standard.bool(forKey: verboseLogsKey)
#else
    return false
#endif
  }

  public static func setVerboseLogsEnabled(_ enabled: Bool) {
#if DEBUG
    UserDefaults.standard.set(enabled, forKey: verboseLogsKey)
#else
    _ = enabled
#endif
  }
}

