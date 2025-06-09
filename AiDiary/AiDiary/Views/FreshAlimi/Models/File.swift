import Foundation

struct Ingredient: Identifiable, Codable {
    let id: UUID
    var name: String
    var expirationDate: Date
    var storageType: StorageType
}

enum StorageType: String, Codable, CaseIterable {
    case fridge = "냉장"
    case freezer = "냉동"
    case room = "실온"
}

