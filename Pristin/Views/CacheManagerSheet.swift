//
//  Copyright (c) 2026 Stefan Werner. All rights reserved.
//
//  This software is provided for PERSONAL, NON-COMMERCIAL USE ONLY.
//  No redistribution, forks, or derivative works are permitted.
//
//  See the LICENSE file in the root directory of this repository
//  for the full terms and conditions.
//

import SwiftUI

struct CacheManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let apps: [SystemApp]
    
    @State private var sheetSearchString = ""
    @State private var showBulkDeleteConfirmation = false
    
    @State private var failedPaths: [String] = []
    @State private var showFailureAlert = false
    
    var allCachePaths: [(appName: String, path: String)] {
        var caches: [(appName: String, path: String)] = []
        for app in apps {
            for path in app.paths {
                let isCache = path.contains("/Caches/") || path.lowercased().contains("cache")
                if isCache {
                    caches.append((appName: app.name, path: path))
                }
            }
        }
        
        if !sheetSearchString.isEmpty {
            caches = caches.filter {
                $0.path.localizedCaseInsensitiveContains(sheetSearchString) ||
                $0.appName.localizedCaseInsensitiveContains(sheetSearchString)
            }
        }
        
        return caches.sorted { $0.appName < $1.appName }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Cache Clearer")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Review all localized cache layers before permanent removal.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                TextField("Search paths...", text: $sheetSearchString)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .controlSize(.large)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            List(allCachePaths, id: \.path) { item in
                HStack(spacing: 12) {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.path)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text("Belongs to: \(item.appName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            
            Divider()
            
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(role: .destructive) {
                    showBulkDeleteConfirmation = true
                } label: {
                    Label("Trash All Caches (\(allCachePaths.count))", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .disabled(allCachePaths.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 650, minHeight: 450)
        .confirmationDialog(
            "Are you sure you want to move all found caches to the Trash?",
            isPresented: $showBulkDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                moveCachesToTrash()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will move \(allCachePaths.count) cache directories to the Trash. Performance of some tools may temporarily degrade while rebuilding indexes.")
        }
        .alert(
            "Some caches could not be moved to the Trash",
            isPresented: $showFailureAlert,
            presenting: failedPaths
        ) { failed in
            Button("Reveal in Finder") {
                revealInFinder(paths: failed)
            }
            Button("OK", role: .cancel) {}
        } message: { failed in
            let limit = 5
            let displayedPaths = failed.prefix(limit).joined(separator: "\n")
            let moreText = failed.count > limit ? "\n... and \(failed.count - limit) more" : ""
            Text("Likely due to missing permissions, the following items failed:\n\n\(displayedPaths)\(moreText)")
        }
    }
        
    private func moveCachesToTrash() {
        var failures: [String] = []
        let fileManager = FileManager.default
        
        for item in allCachePaths {
            let url = URL(fileURLWithPath: item.path)
            guard fileManager.fileExists(atPath: item.path) else { continue }
            
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                failures.append(item.path)
                print("Failed to trash cache \(item.path): \(error.localizedDescription)")
            }
        }
        
        if !failures.isEmpty {
            self.failedPaths = failures
            self.showFailureAlert = true
        } else {
            dismiss()
        }
    }
    
    private func revealInFinder(paths: [String]) {
        let urls = paths.map { URL(fileURLWithPath: $0) }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
}
