// Views/Components/LoadingStateView.swift - NOVO ARQUIVO
import SwiftUI

struct LoadingStateView: View {
    let message: String
    var showProgress: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
            }
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Isso pode levar alguns segundos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ShimmerLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Shimmer effect para cards
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 80)
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .white.opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black)
                                )
                        )
                }
            }
            .padding(.horizontal)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
