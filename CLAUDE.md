# ThriftFlip — Project Context

## What This Is

ThriftFlip is an iOS app that scans thrift store clothing tags/items and returns eBay-backed resale price estimates with confidence scores.

**User promise:** "Scan the tag and item, then get an eBay-backed price range with confidence."

---

## Architecture

- **Platform:** iOS 17+
- **Language:** Swift 6, strict concurrency
- **UI Framework:** SwiftUI
- **Architecture Pattern:** MVVM with `@Observable` (not ObservableObject)
- **State:** `@Observable` for shared models, `@State` for private view state, `@Bindable` for injected observables
- **Navigation:** `NavigationStack` with typed routes
- **Async:** `async/await` throughout, no Combine unless wrapping a delegate API
- **Backend:** Python (FastAPI) — separate repo

---

## Project Structure

```
ThriftFlip/
├── App/
│   ├── ThriftFlipApp.swift
│   └── ContentView.swift
├── Core/
│   ├── DesignSystem/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   └── Components/
│   │       ├── ConfidenceBadge.swift
│   │       ├── PriceRangeView.swift
│   │       ├── CompCard.swift
│   │       ├── ScanButton.swift
│   │       ├── ResultCard.swift
│   │       ├── EmptyStateView.swift
│   │       └── ItemRow.swift
│   ├── Models/
│   │   ├── ScanResult.swift
│   │   ├── CompListing.swift
│   │   ├── PriceRange.swift
│   │   ├── ConfidenceLevel.swift
│   │   └── SavedItem.swift
│   ├── Services/
│   │   ├── ScanService.swift
│   │   ├── APIClient.swift
│   │   └── CameraService.swift
│   └── Utilities/
│       └── Color+Hex.swift
├── Features/
│   ├── Scan/
│   │   ├── ScanView.swift
│   │   ├── ScanViewModel.swift
│   │   └── ScanningStateView.swift
│   ├── Result/
│   │   ├── ResultView.swift
│   │   └── ResultViewModel.swift
│   ├── Collection/
│   │   ├── CollectionView.swift
│   │   ├── CollectionViewModel.swift
│   │   └── ItemDetailView.swift
│   ├── Sell/
│   │   ├── SellView.swift
│   │   └── SellViewModel.swift
│   └── Onboarding/
│       └── OnboardingView.swift
└── Resources/
    └── Assets.xcassets
```

---

## Design Tokens

### Colors

```swift
// Colors defined in Assets.xcassets with light/dark variants.
// SwiftUI resolves automatically based on colorScheme.
enum TFColor {
    // Semantic colors (adapt to light/dark)
    static let background = Color("TFBackground")         // Dark: #1F2123, Light: #FFFFFF
    static let cardSurface = Color("TFCardSurface")       // Dark: #2A2C2E, Light: #F5F5F7
    static let textPrimary = Color("TFTextPrimary")       // Dark: #FFFFFF, Light: #1A1A1A
    static let textSecondary = Color("TFTextSecondary")   // Dark: #9CA3AF, Light: #6B7280
    static let textTertiary = Color("TFTextTertiary")     // Dark: #48484A, Light: #9CA3AF

    // Fixed colors (same in both modes)
    static let gainGreen = Color(hex: "#5AC53A")          // Positive/profit indicators
    static let warning = Color(hex: "#EB5D2A")            // Warnings, low confidence, value decrease
    static let gold = Color(hex: "#F6C86A")               // Medium confidence, accents
}

// Theme modes: Dark (default), Light, System
// Scan screen always uses dark surround regardless of theme
```

### Typography (SF Pro, system font)

| Name | Size | Weight | Use |
|------|------|--------|-----|
| display | 42pt | bold | Price numbers |
| title1 | 28pt | semibold | Screen headers |
| title2 | 22pt | semibold | Section headers |
| headline | 18pt | semibold | Card titles |
| body | 16pt | regular | Content text |
| caption | 14pt | medium | Labels, badges |
| micro | 12pt | regular | Metadata, timestamps |

### Spacing

| Token | Value |
|-------|-------|
| xs | 4pt |
| sm | 8pt |
| md | 16pt |
| lg | 24pt |
| xl | 32pt |
| xxl | 48pt |

### Corner Radius

| Token | Value |
|-------|-------|
| small | 8pt |
| medium | 12pt |
| large | 16pt |
| pill | 999pt |

---

## Confidence Levels

| Level | Score | Color | Copy Style |
|-------|-------|-------|-----------|
| High | 80-100 | gainGreen | Direct: "Patagonia Better Sweater" |
| Medium | 55-79 | gold | Hedged: "Likely a Patagonia Better Sweater" |
| Low | 30-54 | warning | Cautious: "This might be..." + suggest rescan |
| Insufficient | 0-29 | textTertiary | "Not enough data" + offer manual entry |

Low confidence must NEVER use assertive language. Always offer tag-focused rescan.
Insufficient confidence must NOT display a price range — show manual entry instead.

---

## Navigation

Bottom tab bar with 3 tabs:
1. **Scan** (default, camera-first)
2. **Collection** ("My Finds")
3. **Sell** (eBay-only in MVP)

Profile/settings: top-corner sheet, not a tab.

---

## Rules

### DO
- Use `@Observable` for all view models (not ObservableObject)
- Use `async/await` for all async work
- Show confidence on every result
- Use cautious copy for low-confidence results
- Provide actionable recovery for every error state
- Use design tokens (TFColor, TFFont, TFSpacing) — never hardcode values
- Write SwiftUI Previews for every view
- Keep views under 100 lines — extract subviews

### DO NOT
- Never claim "scan anything" — always "scan the tag and item"
- Never show a single price number — always a range (low/median/high)
- Never use assertive language for low-confidence results
- Never use deprecated SwiftUI APIs (@ObservedObject, @StateObject, @EnvironmentObject for new code)
- Never force unwrap optionals
- Never hardcode colors, fonts, or spacing values
- Never add Poshmark/Mercari/Depop features — eBay only in MVP
- Never promise authentication of luxury items

---

## Key Data Shapes

See `specs/api-contract.md` for full API contract.

A scan result contains:
- `id`, `timestamp`
- `identification` (brand, item name, category, garment type)
- `priceRange` (low, median, high, currency)
- `confidence` (score 0-100, level high/medium/low/insufficient, factors array)
- `comps` (array of comparable listings with title, price, sold/active, source, image URL)
- `tagExtraction` (brand, size, material, rn number — all optional)

---

## MVP Scope Boundaries

**In scope:** Camera scan, OCR extraction, eBay comps (Browse API + Apify sold), price range with confidence, save to collection, correction input.

**Out of scope:** Poshmark/Mercari automation, Depop integration, multi-platform listing, advanced gamification, luxury authentication.

**Free tier:** 5 scans per day (locked, non-negotiable in MVP).

---

## Reference Docs

Authority order for build decisions:
1. `12_MVP_Canonical_Plan.md`
2. `specs/build-decisions.md` (gap resolutions — camera flow, onboarding, paywall, offline, persistence, permissions, navigation, error copy)
3. `specs/backend-scanner-spec.md` (algorithms, schema, confidence, pricing, all constants)
4. `specs/api-contract.md` (endpoints, data shapes, mock data)
5. `13_MVP_Build_Checklist.md`
6. `14_MVP_Risk_and_Decisions.md`
7. `11_MVP_UI_UX_Plan.md` (15 component specs, design tokens, states checklist)
8. `07_Testing_Plan.md`
