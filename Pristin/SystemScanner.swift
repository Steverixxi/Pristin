//
//  SystemScanner.swift
//  Pristin
//

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
            "Node.js": ["node", "npm", "npx", ".npm", ".nvm", "nvm", "nodemon", "pm2", "corepack"],
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
            "Unity 3D": ["unity", "unityhub", "plastic4"],
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
            "Mozilla Firefox": ["mozilla", "firefox"],
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
            "/Library/PrivilegedHelperTools"
        ]
        
        let userLibraryLocations = [
            homeDir + "/.config",
            homeDir + "/Library/Application Support",
            homeDir + "/Library/Caches",
            homeDir + "/Library/Logs"
        ]
        
        let fileManager = FileManager.default
        var rawItemsToCluster: [String] = []

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
            "CFUserTextEncoding", "ControlCenter", "FileProvider", "CallHistoryDB", "CallHistoryTransactions", "AppAnalytics", "icloudmailagent"
        ]

        func isBlacklisted(_ name: String) -> Bool {
            let lowerName = name.lowercased()
            return systemBlacklist.contains {
                let blackWord = $0.lowercased()
                return lowerName == blackWord || lowerName.hasPrefix("\(blackWord).") || lowerName.hasPrefix("\(blackWord)_")
            }
        }

        for location in unixLocations {
            guard let items = try? fileManager.contentsOfDirectory(atPath: location) else { continue }
            for item in items {
                if isBlacklisted(item) { continue }
                if item.hasPrefix(".") && !item.hasPrefix(".config") { continue }
                
                let fullPath = "\(location)/\(item)"
                
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                if !isDir.boolValue && isAppleSigned(path: fullPath) {
                    continue
                }
                
                if !rawItemsToCluster.contains(item) {
                    rawItemsToCluster.append(item)
                }
            }
        }

        for location in userLibraryLocations {
            guard let items = try? fileManager.contentsOfDirectory(atPath: location) else { continue }
            for item in items {
                if isBlacklisted(item) { continue }
                if !rawItemsToCluster.contains(item) {
                    rawItemsToCluster.append(item)
                }
            }
        }
        
        if let homeItems = try? fileManager.contentsOfDirectory(atPath: homeDir) {
            for item in homeItems {
                if item.hasPrefix(".") {
                    let cleanDot = item.replacingOccurrences(of: ".", with: "")
                    if isBlacklisted(cleanDot) { continue }
                    if cleanDot.count >= 3 && !rawItemsToCluster.contains(item) {
                        rawItemsToCluster.append(item)
                    }
                }
            }
        }

        let allLocations = unixLocations + userLibraryLocations + [homeDir]

        for targetName in rawItemsToCluster {
            let cleanName = targetName.replacingOccurrences(of: ".", with: "")
                                      .replacingOccurrences(of: "com.", with: "")
                                      .components(separatedBy: ".").first ?? targetName
            
            if cleanName.count < 3 && !knownRules.keys.contains(cleanName) { continue }
            if isBlacklisted(cleanName) { continue }
            
            var matchedName: String? = nil
            let lowerClean = cleanName.lowercased()
            
            for (appName, keywords) in knownRules {
                if keywords.contains(where: { keyword in
                    let lowerKey = keyword.lowercased()
                    return lowerClean == lowerKey ||
                           lowerClean.hasPrefix("\(lowerKey)-") ||
                           lowerClean.hasPrefix("\(lowerKey)_")
                }) {
                    matchedName = appName
                    break
                }
            }
            
            let isKnown = (matchedName != nil)
            let finalName = matchedName ?? cleanName
            var associatedPaths: [String] = []
            
            for location in allLocations {
                guard let subItems = try? fileManager.contentsOfDirectory(atPath: location) else { continue }
                for subItem in subItems {
                    let lowerSub = subItem.lowercased()
                    let isExactMatch = lowerSub == lowerClean || lowerSub == ".\(lowerClean)"
                    let isBoundedMatch = lowerSub.hasPrefix("\(lowerClean)-") ||
                                         lowerSub.hasPrefix("\(lowerClean)_") ||
                                         lowerSub.hasPrefix(".\(lowerClean)-") ||
                                         lowerSub.hasPrefix(".\(lowerClean)_")
                    
                    if (isExactMatch || isBoundedMatch) && !isBlacklisted(lowerSub) {
                        let fullPath = "\(location)/\(subItem)"
                        if fullPath == homeDir { continue }
                        
                        if !associatedPaths.contains(fullPath) {
                            associatedPaths.append(fullPath)
                        }
                    }
                }
            }
            
            if !associatedPaths.isEmpty {
                if let existingIndex = detectedApps.values.firstIndex(where: { $0.name.lowercased() == finalName.lowercased() }) {
                    let id = detectedApps.values[existingIndex].id
                    if var existingApp = detectedApps[id] {
                        existingApp.paths = Array(Set(existingApp.paths + associatedPaths))
                        detectedApps[id] = existingApp
                    }
                } else {
                    let app = SystemApp(name: finalName, isKnown: isKnown, paths: associatedPaths)
                    detectedApps[app.id] = app
                }
            }
        }
        
        // --- LaunchDaemon / Agent Analysis ---
        let launchFolders = ["/Library/LaunchDaemons", "/Library/LaunchAgents", homeDir + "/Library/LaunchAgents"]
        for folder in launchFolders {
            guard let plists = try? fileManager.contentsOfDirectory(atPath: folder) else { continue }
            for plist in plists {
                if isBlacklisted(plist) { continue }
                
                let fullPlistPath = "\(folder)/\(plist)"
                if let plistData = fileManager.contents(atPath: fullPlistPath),
                   let dict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                    
                    let binaryPath = (dict["Program"] as? String) ?? (dict["ProgramArguments"] as? [String])?.first
                    
                    if let binaryPath = binaryPath {
                        if isAppleSigned(path: binaryPath) {
                            continue
                        }
                        
                        var serviceName = plist.replacingOccurrences(of: ".plist", with: "")
                        let nameComponents = serviceName.components(separatedBy: ".")
                        if nameComponents.count > 2 {
                            serviceName = nameComponents[1]
                        }
                        
                        for (appName, keywords) in knownRules {
                            if keywords.contains(serviceName.lowercased()) {
                                serviceName = appName
                                break
                            }
                        }
                        
                        let paths = [fullPlistPath, binaryPath]
                        
                        if let existingIndex = detectedApps.values.firstIndex(where: { $0.name.lowercased() == serviceName.lowercased() }) {
                            let id = detectedApps.values[existingIndex].id
                            if var existingApp = detectedApps[id] {
                                existingApp.paths = Array(Set(existingApp.paths + paths))
                                detectedApps[id] = existingApp
                            }
                        } else {
                            let isKnown = knownRules.keys.contains(serviceName)
                            let app = SystemApp(name: serviceName, isKnown: isKnown, paths: paths)
                            detectedApps[app.id] = app
                        }
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
