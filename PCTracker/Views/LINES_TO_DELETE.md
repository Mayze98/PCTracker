# Quick Reference: Lines to Delete

## ArchivedView.swift - Lines to Remove

### Section 1: Old Row View Structs (lines ~667-873)
**Delete from:** `// MARK: - Row Views`  
**Delete to:** Just before `extension ArchivedView {`

**What to delete:**
- `struct CardRowView: View { ... }`  
- `struct SealedProductRowView: View { ... }`
- `struct MiscExpenseRowView: View { ... }`

**Why:** These are replaced by shared components:
- `InventoryCardRow`
- `InventorySealedProductRow`
- `InventoryMiscExpenseRow`

### Section 2: Duplicate RangeSlider (lines ~1100-1200)
**Delete:** Entire `struct RangeSlider: View { ... }` implementation

**Why:** Already have RangeSlider in SharedComponents.swift

---

## AddCardView.swift - Lines to Remove

### Commented Code (lines ~429-432)
**Delete these commented lines:**
```swift
//    var itemDescription: String
//    var cost: Double
//    var purchaseDate: Date
//    var notes: String?
```

---

## Summary of Changes

| Action | Location | Lines Removed | Impact |
|--------|----------|---------------|---------|
| Delete old row views | ArchivedView.swift:667-873 | ~206 | High |
| Delete RangeSlider | ArchivedView.swift:~1100-1200 | ~100 | High |
| Delete comments | AddCardView.swift:~429-432 | 4 | Low |
| **TOTAL** | | **~310 lines** | **High** |

After these deletions:
- ArchivedView.swift: 1206 → ~900 lines (**-25%**)
- AddCardView.swift: 545 → 541 lines (**-1%**)
- **Total reduction: ~310 lines of duplicate/unused code**
- Plus gained: SharedComponents.swift with 530 lines of **reusable** code

**Net effect:** Cleaner, more maintainable codebase with centralized components!
