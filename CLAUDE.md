# ThriftFlip — Project Context

## What This Is

ThriftFlip is an iOS app that helps thrift store shoppers make instant buy/pass decisions. Scan a clothing tag, get sold price data, see a profit estimate, and know in 3 seconds whether it's worth buying.

**User promise:** "Scan it. Know if it's worth buying. In 3 seconds."

**Core differentiators (no competitor has all three):**
1. **Buy/Pass traffic light** — Green/Yellow/Red instant signal based on your personal profit threshold
2. **Sold price separation** — Shows what items actually sold for, not just what people are asking
3. **Multi-platform fee comparison** — Net profit across eBay, Poshmark, Mercari, Depop, and Whatnot

---

## Architecture

- **Platform:** iOS 17+
- **Language:** Swift 6, strict concurrency
- **UI Framework:** SwiftUI
- **Architecture Pattern:** MVVM with `@Observable` (not ObservableObject)
- **State:** `@Observable` for shared models, `@State` for private view state, `@Bindable` for injected observables
- **Navigation:** `NavigationStack` with typed routes
- **Async:** `async/await` throughout, no Combine unless wrapping a delegate API
- **Backend:** Python (FastAPI) on Render, Supabase (auth + DB + storage), Upstash Redis

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
│   │       ├── ItemRow.swift
│   │       ├── BuySignalView.swift
│   │       ├── PlatformComparisonView.swift
│   │       └── MarketInsightsView.swift
│   ├── Models/
│   │   ├── ScanResult.swift
│   │   ├── CompListing.swift
│   │   ├── PricingBreakdown.swift
│   │   ├── PriceRange.swift
│   │   ├── MarketInsights.swift
│   │   ├── PlatformEstimate.swift
│   │   ├── BuySignal.swift
│   │   ├── ConfidenceLevel.swift
│   │   ├── UserSettings.swift
│   │   ├── ListingDraft.swift
│   │   └── PortfolioSummary.swift
│   ├── Services/
│   │   ├── ScanService.swift
│   │   ├── APIClient.swift
│   │   ├── CameraService.swift
│   │   ├── SettingsService.swift
│   │   └── ListingService.swift
│   └── Utilities/
│       └── Color+Hex.swift
├── Features/
│   ├── Scan/
│   │   ├── ScanView.swift
│   │   ├── ScanViewModel.swift
│   │   ├── ScanningStateView.swift
│   │   └── CompactResultCard.swift
│   ├── Result/
│   │   ├── ResultView.swift
│   │   └── ResultViewModel.swift
│   ├── MyFinds/
│   │   ├── MyFindsView.swift
│   │   ├── MyFindsViewModel.swift
│   │   └── ItemDetailView.swift
│   ├── Sell/
│   │   ├── SellView.swift
│   │   ├── SellViewModel.swift
│   │   ├── PortfolioDashboard.swift
│   │   ├── ListingDraftView.swift
│   │   └── ListingPhotoCapture.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── Onboarding/
│       ├── OnboardingView.swift
│       └── OnboardingQuizView.swift
└── Resources/
    └── Assets.xcassets
```

---

## Core UX Flows

### Rapid-Scan (In-Store)
1. Camera opens full-screen → user taps scan button
2. On-device ML runs (~340ms) → sends to backend
3. Compact result card slides up from bottom (~30% height) over live camera
4. Card shows: buy signal (green/yellow/red) + item name + price + profit estimate
5. Item auto-saves to My Finds with `status: "scanned"`
6. User can drag card up to see full details or scan next item immediately
7. Camera never closes — designed for scanning 15-20 items per trip

### Compact Card → Expanded Detail
- `.presentationDetents([.height(280), .large])` — iOS native sheet
- Compact: signal + item name + price + profit (the "in-store glance")
- Expanded: full pricing, market data, comps, platform comparison
- Swipe down to dismiss, camera returns to full screen

### Item Lifecycle
- **Scanned** → automatic on every successful scan, appears in My Finds
- **Bought** → user taps "I Bought This", optionally enters actual purchase price
- No "Listed" or "Sold" states in MVP

### Onboarding Quiz (First Launch)
1. Experience level: beginner / intermediate / expert → controls progressive disclosure
2. Minimum profit per item → feeds buy/pass signal algorithm
3. Store type: Goodwill ($7), Salvation Army ($5), etc. → sets default cost estimate
4. Camera permission request

### Cost Estimation (Zero Friction)
- Cost comes from store type set in quiz (not per-scan input)
- Profit is always visible on every result — no "enter price" step
- User can override per-item later

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
    static let gainGreen = Color(hex: "#5AC53A")          // Positive/profit, green buy signal
    static let warning = Color(hex: "#EB5D2A")            // Warnings, red pass signal, value decrease
    static let gold = Color(hex: "#F6C86A")               // Medium confidence, yellow maybe signal
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

## Buy/Pass Signal

| Signal | Color | Meaning |
|--------|-------|---------|
| Green | gainGreen | Good buy — high sell-through, meets profit threshold |
| Yellow | gold | Maybe — moderate sell-through or tight margins |
| Red | warning | Pass — low sell-through, below threshold, or low confidence |

The buy signal is the **first thing** users see on the result card. It's the core UX.
Profit threshold and cost estimate come from user settings (set in onboarding quiz).

---

## Navigation

Bottom tab bar with 3 tabs:
1. **Scan** (default, camera-first, rapid-scan flow)
2. **My Finds** (scanned items grouped by date + bought items)
3. **Sell** (portfolio dashboard + eBay listing)

Profile/settings: top-corner sheet, not a tab.

---

## Item States

| State | How It Happens | Where It Shows |
|-------|---------------|----------------|
| `scanned` | Auto-save on every successful scan | My Finds → Scanned section |
| `bought` | User taps "I Bought This" | My Finds → Bought section, Sell tab portfolio |

No separate "collections" table — scans ARE the library. Every scan auto-saves silently.

---

## Rules

### DO
- Use `@Observable` for all view models (not ObservableObject)
- Use `async/await` for all async work
- Show the buy signal (green/yellow/red) on every result
- Show confidence on every result
- Separate sold prices from active prices — sold is primary
- Auto-save every successful scan (no manual save button)
- Use cost from settings for profit calculations (not per-scan input)
- Adapt UI detail level based on `experienceLevel` (beginner/intermediate/expert)
- Use cautious copy for low-confidence results
- Provide actionable recovery for every error state
- Use design tokens (TFColor, TFFont, TFSpacing) — never hardcode values
- Write SwiftUI Previews for every view
- Keep views under 100 lines — extract subviews

### DO NOT
- Never claim "scan anything" — always "scan the tag and item"
- Never show a single price number — always a range (low/median/high)
- Never blend sold and active prices without clear separation
- Never use assertive language for low-confidence results
- Never use deprecated SwiftUI APIs (@ObservedObject, @StateObject, @EnvironmentObject for new code)
- Never force unwrap optionals
- Never hardcode colors, fonts, or spacing values
- Never promise authentication of luxury items
- Never hardcode platform fees — use configurable constants
- Never use scan photos for eBay listings — users take separate product photos
- Never ask for thrift price per-scan — cost comes from settings

---

## Key Data Shapes

See `specs/api-contract.md` for full API contract and Swift models.

A scan result contains:
- `id`, `timestamp`, `status` (scanned/bought)
- `identification` (brand, item name, category, garment type)
- `pricingBreakdown` (sold range, active range, combined range — each with low/median/high)
- `marketInsights` (sell-through rate, avg days to sell, demand level, volume trend)
- `platformComparison` (array of 5 platforms with fee-adjusted net profit)
- `buySignal` (green/yellow/red signal with reason and ROI)
- `profitEstimate` (estimatedCost from settings, best net profit, best platform, ROI %)
- `confidence` (score 0-100, level high/medium/low/insufficient, factors array)
- `comps` (array of comparable listings with title, price, sold/active, source, image URL)
- `tagExtraction` (brand, size, material, rn number — all optional)
- `scanImages` (tagImageURL, itemImageURL optional, thumbnailURL)
- `purchasePrice` (set when user marks as bought, optional)

---

## MVP Scope Boundaries

**In scope:** Camera scan, OCR extraction, rapid-scan camera flow, compact card + expanded detail sheet, eBay comps (Browse API + Marketplace Insights), sold/active price separation, multi-platform fee comparison (eBay/Poshmark/Mercari/Depop/Whatnot), buy/pass traffic light signal, sell-through rate + market insights, user settings (profit threshold, platforms, shipping, experience level, store type), auto-save to library, item states (scanned/bought), haul grouping by date, portfolio dashboard, eBay listing (AI draft + product photos + publish), correction input, onboarding quiz, profit calculator.

**Out of scope:** Cross-posting to non-eBay platforms, Poshmark/Mercari/Depop/Whatnot sold data scraping (eBay data only in MVP, fee comparison is just math), Listed/Sold item states, advanced gamification, luxury authentication, seasonal price adjustment.

**Free tier:** 5 scans per day (locked, non-negotiable in MVP).

---

## Reference Docs

Authority order for build decisions:
1. `12_MVP_Canonical_Plan.md`
2. `specs/build-decisions.md` (23 gap resolutions — rapid-scan flow, onboarding quiz, paywall, offline, persistence, permissions, navigation, error copy, buy signal, sold/active separation, platform comparison, market insights, user settings, item states, haul grouping, portfolio, eBay listing, compact card UX)
3. `specs/backend-scanner-spec.md` (algorithms, schema, confidence, pricing, platform fees, buy signal algorithm, all constants)
4. `specs/api-contract.md` (endpoints, data shapes, Swift models, mock data for all 4 confidence tiers)
5. `13_MVP_Build_Checklist.md`
6. `14_MVP_Risk_and_Decisions.md`
7. `11_MVP_UI_UX_Plan.md` (15 component specs, design tokens, states checklist)
8. `07_Testing_Plan.md`
