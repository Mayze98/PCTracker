//
//  EditMiscExpenseView.swift
//  PCTracker
//
//  Created by John on 2026-03-08.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditMiscExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "CAD"
    
    let expense: MiscExpense
    
    @State private var itemDescription: String
    @State private var cost: String
    @State private var purchaseDate: Date
    @State private var notes: String
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var showingLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(expense: MiscExpense) {
        self.expense = expense
        let displayCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "CAD"
        _itemDescription = State(initialValue: expense.itemDescription)
        _cost = State(initialValue: String(format: "%.2f", CurrencyFormatter.displayAmount(expense.cost, displayCode: displayCode)))
        _purchaseDate = State(initialValue: expense.purchaseDate)
        _notes = State(initialValue: expense.notes ?? "")
        _photoData = State(initialValue: expense.photoData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Description")
                            .foregroundColor(.themePrimaryText)
                        Spacer()
                        TextField("", text: $itemDescription)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                    .listRowBackground(Color.themeRowBackground)
                    
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text(CurrencyFormatter.symbol(for: currencyCode))
                            .foregroundColor(.themeSecondaryText)
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Expense Information")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                        .environment(\.colorScheme, .dark)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Purchase Date")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .listRowBackground(Color.themeRowBackground)
                } header: {
                    Text("Notes")
                        .textCase(nil)
                        .foregroundColor(.themeSecondaryText)
                }
                .autocorrectionDisabled()
                .autocapitalization(.none)
                
                PhotoPickerSection(photoData: $photoData, onLibraryRequested: { showingLibraryPicker = true }, onCameraRequested: { showingCamera = true })
            }
            .foregroundColor(.themePrimaryText)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.themeGold)
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
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { data in photoData = data }
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showingLibraryPicker, selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data), let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                            await MainActor.run { photoData = compressed }
                        } else {
                            await MainActor.run { photoData = data }
                        }
                    }
                    await MainActor.run { selectedPhotoItem = nil }
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let costValue = Double(cost) else { return }
        
        expense.itemDescription = itemDescription
        expense.cost = CurrencyFormatter.toStorageAmount(costValue, fromCode: currencyCode)
        expense.purchaseDate = purchaseDate
        expense.notes = notes.isEmpty ? nil : notes
        expense.photoData = photoData
        
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Error saving expense: \(error)")
            #endif
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: MiscExpense.self, configurations: config) else {
        fatalError("Preview ModelContainer failed to initialize")
    }
    
    let sampleExpense = MiscExpense(itemDescription: "Shipping Supplies", cost: 25.00, notes: "Boxes and bubble wrap")
    container.mainContext.insert(sampleExpense)
    
    return EditMiscExpenseView(expense: sampleExpense)
        .modelContainer(container)
}
