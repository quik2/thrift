# ThriftFlip SwiftUI Component Specs

These are ready to hand directly to Codex in Xcode. Each component includes exact behavior, design tokens, and a preview requirement.

All components use `TFColor`, `TFFont`, `TFSpacing` from `Core/DesignSystem/`. Never hardcode values.

---

## 1. ConfidenceBadge

**Purpose:** Visual indicator of confidence level on results and collection items.

**Input:**
```swift
struct ConfidenceBadge: View {
    let level: ConfidenceLevel  // .high, .medium, .low
    let score: Int              // 0-100
}
```

**Appearance:**
| Level | Background | Text | Label |
|-------|-----------|------|-------|
| high | TFColor.gainGreen.opacity(0.15) | TFColor.gainGreen | "High · 87%" |
| medium | TFColor.gold.opacity(0.15) | TFColor.gold | "Medium · 62%" |
| low | TFColor.warning.opacity(0.15) | TFColor.warning | "Low · 31%" |

**Layout:**
- Pill shape (cornerRadius: .pill)
- Horizontal: icon (circle.fill, 6pt) + label text
- Padding: horizontal TFSpacing.sm, vertical TFSpacing.xs
- Font: TFFont.caption

**Preview:** Show all three states side by side.

---

## 2. PriceRangeView

**Purpose:** Display the low/median/high price estimate. This is the core value moment.

**Input:**
```swift
struct PriceRangeView: View {
    let priceRange: PriceRange
    let confidence: ConfidenceLevel
}
```

**Layout:**
- Median price: TFFont.display, TFColor.textPrimary (this is the hero number)
- Below median: "Low $42 — High $95" in TFFont.caption, TFColor.textSecondary
- Format all prices as currency: "$67.50" (no cents if .00)
- When confidence is .low: show median in TFColor.textSecondary instead of textPrimary, append "est." after the number

**Preview:** Show high-confidence and low-confidence variants.

---

## 3. CompCard

**Purpose:** Single comparable listing in the result detail view.

**Input:**
```swift
struct CompCard: View {
    let comp: CompListing
}
```

**Layout:**
- Card background: TFColor.cardSurface, cornerRadius: .medium
- Left: thumbnail image (48x48, cornerRadius: .small, placeholder if no image)
- Right of image, stacked vertically:
  - Title: TFFont.caption, TFColor.textPrimary, 1 line, truncated
  - Price + status badge: "$72.00" in TFFont.headline + "SOLD" or "ACTIVE" badge
- Status badge:
  - Sold: TFColor.gainGreen text, gainGreen.opacity(0.15) background
  - Active: TFColor.textSecondary text, textSecondary.opacity(0.15) background
- Padding: TFSpacing.sm all sides

**Preview:** Show sold and active variants.

---

## 4. ScanButton

**Purpose:** Primary action button on the scan screen. Always visible, always tappable.

**Input:**
```swift
struct ScanButton: View {
    let isScanning: Bool
    let action: () -> Void
}
```

**Layout:**
- Circle, 72pt diameter
- Default state: TFColor.gainGreen background, white camera icon (SF Symbol: "camera.fill", 28pt)
- Scanning state: TFColor.gainGreen background, spinning progress indicator (white, 28pt)
- Shadow: black.opacity(0.3), radius 8, y offset 4
- Tap animation: scale down to 0.9 on press, spring back

**Preview:** Show default and scanning states.

---

## 5. ResultCard

**Purpose:** The primary value moment — shown after a scan completes. Contains identification, price range, confidence, and action buttons.

**Input:**
```swift
struct ResultCard: View {
    let result: ScanResult
    let onSave: () -> Void
    let onRescan: () -> Void
    let onCorrect: () -> Void
}
```

**Layout:**
- Card background: TFColor.cardSurface, cornerRadius: .large
- Top section:
  - Item image thumbnail (full width, 180pt height, cornerRadius: .medium top only)
- Content section (padded TFSpacing.md):
  - Row 1: Brand + item name (TFFont.headline) + ConfidenceBadge (trailing)
  - Row 2: Category/garment type (TFFont.caption, TFColor.textSecondary)
  - Row 3: PriceRangeView
  - Row 4: Comp count label ("Based on 47 comps" — TFFont.micro, TFColor.textTertiary)
  - Row 5: Horizontal scroll of CompCards (max 5 visible)
- Bottom action bar (padded TFSpacing.md):
  - Save button (primary): TFColor.gainGreen background, "Save" text
  - Rescan button (secondary): bordered, TFColor.textSecondary
  - "Mark Incorrect" text button: TFFont.caption, TFColor.textTertiary

**Low-confidence variant:**
When confidence is .low:
- Add yellow/orange top banner: "We're not sure about this one" (TFFont.caption, TFColor.warning)
- Change brand text to: "This might be [brand]"
- Add "Try scanning the tag" suggestion below comp count
- Suppress "Save" as primary — make "Rescan" primary instead

**Preview:** Show high-confidence and low-confidence variants.

---

## 6. EmptyStateView

**Purpose:** Reusable empty/error/offline state for any screen.

**Input:**
```swift
struct EmptyStateView: View {
    let icon: String          // SF Symbol name
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
}
```

**Layout:**
- Centered vertically in available space
- Icon: 48pt, TFColor.textTertiary
- Title: TFFont.headline, TFColor.textPrimary, below icon by TFSpacing.md
- Message: TFFont.body, TFColor.textSecondary, below title by TFSpacing.sm, multiline center-aligned, max width 280pt
- Action button (if provided): below message by TFSpacing.lg, TFColor.gainGreen background, pill shape, TFFont.caption

**Preset configurations:**

```swift
extension EmptyStateView {
    static var noScans: EmptyStateView {
        EmptyStateView(
            icon: "camera.viewfinder",
            title: "No scans yet",
            message: "Scan a tag and item to see what it's worth.",
            actionLabel: "Start Scanning",
            action: nil  // caller provides
        )
    }

    static var networkError: EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No connection",
            message: "Check your internet and try again.",
            actionLabel: "Retry",
            action: nil
        )
    }

    static var noComps: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No comparables found",
            message: "We couldn't find similar listings. Try scanning the tag for better results.",
            actionLabel: "Rescan",
            action: nil
        )
    }

    static var ocrFailed: EmptyStateView {
        EmptyStateView(
            icon: "text.viewfinder",
            title: "Couldn't read the tag",
            message: "Make sure the tag text is visible and well-lit, then try again.",
            actionLabel: "Try Again",
            action: nil
        )
    }
}
```

**Preview:** Show all four presets.

---

## 7. ItemRow

**Purpose:** Single item in the Collection list.

**Input:**
```swift
struct ItemRow: View {
    let item: SavedItem   // lightweight version of ScanResult for list display
}
```

**SavedItem model (for collection list):**
```swift
struct SavedItem: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let identification: Identification
    let priceRange: PriceRange
    let confidence: Confidence
    let thumbnailUrl: String
    let corrected: Bool
}
```

**Layout:**
- Row height: ~72pt
- Left: thumbnail (56x56, cornerRadius: .small)
- Center (stacked):
  - Brand + item name (TFFont.body, TFColor.textPrimary, 1 line truncated)
  - Category (TFFont.caption, TFColor.textSecondary)
  - Median price (TFFont.headline, TFColor.textPrimary)
- Right: ConfidenceBadge (compact variant — just the colored dot + score, no label text)
- If corrected: small "Corrected" label in TFFont.micro, TFColor.gold
- Background: TFColor.background (transparent, no card)
- Bottom separator: TFColor.cardSurface, 1pt

**Preview:** Show regular item, corrected item, and low-confidence item.

---

## Build Order

Build these in this order (each depends on the previous):

1. **Design tokens** (Colors.swift, Typography.swift, Spacing.swift, Color+Hex.swift)
2. **ConfidenceBadge** (standalone, no dependencies)
3. **PriceRangeView** (uses PriceRange model)
4. **CompCard** (uses CompListing model)
5. **EmptyStateView** (standalone)
6. **ScanButton** (standalone)
7. **ItemRow** (uses SavedItem, ConfidenceBadge)
8. **ResultCard** (uses everything above)

After components: build screens in this order:
1. Onboarding → 2. Scan → 3. Scanning State → 4. Result → 5. Collection → 6. Item Detail → 7. Sell Tab
