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

struct DetailView: View {
    let app: SystemApp
    @State private var showDeleteConfirmation = false
    
    @State private var failedPaths: [String] = []
    @State private var showFailureAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(app.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(app.paths.count) associated files found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            List(app.paths, id: \.self) { path in
                let isCache = path.contains("/Caches/") || path.lowercased().contains("cache")
                
                HStack {
                    Image(systemName: isCache ? "archivebox" : "doc")
                        .foregroundStyle(isCache ? .orange : .secondary)
                        .frame(width: 20)
                    
                    Text(path)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .padding(.vertical, 2)
                .contextMenu {
                    Button("Show in Finder") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                    }
                    Button("Copy Path") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(path, forType: .string)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .confirmationDialog(
            "Do you want to move all files for '\(app.name)' to the Trash?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                moveToTrash()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Files will be moved to the Trash. System daemons might require a restart afterwards.")
        }
        .alert(
            "Some files could not be moved to the Trash",
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
            Text("Likely due to missing permissions, the following files failed:\n\n\(displayedPaths)\(moreText)")
        }
    }
    
    
    private func moveToTrash() {
        var failures: [String] = []
        let fileManager = FileManager.default
        
        for path in app.paths {
            let url = URL(fileURLWithPath: path)
            guard fileManager.fileExists(atPath: path) else { continue }
            
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                failures.append(path)
                print("Failed to trash \(path): \(error.localizedDescription)")
            }
        }
        
        if !failures.isEmpty {
            self.failedPaths = failures
            self.showFailureAlert = true
        } else {
           // if ok
        }
    }
    
    private func revealInFinder(paths: [String]) {
        let urls = paths.map { URL(fileURLWithPath: $0) }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
}
