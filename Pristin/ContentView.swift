import SwiftUI

struct ContentView: View {
    @State private var apps: [SystemApp] = []
    @State private var selectedApp: SystemApp?
    @State private var isScanning = false
    @State private var hasScanned = false
    
    @State private var hideCacheOnly = false
    @State private var searchString = ""
    
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
            .searchable(text: $searchString, prompt: "Filter Apps")
            .listStyle(.sidebar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
            }
        }
        .frame(minWidth: 850, minHeight: 550)
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

struct WelcomeScreen: View {
    var startScan: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles.tv")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Pristin")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                
                Text("Clean the system thoroughly to theoretically restore a macOS with only App Store Sandboxes. Completely track down orphaned files, caches, and daemons.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }
            
            Button(action: startScan) {
                Text("Analyze System")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.top, 16)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.underPageBackgroundColor).opacity(0.3))
    }
}

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
                        .textSelection(.enabled)
                    
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
            Button("Delete Permanently", role: .destructive) {
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. System daemons might require a restart afterwards.")
        }
    }
}

#Preview {
    ContentView()
}
