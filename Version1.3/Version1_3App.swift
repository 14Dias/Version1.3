import SwiftUI
import FirebaseCore

@main
struct TrainarApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        
        // Configuração global de aparência da NavigationBar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(TrainarTheme.brandPrimary)]
        appearance.titleTextAttributes = [.foregroundColor: UIColor(TrainarTheme.brandPrimary)]
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light) // Ou deixe o sistema decidir
        }
    }
}
