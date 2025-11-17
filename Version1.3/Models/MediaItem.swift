// Models/MediaItem.swift
import Foundation

struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let duration: String
    let thumbnail: String
    let category: String
    
    // Para evitar ter que passar category sempre
    init(title: String, duration: String, thumbnail: String, category: String = "Geral") {
        self.title = title
        self.duration = duration
        self.thumbnail = thumbnail
        self.category = category
    }
}
