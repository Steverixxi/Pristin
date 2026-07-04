//
//  CacheManager.swift
//  Pristin
//
//  Created by Stefan on 05.07.26.
//

import SwiftUI

struct CacheManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let apps: [SystemApp]
    
    @State private var sheetSearchString = ""
    @State private var showBulkDeleteConfirmation = false
    
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
                            .textSelection(.enabled)
                        
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
                    Label("Delete All Caches (\(allCachePaths.count))", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .disabled(allCachePaths.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 650, minHeight: 450)
        .confirmationDialog(
            "Are you sure you want to delete all found caches?",
            isPresented: $showBulkDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear \(allCachePaths.count) cache directories. Performance of some tools may temporarily degrade while rebuilding indexes.")
        }
    }
}
