//
//  SystemScanner.swift
//  Pristin
//
//  Created by Stefan on 29.06.26.
//

import Foundation

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
    
    // Example function for nodejs / PLACEHOLDER
    static func checkNodeVersion() -> String {
        let commonPaths = ["/usr/local/bin/node", "/opt/homebrew/bin/node"]
        
        let fileManager = FileManager.default
        
        for path in commonPaths {
            if fileManager.fileExists(atPath: path) {
                let version = runShellCommand(executablePath: path, arguments: ["--version"])
                return "Node.js found under \(path):\nVersion: \(version)"
            }
        }
        
        return "Node.js was not found"
    }
}
