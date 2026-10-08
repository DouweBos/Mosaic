// Models/Preferences.swift
// Mosaic
//
// User settings. Views bind through @AppStorage with these keys; services read the current values on use.

import Foundation

enum SettingKey {
    static let snapping = "snappingEnabled"
    static let gap = "windowGap"
    static let ignoredApps = "ignoredBundleIDs"
    static let followNewDisplays = "applyArrangementsAutomatically"
}

enum Preferences {
    static var defaults: UserDefaults = .standard

    static func registerDefaults() {
        defaults.register(defaults: [
            SettingKey.snapping: true,
            SettingKey.gap: 0.0,
            SettingKey.ignoredApps: [String](),
            SettingKey.followNewDisplays: true
        ])
    }

    static var snapping: Bool { defaults.bool(forKey: SettingKey.snapping) }
    static var gap: CGFloat { CGFloat(defaults.double(forKey: SettingKey.gap)) }
    static var followNewDisplays: Bool { defaults.bool(forKey: SettingKey.followNewDisplays) }

    static var ignoredApps: Set<String> {
        Set(defaults.stringArray(forKey: SettingKey.ignoredApps) ?? [])
    }

    static func setIgnored(_ bundleID: String, _ ignored: Bool) {
        var apps = ignoredApps
        if ignored { apps.insert(bundleID) } else { apps.remove(bundleID) }
        defaults.set(apps.sorted(), forKey: SettingKey.ignoredApps)
    }
}
