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

struct WelcomeScreen: View {
    var startScan: () -> Void
    
    @AppStorage("hasSeenWelcomeScreen") private var hasSeenWelcomeScreen = false
    @State private var doNotShowAgain = false
    @State private var showDisclaimerSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 32) {
                    
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles.tv")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Welcome to Pristin")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .tracking(0.5)
                        
                        Text("Thoroughly analyze and clean your system with confidence.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        FeatureRow(
                            icon: "shield.checkerboard",
                            color: .blue,
                            title: "Sandbox Tracking",
                            description: "Identifies orphaned files and directories left outside official App Store sandboxes."
                        )
                        
                        FeatureRow(
                            icon: "archivebox",
                            color: .orange,
                            title: "Localized Cache Layers",
                            description: "Tracks down deeply buried cache structures and accumulated temporary junk files."
                        )
                        
                        FeatureRow(
                            icon: "terminal",
                            color: .purple,
                            title: "Daemon & Launch Detection",
                            description: "Exposes lingering background services and operational fragments of uninstalled apps."
                        )
                    }
                    .frame(maxWidth: 460)
                }
                .padding(32)
            }
            
            Divider()
            
            HStack {
                Toggle("Do not show this welcome screen again", isOn: $doNotShowAgain)
                    .toggleStyle(.checkbox)
                    .controlSize(.regular)
                
                Spacer()
                
                Button(action: {
                    showDisclaimerSheet = true
                }) {
                    HStack {
                        Text("Analyze System")
                        Image(systemName: "chevron.right")
                    }
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.underPageBackgroundColor))
        .onAppear {
            if hasSeenWelcomeScreen {
                doNotShowAgain = true
            }
        }
        .sheet(isPresented: $showDisclaimerSheet) {
            DisclaimerSheet(onAccept: {
                if doNotShowAgain {
                    hasSeenWelcomeScreen = true
                }
                startScan()
            })
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
                    }
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").fontWeight(.bold)
                        Text("The developer assumes absolutely no liability for data loss, operational downtime, or system instability caused by using this software.")
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
            Button("Delete Permanently", role: .destructive) {}
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. System daemons might require a restart afterwards.")
        }
    }
}

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

#Preview {
    ContentView()
}
