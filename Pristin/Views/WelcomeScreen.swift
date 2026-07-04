import SwiftUI

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
