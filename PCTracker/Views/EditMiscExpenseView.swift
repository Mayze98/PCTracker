//
//  EditMiscExpenseView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData

struct EditMiscExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let expense: MiscExpense
    
    @State private var itemDescription: String
    @State private var cost: String
    @State private var purchaseDate: Date
    @State private var notes: String
    
    init(expense: MiscExpense) {
        self.expense = expense
        _itemDescription = State(initialValue: expense.itemDescription)
        _cost = State(initialValue: String(format: "%.2f", expense.cost))
        _purchaseDate = State(initialValue: expense.purchaseDate)
        _notes = State(initialValue: expense.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Information") {
                    TextField("Description", text: $itemDescription)
                    
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
                
                Section("Purchase Date") {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .bold()
                    .disabled(itemDescription.isEmpty || cost.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let costValue = Double(cost) else { return }
        
        expense.itemDescription = itemDescription
        expense.cost = costValue
        expense.purchaseDate = purchaseDate
        expense.notes = notes.isEmpty ? nil : notes
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving expense: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MiscExpense.self, configurations: config)
    
    let sampleExpense = MiscExpense(itemDescription: "Shipping Supplies", cost: 25.00, notes: "Boxes and bubble wrap")
    container.mainContext.insert(sampleExpense)
    
    return EditMiscExpenseView(expense: sampleExpense)
        .modelContainer(container)
}
