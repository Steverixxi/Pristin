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

struct ContentView: View {
    @State private var apps: [SystemApp] = []
    @State private var selectedApp: SystemApp?
    @State private var isScanning = false
    @State private var hasScanned = false
    
    @State private var hideCacheOnly = false
    @State private var searchString = ""
    
    @State private var showCacheManager = false
    
    var filteredApps: [SystemApp] {
        var result = apps
        
        if hideCacheOnly {
            result = result.filter { app in
                let isOnlyCache = app.paths.allSatisfy { path in
                    path.contains("/Caches/") || path.lowercased().contains("cache")
                }
                return !isOnlyCache
            }
        }
        
        if !searchString.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchString) }
        }
        
        return result
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredApps, selection: $selectedApp) { app in
                NavigationLink(value: app) {
                    HStack(spacing: 12) {
                        Image(systemName: app.isKnown ? "app.dashed" : "questionmark.folder")
                            .foregroundStyle(app.isKnown ? Color.accentColor : Color.secondary)
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.system(.body, weight: .medium))
                            Text(app.isKnown ? "Known Tool" : "Unknown")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Found Apps")
            .searchable(text: $searchString, placement: .sidebar, prompt: "Filter Apps")
            .listStyle(.sidebar)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Toggle(isOn: $hideCacheOnly) {
                            Label("Hide Cache-Only Apps", systemImage: "archivebox")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .symbolVariant(hideCacheOnly ? .fill : .none)
                    }
                    .help("Filter View")
                }
            }
        } detail: {
            Group {
                if isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Analyzing system...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !hasScanned {
                    WelcomeScreen(startScan: startSystemScan)
                } else if let app = selectedApp {
                    DetailView(app: app)
                } else {
                    ContentUnavailableView(
                        "No App Selected",
                        systemImage: "macwindow.badge.exclamationmark",
                        description: Text("Select a program from the sidebar to inspect the scattered files.")
                    )
                }
            }
            .toolbar {
                if hasScanned {
                    ToolbarItem(placement: .navigation) {
                        Button(action: startSystemScan) {
                            Label("Scan Again", systemImage: "arrow.clockwise")
                        }
                        .help("Scan system again")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCacheManager = true
                    } label: {
                        Label("Purge Caches", systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasScanned || apps.isEmpty)
                    .help("Show all accumulated system caches")
                }
            }
        }
        .frame(minWidth: 850, minHeight: 550)
        .sheet(isPresented: $showCacheManager) {
            CacheManagerSheet(apps: apps)
        }
    }
    
    func startSystemScan() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isScanning = true
            selectedApp = nil
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let scannedApps = SystemScanner.scanComprehensiveSystem()
            
            DispatchQueue.main.async {
                self.apps = scannedApps
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isScanning = false
                    self.hasScanned = true
                    if let first = self.filteredApps.first {
                        self.selectedApp = first
                    }
                }
            }
        }
    }
}

struct DisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAccept: () -> Void
    
    @State private var hasAcceptedDisclaimer = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.title)
                    
                    Text("Liability Disclaimer & Terms")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Pristin operates directly within advanced macOS system layers and library pathways. Removing detected files can alter or break core system parameters, application dependencies, or background structures.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Responsibility:")
                        .font(.headline)
                    
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").fontWeight(.bold)
                        Text("You are strictly required to manually inspect and verify all reported paths and structures before executing a permanent removal.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").fontWeight(.bold)
                        Text("The developer assumes absolutely no liability for data loss, operational downtime, or system instability caused by using this software.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(12)
                .background(Color(NSColor.alternatingContentBackgroundColors[1]).opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Divider()
                    .padding(.vertical, 4)
                
                Toggle(isOn: $hasAcceptedDisclaimer) {
                    Text("I have reviewed the terms, verified the structural requirements, and explicitly agree to take full responsibility for all removal processes.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .toggleStyle(.checkbox)
            }
            .padding(24)
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                    onAccept()
                }) {
                    Text("Confirm & Proceed")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!hasAcceptedDisclaimer)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 540, height: 420)
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ContentView()
}
