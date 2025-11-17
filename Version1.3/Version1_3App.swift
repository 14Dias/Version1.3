// Version1_3App.swift
import SwiftUI
import FirebaseCore

@main
struct Version1_3App: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        print("🟢 Firebase configurado")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
