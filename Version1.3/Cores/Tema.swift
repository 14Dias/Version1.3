import SwiftUI

struct TrainarTheme {
    // Cores da Marca
    static let brandPrimary = Color.blue // Substitua pelo Hex da sua marca se tiver
    static let brandSecondary = Color.purple
    static let background = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    
    // Gradiente Principal
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [brandPrimary, brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // Tipografia
    static func titleFont() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    static func bodyFont() -> Font {
        .system(size: 16, weight: .medium, design: .default)
    }
}
