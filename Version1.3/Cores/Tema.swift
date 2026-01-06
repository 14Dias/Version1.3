import SwiftUI

struct TrainarTheme {

    static let brandPrimary = Color.blue
    static let brandSecondary = Color.purple
    static let background = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    

    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [brandPrimary, brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
  
    static func titleFont() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    static func bodyFont() -> Font {
        .system(size: 16, weight: .medium, design: .default)
    }
}
