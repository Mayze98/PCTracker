# Quick Reference: Using SharedComponents

## 📦 Available Components

### 1. Row Components

#### InventoryCardRow
```swift
InventoryCardRow(
    card: Cards,
    isMultiSelectMode: Bool,
    isSelected: Bool,
    showProfit: Bool,           // true for archived, false for inventory
    onTap: () -> Void,
    onDelete: () -> Void,
    onEdit: () -> Void
)
```

#### InventorySealedProductRow
```swift
InventorySealedProductRow(
    product: SealedProduct,
    isMultiSelectMode: Bool,
    isSelected: Bool,
    showProfit: Bool,           // true for archived, false for inventory
    onTap: () -> Void,
    onDelete: () -> Void,
    onEdit: () -> Void
)
```

#### InventoryMiscExpenseRow
```swift
InventoryMiscExpenseRow(
    expense: MiscExpense,
    isMultiSelectMode: Bool,
    isSelected: Bool,
    onTap: () -> Void,
    onDelete: () -> Void,
    onEdit: () -> Void
)
```

### 2. UI Components

#### EmptyStateView
```swift
EmptyStateView(
    icon: "systemImageName",    // SF Symbol name
    title: "Title Text",
    subtitle: "Subtitle Text"
)
```

**Example:**
```swift
EmptyStateView(
    icon: "archivebox",
    title: "No archived items",
    subtitle: "Items you sold will appear here"
)
```

#### NoResultsView
```swift
NoResultsView()                 // No parameters needed
```

#### RangeSlider
```swift
RangeSlider(
    minValue: $minValue,        // Binding<Double>
    maxValue: $maxValue,        // Binding<Double>
    bounds: 0...10000,          // ClosedRange<Double>
    step: 1                     // Double (optional, default 0.01)
)
.frame(height: 30)
```

### 3. Sorting Extensions

#### For Cards
```swift
let sorted = cards.sorted(by: "Date", ascending: true)
// Options: "Date", "Profit", "Buy Price", "Sale Price", "Name"
```

#### For SealedProduct
```swift
let sorted = products.sorted(by: "Name", ascending: false)
// Options: "Date", "Profit", "Buy Price", "Sale Price", "Name"
```

#### For MiscExpense
```swift
let sorted = expenses.sorted(by: "Date", ascending: true)
// Options: "Date", "Profit", "Buy Price", "Sale Price", "Name"
```

---

## 🎯 Usage Examples

### Example 1: Card Row in Archived View (with profit)

```swift
Section("Cards") {
    ForEach(cards) { card in
        InventoryCardRow(
            card: card,
            isMultiSelectMode: isMultiSelectMode,
            isSelected: selectedCards.contains(card.id),
            showProfit: true,                   // ← Show profit info
            onTap: { handleCardTap(card) },
            onDelete: { modelContext.delete(card) },
            onEdit: { selectedCard = card }
        )
    }
}
```

### Example 2: Card Row in Inventory View (no profit)

```swift
Section("Cards") {
    ForEach(cards) { card in
        InventoryCardRow(
            card: card,
            isMultiSelectMode: isMultiSelectMode,
            isSelected: selectedCards.contains(card.id),
            showProfit: false,                  // ← Hide profit info
            onTap: {
                if isMultiSelectMode {
                    // Handle selection
                } else {
                    selectedCard = card
                }
            },
            onDelete: { modelContext.delete(card) },
            onEdit: { selectedCard = card }
        )
    }
}
```

### Example 3: Empty State

```swift
@ViewBuilder
private var contentView: some View {
    if items.isEmpty {
        EmptyStateView(
            icon: "cube.box",
            title: "No Items",
            subtitle: "Add some items to get started"
        )
    } else {
        listView
    }
}
```

### Example 4: Sorting

```swift
private var sortedCards: [Cards] {
    let filtered = cards.filter { /* your filters */ }
    return filtered.sorted(by: sortOption.rawValue, ascending: sortAscending)
}
```

### Example 5: Range Slider in Filter

```swift
Section {
    Toggle("Filter by Price", isOn: $usePriceFilter)
    
    if usePriceFilter {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Min").font(.caption)
                    TextField("0", value: $minPrice, format: .number)
                }
                VStack(alignment: .leading) {
                    Text("Max").font(.caption)
                    TextField("1000", value: $maxPrice, format: .number)
                }
            }
            
            RangeSlider(
                minValue: $minPrice,
                maxValue: $maxPrice,
                bounds: 0...10000,
                step: 1
            )
            .frame(height: 30)
        }
    }
}
```

---

## 🔧 Customization Tips

### Modifying Row Display

To change how rows look, edit the component in `SharedComponents.swift`:
- Single change updates ALL views using that component
- No need to update ArchivedView and InventoryView separately

### Adding New Sort Options

1. Update the enum in your view:
```swift
enum SortOption: String {
    case date = "Date"
    case profit = "Profit"
    case newOption = "New Option"  // ← Add here
}
```

2. Update the extension in SharedComponents.swift:
```swift
extension Array where Element == Cards {
    func sorted(by option: String, ascending: Bool) -> [Cards] {
        sorted { card1, card2 in
            let result: Bool
            switch option {
            case "Date": // ...
            case "New Option":      // ← Add case here
                result = /* your logic */
            default: // ...
            }
            return ascending ? result : !result
        }
    }
}
```

### Changing Empty States

Edit `EmptyStateView` in SharedComponents.swift:
- Adjust icon size
- Change fonts
- Modify colors
- All empty states update automatically

---

## ⚠️ Important Notes

1. **showProfit Parameter**
   - Use `true` for Archived view (shows sale price, profit, ROI)
   - Use `false` for Inventory view (hides profit info)

2. **Sort Option Strings**
   - Must match exactly: "Date", "Profit", "Buy Price", "Sale Price", "Name"
   - Case-sensitive

3. **RangeSlider Bounds**
   - Set appropriate bounds for your use case
   - Buy Price: 0...10000
   - Profit: -1000...5000

4. **Import Required**
   - Make sure `import SwiftData` is in files using these components

---

## 📚 Component Benefits

| Component | Benefit |
|-----------|---------|
| `InventoryCardRow` | Consistent card display everywhere |
| `InventorySealedProductRow` | Consistent product display |
| `InventoryMiscExpenseRow` | Consistent expense display |
| `EmptyStateView` | Uniform empty states |
| `NoResultsView` | Consistent no results messaging |
| `RangeSlider` | Reusable range selection |
| Sorting Extensions | Centralized, consistent sorting |

---

## 🎨 Styling

All components use:
- System fonts for consistency
- Adaptive colors (light/dark mode)
- Standard padding and spacing
- SF Symbols for icons

To customize:
1. Edit the component in SharedComponents.swift
2. Changes apply everywhere automatically
3. No need to update multiple files

---

## 🐛 Troubleshooting

**Problem:** Row doesn't display
- Check that the item has required properties
- Verify bindings are correct

**Problem:** Sorting doesn't work
- Ensure sort option string matches exactly
- Check that enum rawValue is used

**Problem:** Empty state doesn't show
- Verify your condition logic
- Check that items array is truly empty

**Problem:** RangeSlider not responding
- Ensure bindings ($minValue, $maxValue) are used
- Check bounds are appropriate
- Verify step value is reasonable

---

## 💡 Pro Tips

1. **Consistency** - Always use the same component for the same item type
2. **showProfit** - Remember to set correctly based on view context
3. **Callbacks** - Keep onTap, onDelete, onEdit logic simple
4. **Testing** - Test components in isolation first
5. **Documentation** - Add comments when customizing

---

## 📖 Related Files

- `SharedComponents.swift` - All reusable components and extensions
- `ArchivedView.swift` - Example usage (with profit)
- `InventoryView.swift` - Example usage (without profit)
- `FINAL_OPTIMIZATION_REPORT.md` - Full optimization details

---

Happy coding! 🚀
