import Foundation
import SwiftData

public struct CSVImporter {
    
    /// Errors that can occur during CSV import.
    public enum CSVImportError: Error, LocalizedError {
        case invalidHeader(expected: [String], found: [String])
        case invalidRow
        case unknownType(String)
        case missingRequiredField(String)
        case numberParseFailed(String)
        case dateParseFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case let .invalidHeader(expected, found):
                return "CSV header is invalid or missing required columns. Expected: \(expected.joined(separator: ", ")). Found: \(found.joined(separator: ", "))."
            case .invalidRow:
                return "A row in the CSV file is invalid or incomplete."
            case let .unknownType(type):
                return "Unknown type '\(type)' in CSV file."
            case let .missingRequiredField(field):
                return "Missing required field '\(field)'."
            case let .numberParseFailed(field):
                return "Failed to parse number from field '\(field)'."
            case let .dateParseFailed(field):
                return "Failed to parse date from field '\(field)'."
            }
        }
    }
    
    /// Parses CSV text into an array of rows, where each row is an array of fields.
    ///
    /// Handles quoted fields and commas within quotes.
    /// - Parameter text: The CSV text.
    /// - Returns: Parsed rows of fields.
    public static func parseCSV(_ text: String) -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        
        var insideQuotes = false
        var iterator = text.makeIterator()
        
        while let char = iterator.next() {
            switch char {
            case "\"":
                if insideQuotes {
                    // Peek next character to check for escaped quote
                    if let nextChar = iterator.next() {
                        if nextChar == "\"" {
                            // Escaped quote, add a quote to field
                            currentField.append("\"")
                        } else if nextChar == "," {
                            // End of quoted field, next field starts
                            insideQuotes = false
                            currentRow.append(currentField)
                            currentField = ""
                        } else if nextChar == "\n" || nextChar == "\r" {
                            // End of quoted field, end of row
                            insideQuotes = false
                            currentRow.append(currentField)
                            currentField = ""
                            result.append(currentRow)
                            currentRow = []
                            
                            // If \r\n, consume \n
                            if nextChar == "\r" {
                                if let lookahead = iterator.next(), lookahead != "\n" {
                                    // Put back if not \n (impossible here but just in case)
                                }
                            }
                        } else {
                            // Next char is something else, end quote and add next char to field
                            insideQuotes = false
                            currentRow.append(currentField)
                            currentField = ""
                            currentField.append(nextChar)
                        }
                    } else {
                        // Quote at end of file
                        insideQuotes = false
                        currentRow.append(currentField)
                        currentField = ""
                    }
                } else {
                    // Starting quote
                    insideQuotes = true
                }
            case ",":
                if insideQuotes {
                    currentField.append(char)
                } else {
                    currentRow.append(currentField)
                    currentField = ""
                }
            case "\n":
                if insideQuotes {
                    currentField.append(char)
                } else {
                    currentRow.append(currentField)
                    currentField = ""
                    result.append(currentRow)
                    currentRow = []
                }
            case "\r":
                if insideQuotes {
                    currentField.append(char)
                } else {
                    // Handle \r\n
                    currentRow.append(currentField)
                    currentField = ""
                    result.append(currentRow)
                    currentRow = []
                    // Check if next is \n and consume it
                    if let nextChar = iterator.next(), nextChar != "\n" {
                        // no-op (no put back)
                    }
                }
            default:
                currentField.append(char)
            }
        }
        
        // Append last field and row if any
        if !currentField.isEmpty || insideQuotes {
            currentRow.append(currentField)
        }
        if !currentRow.isEmpty {
            result.append(currentRow)
        }
        
        return result
    }
    
    /// Detects the currency code from a header column like "Buy Price (CAD)" or "Buy Price (USD)".
    /// Returns "CAD" if no currency code is found.
    private static func detectCurrency(from header: [String]) -> String {
        for col in header {
            if let match = col.range(of: "\\(([A-Z]{3})\\)", options: .regularExpression) {
                return String(col[match]).replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            }
        }
        return "CAD"
    }
    
    /// Converts an imported price to the storage currency (CAD).
    private static func toStorage(_ value: Double, fromCode: String) -> Double {
        return CurrencyFormatter.toStorageAmount(value, fromCode: fromCode)
    }
    
    /// Checks if a header matches the expected column names, ignoring currency suffixes like " (CAD)".
    private static func headerMatches(_ header: [String], expected: [String]) -> Bool {
        guard header.count == expected.count else { return false }
        for (h, e) in zip(header, expected) {
            // Strip currency suffix for comparison: "Buy Price (CAD)" -> "Buy Price"
            let stripped = h.replacingOccurrences(of: "\\s*\\([A-Z]{3}\\)", with: "", options: .regularExpression)
            if stripped != e { return false }
        }
        return true
    }
    
    /// Imports an Inventory CSV file into the given ModelContext.
    ///
    /// Supports both the new format with Card Set, Market Price, and currency codes:
    /// `Type,Name,Number,Card Set,Condition/Graded,Buy Price (CAD),Market Price (CAD),Purchase Date`
    ///
    /// And the legacy format:
    /// `Type,Name,Number,Condition/Graded,Buy Price,Purchase Date`
    ///
    /// - Parameters:
    ///   - url: The file URL of the CSV file to import.
    ///   - context: The ModelContext to insert the models into.
    /// - Throws: CSVImportError or other errors related to file reading or context saving.
    public static func importInventoryCSV(from url: URL, into context: ModelContext) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let rows = parseCSV(normalizedContent)
        guard !rows.isEmpty else { throw CSVImportError.invalidHeader(expected: ["Type", "Name", "Number", "Card Set", "Condition/Graded", "Buy Price", "Market Price", "Purchase Date"], found: []) }
        
        let header = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let newExpected = ["Type", "Name", "Number", "Card Set", "Condition/Graded", "Buy Price", "Market Price", "Purchase Date"]
        let legacyExpected = ["Type", "Name", "Number", "Condition/Graded", "Buy Price", "Purchase Date"]
        
        let isNewFormat = headerMatches(header, expected: newExpected)
        let isLegacyFormat = header == legacyExpected
        
        guard isNewFormat || isLegacyFormat else {
            throw CSVImportError.invalidHeader(expected: newExpected, found: header)
        }
        
        let importCurrency = isNewFormat ? detectCurrency(from: header) : "CAD"
        
        for idx in 1..<rows.count {
            let row = rows[idx]
            if row.isEmpty || row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }
            let fields = row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let type = fields[0].lowercased()
            
            if isNewFormat {
                guard fields.count >= newExpected.count else { throw CSVImportError.invalidRow }
                switch type {
                case "card":
                    try await insertCardInventoryRowNew(fields: fields, currency: importCurrency, context: context)
                case "sealed product":
                    try await insertSealedProductInventoryRowNew(fields: fields, currency: importCurrency, context: context)
                default:
                    throw CSVImportError.unknownType(fields[0])
                }
            } else {
                guard fields.count >= legacyExpected.count else { throw CSVImportError.invalidRow }
                switch type {
                case "card":
                    try await insertCardInventoryRow(fields: fields, context: context)
                case "sealed product":
                    try await insertSealedProductInventoryRow(fields: fields, context: context)
                default:
                    throw CSVImportError.unknownType(fields[0])
                }
            }
        }
        
        try context.save()
    }
    
    /// Imports an Archive CSV file into the given ModelContext.
    ///
    /// Supports both the new format with Card Set, Sale Date, and currency codes:
    /// `Type,Name,Number,Card Set,Condition/Graded,Buy Price (CAD),Sale Price (CAD),Profit (CAD),Purchase Date,Sale Date`
    ///
    /// And the legacy format:
    /// `Type,Name,Number,Condition/Graded,Buy Price,Sale Price,Profit,Purchase Date`
    ///
    /// Optionally includes a Misc Expenses section with header:
    /// `Description,Cost (CAD),Purchase Date,Notes`
    ///
    /// The Profit column is ignored (computed).
    ///
    /// - Parameters:
    ///   - url: The file URL of the CSV file to import.
    ///   - context: The ModelContext to insert the models into.
    /// - Throws: CSVImportError or other errors related to file reading or context saving.
    public static func importArchiveCSV(from url: URL, into context: ModelContext) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let rows = parseCSV(normalizedContent)
        guard !rows.isEmpty else { throw CSVImportError.invalidHeader(expected: ["Type", "Name", "Number", "Card Set", "Condition/Graded", "Buy Price", "Sale Price", "Profit", "Purchase Date", "Sale Date"], found: []) }
        
        let header = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let newExpected = ["Type", "Name", "Number", "Card Set", "Condition/Graded", "Buy Price", "Sale Price", "Profit", "Purchase Date", "Sale Date"]
        let legacyExpected = ["Type", "Name", "Number", "Condition/Graded", "Buy Price", "Sale Price", "Profit", "Purchase Date"]
        
        let isNewFormat = headerMatches(header, expected: newExpected)
        let isLegacyFormat = header == legacyExpected
        
        guard isNewFormat || isLegacyFormat else {
            throw CSVImportError.invalidHeader(expected: newExpected, found: header)
        }
        
        let importCurrency = isNewFormat ? detectCurrency(from: header) : "CAD"
        
        var inMiscExpensesSection = false
        var miscExpensesHeaderFound = false
        
        for idx in 1..<rows.count {
            let row = rows[idx]
            
            // Skip empty rows
            if row.isEmpty || row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }
            
            let firstField = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if we're entering the Misc Expenses section
            if firstField.lowercased() == "misc expenses" {
                inMiscExpensesSection = true
                continue
            }
            
            // Check for Misc Expenses header
            if inMiscExpensesSection && firstField.lowercased() == "description" {
                miscExpensesHeaderFound = true
                continue
            }
            
            // Process rows based on section
            if inMiscExpensesSection && miscExpensesHeaderFound {
                if row.count >= 3 {
                    try await insertMiscExpenseRow(fields: row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }, currency: importCurrency, context: context)
                }
            } else if !inMiscExpensesSection {
                let fields = row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let type = fields[0].lowercased()
                
                if isNewFormat {
                    guard fields.count >= newExpected.count else { throw CSVImportError.invalidRow }
                    switch type {
                    case "card":
                        try await insertCardArchiveRowNew(fields: fields, currency: importCurrency, context: context)
                    case "sealed product":
                        try await insertSealedProductArchiveRowNew(fields: fields, currency: importCurrency, context: context)
                    default:
                        throw CSVImportError.unknownType(fields[0])
                    }
                } else {
                    guard fields.count >= legacyExpected.count else { throw CSVImportError.invalidRow }
                    switch type {
                    case "card":
                        try await insertCardArchiveRow(fields: fields, context: context)
                    case "sealed product":
                        try await insertSealedProductArchiveRow(fields: fields, context: context)
                    default:
                        throw CSVImportError.unknownType(fields[0])
                    }
                }
            }
        }
        
        try context.save()
    }
    
    // MARK: - Private helpers
    
    private static func insertCardInventoryRow(fields: [String], context: ModelContext) async throws {
        // Fields index mapping based on inventory csv:
        // Type(0), Name(1), Number(2), Condition/Graded(3), Buy Price(4), Purchase Date(5)
        let name = fields[1]
        let numberField = fields[2]
        let number: String? = numberField.isEmpty ? nil : numberField
        let conditionText = fields[3]
        let buyPriceString = fields[4]
        let purchaseDateString = fields[5]
        
        guard !name.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let (graded, gradeLevel, condition) = parseConditionField(conditionText)
        
        let card = Cards(
            name: name,
            number: number,
            graded: graded,
            gradeLevel: gradeLevel,
            condition: condition,
            buyPrice: buyPrice,
            purchaseDate: purchaseDate
        )
        context.insert(card)
    }
    
    private static func insertSealedProductInventoryRow(fields: [String], context: ModelContext) async throws {
        // Fields index mapping based on inventory csv:
        // Type(0), Name(1), Number(2), Condition/Graded(3), Buy Price(4), Purchase Date(5)
        let nameField = fields[1]
        let buyPriceString = fields[4]
        let purchaseDateString = fields[5]
        
        guard !nameField.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let (name, expansion) = splitNameAndExpansion(nameField)
        
        let sealed = SealedProduct(
            name: name,
            expansion: expansion ?? "",
            buyPrice: buyPrice,
            purchaseDate: purchaseDate
        )
        context.insert(sealed)
    }
    
    private static func insertCardArchiveRow(fields: [String], context: ModelContext) async throws {
        // Fields index mapping based on archive csv:
        // Type(0), Name(1), Number(2), Condition/Graded(3), Buy Price(4), Sale Price(5), Profit(6), Purchase Date(7)
        let name = fields[1]
        let numberField = fields[2]
        let number: String? = numberField.isEmpty ? nil : numberField
        let conditionText = fields[3]
        let buyPriceString = fields[4]
        let salePriceString = fields[5]
        let purchaseDateString = fields[7]
        
        guard !name.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        var salePrice: Double? = nil
        if !salePriceString.isEmpty {
            salePrice = parseDouble(salePriceString)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let (graded, gradeLevel, condition) = parseConditionField(conditionText)
        
        let card = Cards(
            name: name,
            number: number,
            graded: graded,
            gradeLevel: gradeLevel,
            condition: condition,
            buyPrice: buyPrice,
            salePrice: salePrice,
            purchaseDate: purchaseDate
        )
        context.insert(card)
    }
    
    private static func insertSealedProductArchiveRow(fields: [String], context: ModelContext) async throws {
        // Fields index mapping based on archive csv:
        // Type(0), Name(1), Number(2), Condition/Graded(3), Buy Price(4), Sale Price(5), Profit(6), Purchase Date(7)
        let nameField = fields[1]
        let buyPriceString = fields[4]
        let salePriceString = fields[5]
        let purchaseDateString = fields[7]
        
        guard !nameField.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        var salePrice: Double? = nil
        if !salePriceString.isEmpty {
            salePrice = parseDouble(salePriceString)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let (name, expansion) = splitNameAndExpansion(nameField)
        
        let sealed = SealedProduct(
            name: name,
            expansion: expansion ?? "",
            buyPrice: buyPrice,
            salePrice: salePrice,
            purchaseDate: purchaseDate
        )
        context.insert(sealed)
    }
    
    // MARK: - New format helpers (with Card Set, Market Price, Sale Date, currency conversion)
    
    private static func insertCardInventoryRowNew(fields: [String], currency: String, context: ModelContext) async throws {
        // Type(0), Name(1), Number(2), Card Set(3), Condition/Graded(4), Buy Price(5), Market Price(6), Purchase Date(7)
        let name = fields[1]
        let numberField = fields[2]
        let number: String? = numberField.isEmpty ? nil : numberField
        let cardSetField = fields[3]
        let cardSet: String? = cardSetField.isEmpty ? nil : cardSetField
        let conditionText = fields[4]
        let buyPriceString = fields[5]
        let marketPriceString = fields[6]
        let purchaseDateString = fields[7]
        
        guard !name.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        var marketPrice: Double? = nil
        if !marketPriceString.isEmpty, let mp = parseDouble(marketPriceString) {
            marketPrice = toStorage(mp, fromCode: currency)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let (graded, gradeLevel, condition) = parseConditionField(conditionText)
        
        let card = Cards(
            name: name,
            number: number,
            cardSet: cardSet,
            graded: graded,
            gradeLevel: gradeLevel,
            condition: condition,
            buyPrice: toStorage(buyPrice, fromCode: currency),
            purchaseDate: purchaseDate,
            marketPrice: marketPrice,
            marketPriceDate: marketPrice != nil ? Date() : nil
        )
        context.insert(card)
    }
    
    private static func insertSealedProductInventoryRowNew(fields: [String], currency: String, context: ModelContext) async throws {
        // Type(0), Name(1), Number(2), Card Set(3), Condition/Graded(4), Buy Price(5), Market Price(6), Purchase Date(7)
        // For sealed products: Name(1) is the product name, Condition/Graded(4) holds the expansion
        let name = fields[1]
        let expansionField = fields[4]
        let expansion: String? = expansionField.isEmpty || expansionField == "N/A" ? nil : expansionField
        let buyPriceString = fields[5]
        let purchaseDateString = fields[7]
        
        guard !name.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let sealed = SealedProduct(
            name: name,
            expansion: expansion ?? "",
            buyPrice: toStorage(buyPrice, fromCode: currency),
            purchaseDate: purchaseDate
        )
        context.insert(sealed)
    }
    
    private static func insertCardArchiveRowNew(fields: [String], currency: String, context: ModelContext) async throws {
        // Type(0), Name(1), Number(2), Card Set(3), Condition/Graded(4), Buy Price(5), Sale Price(6), Profit(7), Purchase Date(8), Sale Date(9)
        let name = fields[1]
        let numberField = fields[2]
        let number: String? = numberField.isEmpty ? nil : numberField
        let cardSetField = fields[3]
        let cardSet: String? = cardSetField.isEmpty ? nil : cardSetField
        let conditionText = fields[4]
        let buyPriceString = fields[5]
        let salePriceString = fields[6]
        // Profit(7) is ignored — computed
        let purchaseDateString = fields[8]
        let saleDateString = fields.count > 9 ? fields[9] : ""
        
        guard !name.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        var salePrice: Double? = nil
        if !salePriceString.isEmpty, let sp = parseDouble(salePriceString) {
            salePrice = toStorage(sp, fromCode: currency)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        var saleDate: Date? = nil
        if !saleDateString.isEmpty {
            saleDate = parseDate(saleDateString)
        }
        
        let (graded, gradeLevel, condition) = parseConditionField(conditionText)
        
        let card = Cards(
            name: name,
            number: number,
            cardSet: cardSet,
            graded: graded,
            gradeLevel: gradeLevel,
            condition: condition,
            buyPrice: toStorage(buyPrice, fromCode: currency),
            salePrice: salePrice,
            saleDate: saleDate,
            purchaseDate: purchaseDate
        )
        context.insert(card)
    }
    
    private static func insertSealedProductArchiveRowNew(fields: [String], currency: String, context: ModelContext) async throws {
        // Type(0), Name(1), Number(2), Card Set(3), Condition/Graded(4), Buy Price(5), Sale Price(6), Profit(7), Purchase Date(8), Sale Date(9)
        // For sealed products: Condition/Graded(4) holds the expansion
        let name = fields[1]
        let expansionField = fields[4]
        let expansion: String? = expansionField.isEmpty || expansionField == "N/A" ? nil : expansionField
        let buyPriceString = fields[5]
        let salePriceString = fields[6]
        // Profit(7) is ignored
        let purchaseDateString = fields[8]
        let saleDateString = fields.count > 9 ? fields[9] : ""
        
        guard !name.isEmpty else { throw CSVImportError.missingRequiredField("Name") }
        guard !buyPriceString.isEmpty else { throw CSVImportError.missingRequiredField("Buy Price") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let buyPrice = parseDouble(buyPriceString) else {
            throw CSVImportError.numberParseFailed(buyPriceString)
        }
        
        var salePrice: Double? = nil
        if !salePriceString.isEmpty, let sp = parseDouble(salePriceString) {
            salePrice = toStorage(sp, fromCode: currency)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        var saleDate: Date? = nil
        if !saleDateString.isEmpty {
            saleDate = parseDate(saleDateString)
        }
        
        let sealed = SealedProduct(
            name: name,
            expansion: expansion ?? "",
            buyPrice: toStorage(buyPrice, fromCode: currency),
            salePrice: salePrice,
            saleDate: saleDate,
            purchaseDate: purchaseDate
        )
        context.insert(sealed)
    }
    
    private static func insertMiscExpenseRow(fields: [String], currency: String, context: ModelContext) async throws {
        // Fields index mapping for misc expenses:
        // Description(0), Cost(1), Purchase Date(2), Notes(3)
        let description = fields[0]
        let costString = fields[1]
        let purchaseDateString = fields[2]
        let notes = fields.count > 3 ? fields[3] : nil
        
        guard !description.isEmpty else { throw CSVImportError.missingRequiredField("Description") }
        guard !costString.isEmpty else { throw CSVImportError.missingRequiredField("Cost") }
        guard !purchaseDateString.isEmpty else { throw CSVImportError.missingRequiredField("Purchase Date") }
        
        guard let cost = parseDouble(costString) else {
            throw CSVImportError.numberParseFailed(costString)
        }
        
        guard let purchaseDate = parseDate(purchaseDateString) else {
            throw CSVImportError.dateParseFailed(purchaseDateString)
        }
        
        let expense = MiscExpense(
            itemDescription: description,
            cost: toStorage(cost, fromCode: currency),
            purchaseDate: purchaseDate,
            notes: notes?.isEmpty == false ? notes : nil
        )
        context.insert(expense)
    }
    
    /// Parses a condition field from CSV and returns graded status, grade level, and condition string.
    ///
    /// Recognizes:
    /// - "PSA 10", "PSA 9", etc. → graded=true, gradeLevel=10/9/etc., condition="PSA 10"
    /// - "GRADED" → graded=true, gradeLevel=nil, condition="GRADED"
    /// - Anything else → graded=false, gradeLevel=nil, condition as-is (or "NM" if empty)
    private static func parseConditionField(_ text: String) -> (graded: Bool, gradeLevel: Int?, condition: String) {
        let upper = text.uppercased().trimmingCharacters(in: .whitespaces)
        
        if upper.hasPrefix("PSA "), let level = Int(upper.dropFirst(4).trimmingCharacters(in: .whitespaces)), (1...10).contains(level) {
            return (true, level, "PSA \(level)")
        } else if upper == "GRADED" {
            return (true, nil, "GRADED")
        } else {
            return (false, nil, text.isEmpty ? "NM" : text)
        }
    }
    
    /// Attempts to parse a Double value from a string using the current locale.
    ///
    /// Falls back to Double(string) if locale parsing fails.
    /// Handles comma-separated thousands (e.g., "1,000.00").
    /// - Parameter s: The string to parse.
    /// - Returns: The parsed Double, or nil on failure.
    public static func parseDouble(_ s: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: s) {
            return number.doubleValue
        }
        
        // Try removing commas and parsing again (for numbers like "1,000.00")
        let withoutCommas = s.replacingOccurrences(of: ",", with: "")
        if let number = Double(withoutCommas) {
            return number
        }
        
        return Double(s)
    }
    
    /// Attempts to parse a Date from a string using multiple common date formats.
    ///
    /// Tries the following formats in order:
    /// - M/d/yyyy (e.g., 1/15/2026)
    /// - MM/dd/yyyy (e.g., 01/15/2026)
    /// - Current locale's short date style
    /// - ISO8601 format
    ///
    /// - Parameter s: The string to parse.
    /// - Returns: The parsed Date, or nil if parsing failed.
    public static func parseDate(_ s: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        
        // Try common date formats
        let formats = [
            "M/d/yyyy",      // 1/15/2026
            "MM/dd/yyyy",    // 01/15/2026
            "M/d/yy",        // 1/15/26
            "MM/dd/yy",      // 01/15/26
            "yyyy-MM-dd",    // 2026-01-15
            "M-d-yyyy",      // 1-15-2026
            "MM-dd-yyyy"     // 01-15-2026
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: s) {
                return date
            }
        }
        
        // Try current locale's short date style
        dateFormatter.dateFormat = nil
        dateFormatter.dateStyle = .short
        if let date = dateFormatter.date(from: s) {
            return date
        }
        
        // Try ISO8601 as last resort
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: s)
    }
    
    /// Splits a name string into a name and optional expansion by splitting on " - ".
    ///
    /// If the string contains " - ", the part before is the name, the part after is the expansion.
    /// Otherwise, expansion is nil.
    ///
    /// - Parameter s: The full name string.
    /// - Returns: A tuple with name and optional expansion.
    public static func splitNameAndExpansion(_ s: String) -> (name: String, expansion: String?) {
        let parts = s.components(separatedBy: " - ")
        if parts.count == 2 {
            return (parts[0], parts[1])
        } else {
            return (s, nil)
        }
    }
}




