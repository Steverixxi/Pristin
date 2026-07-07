//
//  DetailView.swift
//  Pristin
//
//  Created by Stefan on 05.07.26.
//

import SwiftUI

struct DetailView: View {
    let app: SystemApp
    @State private var showDeleteConfirmation = false
    
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
                    Label("Remove All", systemImage: "trash")
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
            "Do you want to permanently delete all files for '\(app.name)'?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {}
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. System daemons might require a restart afterwards.")
        }
    }
}
