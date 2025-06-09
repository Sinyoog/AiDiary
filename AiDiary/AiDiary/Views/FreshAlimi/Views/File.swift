import SwiftUI

struct AddIngredientView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: IngredientViewModel

    @State private var name = ""
    @State private var expirationDate = Date()
    @State private var storageType: StorageType = .fridge

    var body: some View {
        
        Form {
            TextField("이름", text: $name)
            DatePicker("유통기한", selection: $expirationDate, displayedComponents: .date)
            Picker("보관 장소", selection: $storageType) {
                ForEach(StorageType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                }
            }
            Button("추가") {
                let newItem = Ingredient(id: UUID(), name: name, expirationDate: expirationDate, storageType: storageType)
                viewModel.addIngredient(newItem)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle("식재료 추가")
    }
}

