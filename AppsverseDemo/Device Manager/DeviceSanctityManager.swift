//
//  DeviceSanctityManager.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 6/12/20.
//

import Foundation
import UIKit

let privateTextFile = "/private/jailbreak.txt"

protocol DeviceSanctityType {
    var isDevice: Bool { get }
    func isMaliciousDevice() -> Bool
}

class DeviceSanctityManager: DeviceSanctityType {
    var isDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    func isMaliciousDevice() -> Bool {
        if self.isDevice {
            let isMalicious = self.canViolatePaths() ||
                self.canViolateSchemes() ||
                self.canViolateSandbox()
            return isMalicious
        } else {
            return false
        }
    }

    private func pathsToCheck() -> [String] {
        return [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/usr/sbin/frida-server",
            "/usr/bin/cycript",
            "/usr/local/bin/cycript",
            "/usr/lib/libcycript.dylib",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Applications/blackra1n.app",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/bin/sh",
            "/etc/ssh/sshd_config",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/usr/bin/sshd",
            "/usr/libexec/sftp-server",
            "/usr/libexec/ssh-keysign",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia"
        ]
    }

    private func schemesToCheck() -> [String] {
        return [ "cydia://package/com.example.package" ]
    }

    //Check root files and cydia app file exists.
    func canViolatePaths() -> Bool {
        var existsPath = false
        for path in self.pathsToCheck() {
            if FileManager.default.fileExists(atPath: path) {
                existsPath = true
                break
            }
        }
        return existsPath
    }

    //Check can open third party malicious app named Cydia.
    func canViolateSchemes() -> Bool {
        var canOpenScheme = false
        for scheme in self.schemesToCheck() {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                canOpenScheme = true
                break
            }
        }
        return canOpenScheme
    }

    //Checking can access out of sandbox files.
    func canViolateSandbox() -> Bool {
        var grantsToWrite = false
        let stringToBeWritten = "This is an anti-spoofing test."
        do {
            try stringToBeWritten.write(toFile: privateTextFile,
                                        atomically: true,
                                        encoding: String.Encoding.utf8)
            grantsToWrite  = true
        } catch {
            grantsToWrite = false
        }
        return grantsToWrite
    }
}
