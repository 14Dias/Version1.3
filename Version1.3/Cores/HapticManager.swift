import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Só executa se NÃO for o simulador
        #if !targetEnvironment(simulator)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        // Só executa se NÃO for o simulador
        #if !targetEnvironment(simulator)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
}
