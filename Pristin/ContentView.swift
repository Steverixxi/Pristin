//
//  ContentView.swift
//  Pristin
//
//  Created by Stefan on 29.06.26.
//

import SwiftUI

struct ContentView: View {
    @State private var scanResult: String = "Click on Scan to start a System Scan."
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pristin")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView {
                Text(scanResult)
                    .font(.system(.body, design: .default))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
            }
            .frame(minHeight: 150)
            
            Button(action: {
                isScanning = true
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let result = SystemScanner.checkNodeVersion()
                    DispatchQueue.main.async {
                        self.scanResult = result
                        self.isScanning = false
                    }
                }
            }) {
                if isScanning {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Text("Scan System")
                        .padding(.horizontal, 10)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isScanning)
        }
        .padding()
        .frame(minWidth: 450, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
