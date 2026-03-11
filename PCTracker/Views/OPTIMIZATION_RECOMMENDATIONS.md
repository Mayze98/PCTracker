# Code Optimization Recommendations for PCTracker

## Summary
Your codebase has grown significantly, and there are multiple opportunities to reduce redundancy and improve maintainability. Here are the key optimizations:

## ✅ COMPLETED
1. **Created SharedComponents.swift** - Centralized reusable components including:
   - `InventoryCardRow` - Unified row view for cards (replaces CardRowView in both files)
   - `InventorySealedProductRow` - Unified row view for sealed products
   - `InventoryMiscExpenseRow` - Unified row view for expenses
   - `ActionButtonsBar` - Reusable Select/Filter/Sort button bar
   - `RangeSlider` - Single implementation for both filter views
   - `EmptyStateView` - Reusable empty state component
   - `NoResultsView` - Reusable no results component

## 🎯 RECOMMENDED CHANGES

### 1. Replace Duplicate Row Views in ArchivedView.swift (Lines ~700-900)
**Current:** 3 separate row view structs (CardRowView, SealedProductRowView, MiscExpenseRowView)
**Replace with:** SharedComponents versions

```swift
// In cardsSection, replace CardRowView with:
InventoryCardRow(
    card: card,
    isMultiSelectMode: isMultiSelectMode,
    isSelected: selectedCards.contains(card.id),
    showProfit: true, // Show profit in archived
    onTap: { handleCardTap(card) },
    onDelete: { modelContext.delete(card) },
    onEdit: { selectedCard = card }
)

// Similar for SealedProductRowView and MiscExpenseRowView
```

**Lines saved:** ~200 lines

### 2. Replace Button Bar in ArchivedView.swift (Lines ~416-530)
**Current:** Three separate button views (selectButton, filterButton, sortButton)
**Replace with:** ActionButtonsBar from SharedComponents

**Lines saved:** ~114 lines

### 3. Replace RangeSlider in ArchivedView.swift (Lines ~1100-1200)
**Current:** Full RangeSlider implementation duplicated
**Replace with:** Use RangeSlider from SharedComponents
**Delete:** The entire RangeSlider struct at the end of ArchivedView.swift

**Lines saved:** ~100 lines

### 4. Update InventoryView.swift to Use Shared Components
**Current:** Duplicate row views inline, duplicate button bar
**Replace with:** Use all shared components from SharedComponents.swift

**Lines saved:** ~250 lines

### 5. Consolidate Filter Logic
Create a shared `FilterHelper` for common filtering operations:
- Condition filtering
- Date range filtering  
- Price range filtering

**Lines saved:** ~150 lines across both files

### 6. Simplify Sort Functions
Both ArchivedView and InventoryView have nearly identical sorting logic. Create a generic sort function:

```swift
// In SharedComponents.swift
extension Collection where Element == Cards {
    func sorted(by option: String, ascending: Bool) -> [Cards] {
        sorted { card1, card2 in
            let result: Bool
            switch option {
            case "Date": result = card1.purchaseDate < card2.purchaseDate
            case "Profit": result = (card1.profit ?? 0) < (card2.profit ?? 0)
            case "Buy Price": result = card1.buyPrice < card2.buyPrice
            case "Sale Price": result = (card1.salePrice ?? 0) < (card2.salePrice ?? 0)
            case "Name": result = card1.name < card2.name
            default: result = card1.purchaseDate < card2.purchaseDate
            }
            return ascending ? result : !result
        }
    }
}
```

**Lines saved:** ~60 lines

### 7. Remove Empty State Duplication
**Current:** Custom empty state views in multiple places
**Replace with:** Use `EmptyStateView` from SharedComponents

```swift
// Replace emptyStateView in ArchivedView with:
EmptyStateView(
    icon: "archivebox",
    title: "No archived items",
    subtitle: "Items you sold will appear here"
)
```

**Lines saved:** ~40 lines

### 8. Consolidate noResultsSection
**Current:** Duplicate no results views  
**Replace with:** Use `NoResultsView()` from SharedComponents

**Lines saved:** ~30 lines per file = ~60 lines

### 9. Remove Commented Code
**Files:** AddCardView.swift has commented code (lines ~429-432)
```swift
//    var itemDescription: String
//    var cost: Double
//    var purchaseDate: Date
//    var notes: String?
```

**Action:** Delete commented code

### 10. Simplify Add Form Views  
**Current:** Three nearly identical form views in AddCardView.swift with duplicate validation
**Optimize:** Extract common validation and UI patterns

**Lines saved:** ~50 lines

## 📊 TOTAL POTENTIAL LINE REDUCTION

| File | Current Lines | After Optimization | Reduction |
|------|---------------|-------------------|-----------|
| ArchivedView.swift | 1206 | ~650 | **-556 lines** |
| InventoryView.swift | 707 | ~450 | **-257 lines** |
| AddCardView.swift | 545 | ~495 | **-50 lines** |
| **TOTAL** | **2458** | **~1595** | **-863 lines (35%)** |

## 🚀 PRIORITY ORDER

1. **HIGH PRIORITY** - Use SharedComponents in both ArchivedView and InventoryView
   - Immediate impact: ~500 lines saved
   - Better maintainability
   - Consistent UI across views

2. **MEDIUM PRIORITY** - Consolidate sorting and filtering logic
   - Impact: ~200 lines saved
   - Easier to add new features

3. **LOW PRIORITY** - Clean up commented code and minor optimizations
   - Impact: ~50 lines saved
   - Code clarity

## 💡 ADDITIONAL BENEFITS

Beyond line count reduction:

1. **Single Source of Truth** - UI changes only need to happen once
2. **Easier Testing** - Shared components can be tested in isolation
3. **Consistent Behavior** - Same component behavior across views
4. **Faster Development** - Reusable components speed up feature additions
5. **Reduced Bugs** - Fixes in shared components fix all usages

## 🔧 IMPLEMENTATION STEPS

1. Import SharedComponents in ArchivedView and InventoryView
2. Replace row views one type at a time (test after each)
3. Replace button bars
4. Replace RangeSlider  
5. Remove old implementations
6. Test thoroughly
7. Add sorting/filtering extensions
8. Final cleanup pass

## ⚠️ TESTING CHECKLIST

After refactoring, test:
- [ ] Card/Product/Expense row display
- [ ] Multi-select mode
- [ ] Edit sheets
- [ ] Delete functionality
- [ ] Filter application
- [ ] Sort functionality
- [ ] Search interaction
- [ ] Empty states
- [ ] No results states

Would you like me to proceed with implementing any of these optimizations?
