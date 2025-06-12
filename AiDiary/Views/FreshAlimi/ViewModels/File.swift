import Foundation

class IngredientViewModel: ObservableObject {
    @Published var ingredients: [Ingredient] = []

    init() {
        loadData()
    }

    func addIngredient(_ ingredient: Ingredient) {
        ingredients.append(ingredient)
        saveData()
    }

    func removeIngredient(at indexSet: IndexSet) {
        ingredients.remove(atOffsets: indexSet)
        saveData()
    }

    func saveData() {
        if let encoded = try? JSONEncoder().encode(ingredients) {
            UserDefaults.standard.set(encoded, forKey: "ingredients")
        }
    }

    func loadData() {
        if let savedData = UserDefaults.standard.data(forKey: "ingredients"),
           let decoded = try? JSONDecoder().decode([Ingredient].self, from: savedData) {
            ingredients = decoded
        }
    }
}

