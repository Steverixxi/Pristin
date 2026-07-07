import Foundation
import Security

class SystemScanner {

    static func runShellCommand(executablePath: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return "Error while executing: \(error.localizedDescription)"
        }

        return "No output received."
    }

    static func isAppleSigned(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        var staticCode: SecStaticCode?

        guard SecStaticCodeCreateWithPath(url as CFURL, SecCSFlags(rawValue: 0), &staticCode) == errSecSuccess,
              let code = staticCode else {
            return false
        }

        var requirement: SecRequirement?
        guard SecRequirementCreateWithString("anchor apple" as CFString, SecCSFlags(rawValue: 0), &requirement) == errSecSuccess,
              let req = requirement else {
            return false
        }

        let status = SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures), req)
        return status == errSecSuccess
    }

    static func scanComprehensiveSystem() -> [SystemApp] {
        var detectedApps: [UUID: SystemApp] = [:]

        let knownRules = [
            "Node.js": ["node", "npm", "npx", ".npm", ".nvm", "nvm", "nodemon", "pm2", "corepack", "node_modules"],
            "DNET Core / .NET": ["dotnet", ".dotnet", "nuget", ".nuget", "msbuild", "aspnet"],
            "Python": ["python", "python3", "pip", "pip3", "conda", "miniconda", "anaconda", ".virtualenvs", ".pyenv", "pyenv", "poetry", "jupyter", ".jupyter"],
            "Ruby": ["ruby", "gem", "bundle", "bundler", ".rvm", ".rbenv", "rbenv", ".gem", "rake", "irb"],
            "Rust": ["rustc", "cargo", "rustup", ".rustup", ".cargo", "rustfmt", "clippy"],
            "Go / Golang": ["go", "gofmt", ".go", "golang", "godoc"],
            "Java / JDK": ["java", "javac", "jdk", "jre", ".java", "javaws", "jar"],
            "PHP": ["php", "php-fpm", "phpize", "phpunit", ".php"],
            "Perl": ["perl", "cpan", ".cpan", "cpanm"],
            "Swift": ["swift", "swiftc", "swiftpm", ".swiftpm"],
            "C/C++": ["gcc", "g++", "clang", "clang++", "cmake", "make", "gdb", "lldb"],
            "Mono": ["mono", "monodis", "mcs", ".mono"],

            "Visual Studio Code": ["vscode", "code", "vscode-shared", "csdevkit", "copilot"],
            "Unity 3D": ["unity", "unityhub", "plastic4", "unityhub-updater"],
            "Xcode & Apple Dev": ["xcode", "coresimulator", "proapps", "script editor"],

            "Homebrew": ["brew", "Cellar", "Caskroom", "homebrew"],
            "CocoaPods": ["pod", "pods", ".cocoapods"],
            "Yarn": ["yarn", ".yarn", ".yarnrc", "yarnpkg"],
            "pnpm": ["pnpm", ".pnpm-store"],
            "Composer (PHP)": ["composer", ".composer"],
            "Maven (Java)": ["mvn", "maven", ".m2"],
            "Gradle (Java)": ["gradle", ".gradle", "gradlew"],

            "PostgreSQL": ["postgres", "postgresql", "psql", "pg_ctl", "initdb", ".psql_history"],
            "MySQL / MariaDB": ["mysql", "mysqld", "mariadb", "mysqladmin", ".mysql_history"],
            "MongoDB": ["mongo", "mongod", "mongos", "mongosh", ".mongodb"],
            "Redis": ["redis-server", "redis-cli", "redis"],
            "SQLite": ["sqlite", "sqlite3"],
            "Docker": ["docker", "docker-compose", ".docker", "com.docker.docker", "docker-credential"],
            "AWS CLI": ["aws", ".aws", "aws-cli", "eb", "sam"],
            "Google Cloud SDK": ["gcloud", "gsutil", "bq", ".config/gcloud"],

            "Git": ["git", ".gitconfig", ".git-credentials", "git-lfs", ".gitk"],
            "GitHub CLI": ["gh", ".config/gh"],

            "DisplayLink": ["displaylink", "displaylinkmanager", "displaylinkuseragent"],
            "Google Chrome / Services": ["google", "chrome", "keystone"],
            "Mozilla": ["mozilla", "firefox"],
            "Discord": ["discord", "discordptb", "discordcanary"],
            "Spotify": ["spotify", "spotifyd"],
            "AlDente": ["aldente", "aldentepro", "apphousekitchen"],
            "Stripe CLI": ["stripe"],
            "Gemini (Cache/Config)": ["gemini"],
            "cURL": ["curl", ".curlrc"],
            "Wget": ["wget", ".wget-hsts"],
            "GnuPG": ["gpg", "gpg-agent", ".gnupg", "gpg2"],
            "SSH": ["ssh", "sshd", ".ssh", "ssh-keygen", "ssh-agent"],
            "Zsh / Bash": ["zsh", "bash", ".zshrc", ".bash_profile", ".bashrc", ".zprofile", "zplug", "oh-my-zsh"]
        ]

        let homeDir = NSHomeDirectory()

        let unixLocations = [
            "/usr/local/bin", "/usr/local/lib", "/usr/local/include", "/usr/local/share", "/usr/local/etc",
            "/opt/homebrew/bin", "/opt/homebrew/lib", "/opt/homebrew/etc", "/opt/homebrew/share", "/opt/homebrew/var",
            "/Library/PrivilegedHelperTools",
            "/Library/Application Support",
            "/Library/Caches",
            "/Library/Logs",
            "/Library/Extensions",
            "/Library/Audio/Plug-Ins",
            "/Library/Internet Plug-Ins",
            "/Library/PreferencePanes",
            "/Library/LaunchAgents",
            "/Library/LaunchDaemons",
            "/private/var/db/receipts"
        ]

        var userLibraryLocations = [
            homeDir + "/.config",
            homeDir + "/.local",
            homeDir + "/.local/bin",
            homeDir + "/Library/Application Support",
            homeDir + "/Library/Caches",
            homeDir + "/Library/Logs",
            homeDir + "/Library/Preferences",
            homeDir + "/Library/Containers",
            homeDir + "/Library/Group Containers",
            homeDir + "/Library/WebKit",
            homeDir + "/Library/Saved Application State",
            homeDir + "/Library/HTTPStorages",
            homeDir + "/Library/Application Support/CrashReporter",
            homeDir + "/Library/Application Scripts",
            homeDir + "/Library/Autosave Information",
            homeDir + "/Library/Cookies",
            homeDir + "/Library/Daemon Containers",
            homeDir + "/Library/PreferencePanes",
            homeDir + "/Library/LaunchAgents",
            "/Library/Preferences",
            "/Library/Managed Preferences"
        ]

        let appBundleRoots = [
            "/Applications",
            homeDir + "/Applications"
        ]

        let fileManager = FileManager.default
        var rawItemsToCluster: [String] = []
        
        // add dynamic temp path if available
        let tempDir = NSTemporaryDirectory()
        let varCacheDir = URL(fileURLWithPath: tempDir).deletingLastPathComponent().deletingLastPathComponent().path
        if fileManager.fileExists(atPath: varCacheDir) {
            userLibraryLocations.append(varCacheDir)
        }

        let systemBlacklist = [
            "com.apple.", "System", "Managed Preferences", "Preferences", "Keychain",
            "Fonts", "Metadata", "Mobile Documents", "AddressBook", "AppStore", "Spotlight",
            "iCloud", "QuickLook", "Containers", "Group Containers", "CloudDocs",
            "DiagnosticReports", "CrashReporter", "CloudKit", "FaceTime", "App Store",
            "Desktop", "Documents", "Downloads", "Library", "Public", "Movies",
            "Pictures", "Creative Cloud Files", "Applications", "Siri", "Animoji",
            "DS_Store", "Trash", "Biome", "CoreMachineLearning", "DuetExpertCenter",
            "Passes", "Photos", "Safari", "Suggestions", "Weather", "Widget", "VoiceTrigger", "TCC",
            "doc", "man", "local", "shared", "info", "libexec", "tipsd", "contactsd",
            "CFUserTextEncoding", "ControlCenter", "FileProvider", "CallHistoryDB", "CallHistoryTransactions", "AppAnalytics", "icloudmailagent",
            "SiriTTSService", "identityservicesd", "GameKit", "FamilyCircle", "familycircled", "DiskImages", "askpermissiond", "MobileSync",
            "appplaceholdersyncd",
            "ARFileCache",
            "Assistant",
            "Baseband",
            "DifferentialPrivacy",
            "features_config",
            "GeoServices",
            "homeenergyd",
            "icdd",
            "iPad Updater Logs",
            "JetPackCache",
            "Knowledge",
            "locationaccessstored",
            "LSMImageCache",
            "mbuseragent",
            "networkserviceproxy",
            "PassKit",
            "PrivacyPreservingMeasurement",
            "SharedImageCache",
            "SyncServices",
            "TrickPlay",
            "tvapp_bag",
            "WindowServer",
            "ColorSync",
            "BTServer",
            "Xsan",
            "livefsd",
            "hidfw-crashlogs",
            "iLifeMediaBrowser",
            "Desktop Pictures",
            "Apple",
            "loginwindow.plist",
            "loginwindow", "ByHost", "Desktop Pictures", "Preferences",
            "com.apple", "CloudStorage", "Mobile Documents",
            "QuickLook", "Saved Application State", "WebKit", "HTTPStorages",
            "ScreenSharing", "Bluetooth", "Audio", "Input Methods", "Keychains",
            "LanguageModeling", "PersonalizationPortrait", "Metadata",
            "Spelling", "TCC", "Autosave Information"
        ]

        func isBlacklisted(_ name: String) -> Bool {
            let lowerName = name.lowercased()
            return systemBlacklist.contains {
                let blackWord = $0.lowercased()
                return lowerName == blackWord || lowerName.hasPrefix("\(blackWord).") || lowerName.hasPrefix("\(blackWord)_")
            }
        }

        func extractCoreName(from string: String) -> String {
            let lower = string.lowercased()
            let prefixes = ["com.", "org.", "net.", "io.", "co.", "uk.co."]
            for prefix in prefixes {
                if lower.hasPrefix(prefix) {
                    let stripped = String(lower.dropFirst(prefix.count))
                    return stripped.components(separatedBy: ".").first ?? stripped
                }
            }
            return lower.components(separatedBy: ".").first ?? lower
        }

        let structuralFolders = ["bin", "share", "lib", "libexec"]

        // Hilfsfunktion, um Code-Doppelung zu vermeiden
        func addItemOrResolveStructural(_ item: String, in location: String) {
            if isBlacklisted(item) { return }
            
            if structuralFolders.contains(item.lowercased()) {
                let subLocation = "\(location)/\(item)"
                if let subItems = try? fileManager.contentsOfDirectory(atPath: subLocation) {
                    for subItem in subItems {
                        if !isBlacklisted(subItem) && !rawItemsToCluster.contains(subItem) {
                            rawItemsToCluster.append(subItem)
                        }
                    }
                }
            } else {
                if !rawItemsToCluster.contains(item) {
                    rawItemsToCluster.append(item)
                }
            }
        }

        for location in unixLocations {
            guard let items = try? fileManager.contentsOfDirectory(atPath: location) else { continue }
            for item in items {
                if item.hasPrefix(".") && !item.hasPrefix(".config") { continue }
                
                let fullPath = "\(location)/\(item)"
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                if !isDir.boolValue && isAppleSigned(path: fullPath) { continue }
                
                addItemOrResolveStructural(item, in: location)
            }
        }

        for location in userLibraryLocations {
            guard let items = try? fileManager.contentsOfDirectory(atPath: location) else { continue }
            for item in items {
                addItemOrResolveStructural(item, in: location)
            }
        }

        if let homeItems = try? fileManager.contentsOfDirectory(atPath: homeDir) {
            for item in homeItems {
                if item.hasPrefix(".") {
                    let cleanDot = item.replacingOccurrences(of: ".", with: "")
                    if isBlacklisted(cleanDot) { continue }
                    if cleanDot.count >= 3 {
                        addItemOrResolveStructural(item, in: homeDir)
                    }
                } else {
                    addItemOrResolveStructural(item, in: homeDir)
                }
            }
        }

        let allLocations = unixLocations + userLibraryLocations + [homeDir]

        for targetName in rawItemsToCluster {
            if targetName.contains("com.apple") {
                continue;
            }
            let cleanName = extractCoreName(from: targetName)

            if cleanName.count < 3 && !knownRules.keys.contains(cleanName) { continue }
            if isBlacklisted(cleanName) { continue }

            var matchedName: String? = nil
            let lowerClean = cleanName

            let genericSegments = ["com", "org", "net", "io", "co", "uk"]
            let identifierSegments = targetName
                .lowercased()
                .components(separatedBy: ".")
                .filter { !genericSegments.contains($0) && $0.count >= 3 }

            outerMatch: for (appName, keywords) in knownRules {
                for segment in identifierSegments {
                    if keywords.contains(segment) {
                        matchedName = appName
                        break outerMatch
                    }
                }
            }

            if matchedName == nil {
                for (appName, keywords) in knownRules {
                    if keywords.contains(lowerClean) {
                        matchedName = appName
                        break
                    }
                }
            }

            let isKnown = (matchedName != nil)
            let finalName = matchedName ?? targetName
            var associatedPaths: [String] = []

            for location in allLocations {
                guard let subItems = try? fileManager.contentsOfDirectory(atPath: location) else { continue }
                for subItem in subItems {
                    if isBlacklisted(subItem) { continue }

                    let lowerSub = subItem.lowercased()
                    var isMatch = false

                    if let keywords = knownRules[matchedName ?? ""] {
                        for keyword in keywords {
                            let kw = keyword.lowercased()
                            if lowerSub == kw || lowerSub.hasPrefix("\(kw)-") || lowerSub.hasPrefix("com.\(kw)") || lowerSub.contains(".\(kw).") || lowerSub.hasPrefix(".\(kw)") || lowerSub.hasSuffix(".\(kw)") {
                                isMatch = true; break
                            }
                        }
                    } else {
                        if lowerSub == lowerClean || lowerSub.hasPrefix("\(lowerClean)-") || lowerSub.hasPrefix("com.\(lowerClean)") || lowerSub.contains(".\(lowerClean).") || lowerSub.hasPrefix(".\(lowerClean)") || lowerSub.hasSuffix(".\(lowerClean)") {
                            isMatch = true
                        }
                    }

                    if isMatch {
                        let fullPath = "\(location)/\(subItem)"
                        if fullPath == homeDir { continue }
                        if !associatedPaths.contains(fullPath) {
                            associatedPaths.append(fullPath)
                        }
                    }
                }
            }

            if !associatedPaths.isEmpty {
                if let existingIndex = detectedApps.values.firstIndex(where: {
                    let existingLower = $0.name.lowercased()
                    let finalLower = finalName.lowercased()
                    
                    return existingLower == finalLower ||
                           existingLower.hasPrefix(finalLower + ".") ||
                           finalLower.hasPrefix(existingLower + ".")
                }) {
                    let id = detectedApps.values[existingIndex].id
                    if var existingApp = detectedApps[id] {
                        if finalName.count < existingApp.name.count {
                            existingApp.name = finalName
                        }
                        existingApp.paths = Array(Set(existingApp.paths + associatedPaths))
                        detectedApps[id] = existingApp
                    }
                } else {
                    let app = SystemApp(name: finalName, isKnown: isKnown, paths: associatedPaths)
                    detectedApps[app.id] = app
                }
            }
        }

        func processPlist(atPath fullPlistPath: String, plistFileName: String) {
            if isBlacklisted(plistFileName) { return }

            guard let plistData = fileManager.contents(atPath: fullPlistPath),
                  let dict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
                return
            }

            let binaryPath = (dict["Program"] as? String) ?? (dict["ProgramArguments"] as? [String])?.first

            if let binaryPath = binaryPath, isAppleSigned(path: binaryPath) {
                return
            }

            let serviceNameLower = extractCoreName(from: plistFileName.replacingOccurrences(of: ".plist", with: ""))
            var finalServiceName = plistFileName.replacingOccurrences(of: ".plist", with: "")

            for (appName, keywords) in knownRules {
                if keywords.contains(serviceNameLower) {
                    finalServiceName = appName
                    break
                }
            }

            var paths = [fullPlistPath]
            if let bin = binaryPath { paths.append(bin) }

            if let existingIndex = detectedApps.values.firstIndex(where: { $0.name.lowercased() == finalServiceName.lowercased() }) {
                let id = detectedApps.values[existingIndex].id
                if var existingApp = detectedApps[id] {
                    existingApp.paths = Array(Set(existingApp.paths + paths))
                    detectedApps[id] = existingApp
                }
            } else {
                let isKnown = knownRules.keys.contains(serviceNameLower)
                let app = SystemApp(name: finalServiceName, isKnown: isKnown, paths: paths)
                detectedApps[app.id] = app
            }
        }

        let launchFolders = ["/Library/LaunchDaemons", "/Library/LaunchAgents", homeDir + "/Library/LaunchAgents"]
        for folder in launchFolders {
            guard let plists = try? fileManager.contentsOfDirectory(atPath: folder) else { continue }
            for plist in plists {
                processPlist(atPath: "\(folder)/\(plist)", plistFileName: plist)
            }
        }

        for appRoot in appBundleRoots {
            guard let apps = try? fileManager.contentsOfDirectory(atPath: appRoot) else { continue }
            for appBundle in apps {
                guard appBundle.hasSuffix(".app") else { continue }

                let bundleLaunchFolders = [
                    "\(appRoot)/\(appBundle)/Contents/Library/LaunchAgents",
                    "\(appRoot)/\(appBundle)/Contents/Library/LaunchDaemons"
                ]

                for folder in bundleLaunchFolders {
                    guard let plists = try? fileManager.contentsOfDirectory(atPath: folder) else { continue }
                    for plist in plists {
                        processPlist(atPath: "\(folder)/\(plist)", plistFileName: plist)
                    }
                }
            }
        }

        return detectedApps.values.sorted {
            if $0.isKnown && !$1.isKnown { return true }
            if !$0.isKnown && $1.isKnown { return false }
            return $0.name.lowercased() < $1.name.lowercased()
        }
    }
}
