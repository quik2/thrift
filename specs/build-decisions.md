# ThriftFlip Build Decisions — Gap Resolution

**Purpose:** Fill every remaining specification gap so the build can proceed with zero ambiguity. Each section addresses a specific gap identified during the pre-build audit.

---

## Gap 1: Four Open Questions from Risk Doc

These were left unresolved in `14_MVP_Risk_and_Decisions.md`. Proposed answers:

### Q1: What confidence threshold triggers "low confidence" UI?

**Answer:** Score < 55 triggers low-confidence UI variant.

- **Score 80-100 (HIGH):** Direct language, green badge, "Save" as primary CTA
- **Score 55-79 (MEDIUM):** Hedged language ("Likely a..."), gold badge, "Save" as primary CTA
- **Score 30-54 (LOW):** Cautious language ("This might be..."), warning banner, "Rescan" as primary CTA, "Save Anyway" as secondary
- **Score 0-29 (INSUFFICIENT):** "Not enough data" message, gray badge, offer manual entry, no price range displayed

This aligns with `backend-scanner-spec.md` Section 6.3 and the `ConfidenceLevel` enum thresholds.

### Q2: What minimum comp count before showing a tight range?

**Answer:**

| Comp Count | Behavior |
|---|---|
| 0-2 | Do NOT display a price range. Show "Insufficient data" empty state. |
| 3-4 | Show min-max range with caveat: "Based on limited data" |
| 5-9 | Show P20-P80 range, no caveat |
| 10-19 | Show P15-P85 range |
| 20+ | Show P10-P90 range (tightest) |

This matches `backend-scanner-spec.md` Section 5.5. The "tight range" threshold is **10+ comps** for the narrow P15-P85 range, **20+ comps** for the tightest P10-P90.

### Q3: Which fields are mandatory for correction submissions?

**Answer:** At least ONE corrected field must be present. No field is individually mandatory.

```
Required: at least one of:
  - correctedBrand
  - correctedItemName
  - correctedCategory

Optional always:
  - correctedGarmentType
  - correctedSize
  - correctedColor
  - notes (free text)
```

**Validation rule:** If all corrected fields are `null`/empty and `notes` is empty, return 400 error: `"At least one correction field is required."`

**Re-pricing trigger:** If `correctedBrand` or `correctedItemName` changes, fire a background re-pricing job (ARQ) using corrected values. If only `correctedCategory` or metadata fields change, update the record but do NOT re-price (saves API calls).

### Q4: What user-visible copy when sold coverage is sparse?

**Answer:** Tiered copy based on comp count and source:

| Situation | Copy | Location |
|---|---|---|
| 0 sold comps, only active listings | "Based on active listings only — no recent sales found" | Below price range, `TFFont.micro`, `TFColor.textTertiary` |
| 1-2 sold comps | "Based on limited sales data" | Below price range, `TFFont.micro`, `TFColor.textTertiary` |
| 3+ sold comps | "Based on N recent sales" | Below price range, `TFFont.micro`, `TFColor.textSecondary` |
| 0 comps total | EmptyStateCard variant: `noComps` — "No comparable listings found. Try scanning the tag for better results." | Full result sheet body |
| Category-only match (no brand) | "Estimated from similar [category] items — results may vary" | Below price range, `TFFont.micro`, `TFColor.warning` |

---

## Gap 2: Rapid-Scan Camera Flow

The in-store experience must be fast. Users scan 15-20 items per trip. The camera should never close.

**Answer:**

### Flow
1. **Camera opens** → Full-screen viewfinder, scan button at bottom center
2. **User taps scan button** → Captures photo, on-device ML runs (~340ms)
3. **Compact result card slides up** from bottom (~30% of screen height), camera stays live behind it:
   ```
   ┌─────────────────────────────────────┐
   │          [CAMERA LIVE]              │
   │                                     │
   │                                     │
   │                                     │
   ├─────────────────────────────────────┤
   │  🟢 Good Buy                       │
   │  Patagonia Better Sweater · $67.50  │
   │  ~$43 profit on eBay               │
   │                         [▲ Details] │
   └─────────────────────────────────────┘
   ```
4. **Tap card or drag up** → Expands to full-screen detail sheet (`.presentationDetents([.height(280), .large])`)
5. **Swipe down** → Collapses back to compact card or dismisses entirely
6. **Scan next item** → Previous card is replaced, item auto-saved to library silently
7. **If OCR/pricing fails** → Compact card shows error state with "Retry" button

### Compact Card Contents (In-Store View)
- Buy signal circle (green/yellow/red) — 32pt, left-aligned
- Item name + brand — `TFFont.headline`
- Median sold price — `TFFont.title2`
- One-line profit estimate — `TFFont.caption`, `TFColor.textSecondary`
- Expand affordance — chevron or "Details" text, right side

### Expanded Detail Card (At-Home Review)
Full `ScanResult` display — see Gap 15 for result sheet content order.

### Auto-Save Behavior
- Every successful scan auto-saves with `status: "scanned"`
- No manual "Save" button needed
- Items silently appear in My Finds tab
- Failed scans (OCR failed, no comps) are NOT auto-saved

### Two-Photo Option
If OCR detects a tag successfully, the compact card includes a subtle "Add item photo" option. This is optional — many users will skip it in rapid-scan mode. The item photo improves visual matching accuracy but is not required.

### Timing
- Capture → compact card visible: ~1-2 seconds
- Camera stays live throughout — user can scan next item immediately

---

## Gap 3: Onboarding Quiz

The app needs to personalize the experience from the first launch. A 3-question quiz replaces static info screens — it collects actionable data while teaching the user what the app does.

**Answer:**

### 3-Question Quiz + Camera Permission

**Screen 1: "What's your experience level?"**
- Title: "How long have you been reselling?" — `TFFont.title1`
- 3 options, large tappable cards (`TFColor.cardSurface`, `TFRadius.large`):
  - **"Just starting out"** → `beginner` — App shows simplified UI: big buy signal, minimal stats
  - **"I've sold a few things"** → `intermediate` — Signal + key stats (sell-through, profit)
  - **"I do this regularly"** → `expert` — Full data: all stats, all platforms, comps
- Selection highlights card with `TFColor.gainGreen` border

**Screen 2: "What's your minimum profit?"**
- Title: "What profit makes a find worth it?" — `TFFont.title1`
- Subtitle: "We'll flag anything below this as a pass" — `TFFont.body`, `TFColor.textSecondary`
- Preset buttons in a row: `$5` `$10` `$15` `$20` `$25`
- `$10` is pre-selected (default)
- Custom input option below: "Other: $[___]" — `TextField`, `.keyboardType(.numberPad)`

**Screen 3: "Where do you shop?"**
- Title: "What kind of stores do you visit?" — `TFFont.title1`
- Subtitle: "This helps us estimate your costs" — `TFFont.body`, `TFColor.textSecondary`
- Options (multi-select, checkmark cards):
  - **Goodwill** (~$7 avg) → `defaultCostEstimate: 7.00`
  - **Salvation Army** (~$5 avg) → `defaultCostEstimate: 5.00`
  - **Consignment shops** (~$12 avg) → `defaultCostEstimate: 12.00`
  - **Vintage stores** (~$15 avg) → `defaultCostEstimate: 15.00`
  - **Garage sales** (~$3 avg) → `defaultCostEstimate: 3.00`
- If multiple selected, use average. Primary selection shown in parentheses.
- "I'll enter prices manually" option at bottom → `custom` store type

**Screen 4: Camera Permission**
- Hero: SF Symbol `camera.fill` at 64pt, `TFColor.gainGreen`
- Title: "One last thing — camera access" — `TFFont.title1`
- Body: "ThriftFlip needs your camera to scan clothing tags. Photos are processed on your device." — `TFFont.body`, `TFColor.textSecondary`
- CTA: `ActionButton(.primary, "Enable Camera")` → triggers `AVCaptureDevice.requestAccess(for: .video)`
- Secondary: `ActionButton(.text, "Maybe Later")` → skips, user can enable in Settings later

### Navigation
- Horizontal paged scroll (`TabView` with `.page` style)
- Progress dots at bottom, `TFColor.gainGreen` active, `TFColor.textTertiary` inactive
- "Skip" text button top-right on screens 1-3 (uses defaults if skipped)
- After screen 4 (or skip): save quiz answers to `UserSettings`, navigate to main `TabView`, set `UserDefaults.hasCompletedOnboarding = true`

### Data Flow
- Quiz answers write directly to `UserSettings` (local SwiftData + server sync)
- `experienceLevel` controls progressive disclosure throughout the app
- `minProfitDollars` feeds into the buy/pass signal algorithm
- `storeType` + `defaultCostEstimate` replaces per-scan thrift price input

### When shown
- Only on first launch (`!UserDefaults.hasCompletedOnboarding`)
- Never shown again after completion or skip
- All values editable later in Settings

---

## Gap 4: Paywall/Upgrade Flow

The UI/UX plan defines `PaywallPlanCard` component but doesn't specify when/where the paywall appears.

**Answer:**

### Trigger Points (in priority order)

1. **Scan limit reached:** When user attempts 6th scan of the day → full-screen paywall sheet
2. **Save to collection prompt:** After 3+ scans (anonymous user) → "Sign in to save" sheet with upgrade upsell below
3. **Sell tab first tap:** If user is on free tier → inline paywall card at top of Sell tab
4. **Settings:** "Upgrade to Pro" row always visible in settings/profile sheet

### Paywall Screen Layout

```
[Close X button — top right, 44x44pt target]

[Title: "Unlock Unlimited Scans" — TFFont.title1, centered]
[Subtitle: "Find more deals, save more money" — TFFont.body, TFColor.textSecondary, centered]

[Spacing: TFSpacing.xl (32pt)]

[PaywallPlanCard — Free tier]
[Spacing: TFSpacing.md (16pt)]
[PaywallPlanCard — Pro tier, selected by default, "Most Popular" badge]

[Spacing: TFSpacing.xl (32pt)]

[ActionButton(.primary, "Start Free Trial") — full width]
[Spacing: TFSpacing.sm (8pt)]
["Restore Purchases" — ActionButton(.text), TFFont.caption, TFColor.textSecondary]

[Spacing: TFSpacing.sm (8pt)]
[Legal: "Cancel anytime. Terms & Privacy" — TFFont.micro, TFColor.textTertiary, centered]
```

### Free vs. Pro Features

| Feature | Free | Pro |
|---|---|---|
| Daily scans | 5 | Unlimited |
| Save to collection | Yes (up to 20) | Unlimited |
| Price range + confidence | Yes | Yes |
| Comparable listings | Top 3 | All comps |
| Correction/re-price | Yes | Yes |
| eBay listing draft | No | Yes |
| Priority processing | No | Yes |

### StoreKit Integration
- Use StoreKit 2 (`Product`, `Transaction`)
- Product IDs: `com.thriftflip.pro.monthly`, `com.thriftflip.pro.yearly`
- Price: TBD (placeholder $4.99/mo, $29.99/yr in UI, fetched from StoreKit at runtime)
- Entitlement check: `Transaction.currentEntitlements` on app launch, cache result

### Presentation
- `.sheet` presentation with `presentationDetents([.large])`
- `.interactiveDismissDisabled(false)` — user can always dismiss
- Animation: slide up from bottom (default sheet)

---

## Gap 5: Offline Behavior

Not addressed in any doc. Critical for a thrift store app (stores often have poor signal).

**Answer:**

### Design Principle
The app should be **usable offline for everything except pricing.** On-device ML runs without network. Pricing requires the backend.

### Offline States by Feature

| Feature | Offline Behavior |
|---|---|
| **Camera** | Works fully (no network needed) |
| **On-device OCR/YOLO/CLIP** | Works fully (models are on-device) |
| **Scan → pricing** | Fails gracefully — show "No connection" error state with "Retry" button |
| **View collection** | Works — collection is cached locally (Core Data or SwiftData) |
| **View saved scan details** | Works — full ScanResult cached locally |
| **Correction** | Queue offline — submit when connection returns |
| **Paywall/purchase** | StoreKit handles offline gracefully (transactions sync when online) |

### Network Detection
```swift
import Network

// NWPathMonitor on a background queue
// Expose via @Observable NetworkMonitor service
// Properties: isConnected: Bool, connectionType: NWInterface.InterfaceType?
```

### Offline Queue for Corrections
- Store pending corrections in local persistence (SwiftData)
- On app foreground + network available: retry all pending corrections
- Show badge on collection item: "Correction pending" — `TFFont.micro`, `TFColor.gold`

### Scan Offline Flow
1. User taps scan → Camera captures → On-device pipeline runs successfully
2. Network request fails → Show `ErrorStateCard` variant: "No connection — we need internet to check prices. Your scan is saved and we'll price it when you're back online."
3. Save partial scan locally (images + OCR results, no pricing)
4. When online: show banner "1 scan ready to price" → tap to submit → normal result flow

---

## Gap 6: Local Persistence / Caching Strategy

No doc specifies how data is cached on-device.

**Answer:**

### Technology: SwiftData (iOS 17+)

SwiftData over Core Data because: native Swift, simpler API, works with @Observable, built-in CloudKit sync path for future.

### What's Persisted Locally

| Data | Storage | TTL | Size Estimate |
|---|---|---|---|
| Collection items (ScanResult) | SwiftData | Forever (until deleted) | ~2KB per item |
| Scan images (tag + item) | File system (`/Documents/scans/`) | Forever (until deleted) | ~200KB per image |
| Thumbnails | File system (`/Caches/thumbnails/`) | System-managed cache eviction | ~15KB each |
| Pending corrections (offline queue) | SwiftData | Until submitted | ~500B each |
| Onboarding state | UserDefaults | Forever | Trivial |
| Auth tokens | Keychain (via Supabase SDK) | Managed by SDK | Trivial |
| Scan quota remaining | UserDefaults (synced from server) | Until next server response | Trivial |
| Brand/RN lookup database | Bundled SQLite (read-only) | App update cycle | ~5MB |

### Cache Keys for Network Responses

No aggressive caching of API responses (eBay legal constraint — can't store eBay data long-term).

| Response | Cache | TTL |
|---|---|---|
| Scan result | Persisted to SwiftData on save | Permanent |
| Comp listings | Persisted with scan result on save | Permanent (snapshot) |
| Active listing prices | NOT cached separately | N/A |
| Presigned upload URLs | In-memory only | 5 min (matches URL expiry) |
| User profile | In-memory `@Observable` | Session lifetime |

### Image Caching
- Use `AsyncImage` with system URL cache for comp listing thumbnails
- For user's own scan images: stored locally in `/Documents/scans/{scanId}/`
- Filename pattern: `{scanId}_tag.jpg`, `{scanId}_item.jpg`, `{scanId}_thumb.jpg`

---

## Gap 7: Info.plist / Entitlements / Permissions

No doc specifies required permissions.

**Answer:**

### Info.plist Keys

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>ThriftFlip needs your camera to scan clothing tags and items for price estimates.</string>

<!-- Photo Library (for gallery import) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>ThriftFlip can import photos of clothing tags from your photo library.</string>
```

### Capabilities (Xcode Signing & Capabilities)

1. **Sign in with Apple** — Required for auth upgrade flow
2. **In-App Purchase** — Required for Pro subscription
3. **Background Modes** — None needed for MVP
4. **Push Notifications** — Not in MVP

### No Additional Entitlements Needed
- No HealthKit, Location, Contacts, Microphone, etc.
- Network access is implicit (no entitlement needed)

---

## Gap 8: Swift Package Manager Dependencies

No doc lists required packages.

**Answer:**

### Required SPM Packages

| Package | URL | Use | Version |
|---|---|---|---|
| **supabase-swift** | `https://github.com/supabase/supabase-swift` | Auth + DB client | Latest stable |

### Built-in Frameworks (No SPM Needed)

| Framework | Use |
|---|---|
| `AVFoundation` | Camera capture |
| `Vision` | OCR (`VNRecognizeTextRequest`) |
| `CoreML` | YOLOv8n + MobileCLIP inference |
| `Charts` | PriceHistoryChart |
| `SwiftData` | Local persistence |
| `StoreKit` | In-app purchases |
| `Network` | Connectivity monitoring (`NWPathMonitor`) |
| `AuthenticationServices` | Sign in with Apple |

### NOT Using (Intentional)
- No Alamofire (use native `URLSession`)
- No Kingfisher/SDWebImage (use native `AsyncImage` + URL cache)
- No Combine (use async/await)
- No third-party chart libraries (use Swift Charts)
- No Firebase (use Supabase)

---

## Gap 9: Navigation Architecture

CLAUDE.md says "NavigationStack with typed routes" but no route enum is defined.

**Answer:**

### Route Definition

```swift
enum AppTab: String, CaseIterable, Identifiable {
    case scan
    case collection
    case sell

    var id: String { rawValue }
}

// Collection tab navigation
enum CollectionRoute: Hashable {
    case itemDetail(scanId: String)
    case correction(scanId: String)
}

// Sell tab navigation
enum SellRoute: Hashable {
    case listingDraft(scanId: String)
}
```

### App-Level Navigation State

```swift
@Observable
final class AppRouter {
    var selectedTab: AppTab = .scan
    var collectionPath = NavigationPath()
    var sellPath = NavigationPath()
    var showPaywall = false
    var showOnboarding = false
    var showSettings = false
}
```

### Sheet Presentations (not in NavigationStack)

| Sheet | Trigger | Detents |
|---|---|---|
| ResultBottomSheet | Scan completes | `.height(380)`, `.large` |
| PaywallSheet | Scan limit, sell tab, settings | `.large` |
| SettingsSheet | Profile icon tap | `.medium`, `.large` |
| OnboardingSheet | First launch | `.large`, non-dismissible |

---

## Gap 10: Error Copy for All States

The UI/UX plan requires 7 error states but only `EmptyStateCard` defines copy. Here's the complete copy table.

**Answer:**

| State | Icon | Title | Message | Primary Action | Secondary |
|---|---|---|---|---|---|
| **Empty collection** | `square.stack` | "No finds yet" | "Scan a tag and save it to start your collection." | "Scan Now" → switch to scan tab | — |
| **Loading** | — | — | — | Skeleton placeholders | — |
| **OCR failed** | `text.viewfinder` | "Couldn't read the tag" | "Make sure the tag text is visible and well-lit, then try again." | "Rescan" | "Try without tag" |
| **No comps** | `magnifyingglass` | "No comparables found" | "We couldn't find similar listings for this item." | "Edit & Retry" → correction flow | "Save Anyway" |
| **Network failure** | `wifi.slash` | "No connection" | "Check your internet connection and try again." | "Retry" | — |
| **Timeout** | `clock.arrow.circlepath` | "Taking too long" | "The search is taking longer than expected. Try again." | "Retry" | "Cancel" |
| **Rate limited** | `lock.fill` | "Daily limit reached" | "You've used all 5 free scans today. Upgrade for unlimited scans." | "Upgrade" → paywall | "OK" (dismiss) |
| **Camera denied** | `camera.fill` | "Camera access needed" | "Go to Settings > ThriftFlip > Camera to enable scanning." | "Open Settings" → `UIApplication.open(settingsURL)` | — |
| **Server error** | `exclamationmark.triangle.fill` | "Something went wrong" | "We hit an unexpected error. Please try again." | "Retry" | "Report Issue" |
| **Scan processing** | `sparkles` | — | "Analyzing tag..." → "Finding comparables..." → "Calculating estimate..." | — | "Cancel" |

### Processing State Copy Progression
The scanning state cycles through 3 messages to indicate progress:
1. 0-1s: "Analyzing tag..."
2. 1-3s: "Finding comparables..."
3. 3s+: "Calculating estimate..."

Each transition uses `.transition(.opacity)` with 0.3s animation.

---

## Gap 11: Testing Framework

The build checklist includes an evaluation harness but no testing framework is chosen.

**Answer:**

### Unit Testing
- **Framework:** XCTest (built-in)
- **Target:** `ThriftFlipTests` (auto-created by Xcode)
- **What to test:** Models (JSON decoding), PricingConfig constants, confidence tier logic, number formatting, network request construction

### UI Testing
- **Framework:** XCTest UI Testing (built-in)
- **Target:** `ThriftFlipUITests`
- **What to test:** Onboarding flow, tab navigation, scan button states, result sheet appearance
- **NOT in MVP:** Snapshot testing, performance testing

### Preview Testing
- Every view has a SwiftUI Preview with mock data
- Use the 3 mock items from `api-contract.md` as preview data

### Backend Testing (Python)
- pytest + httpx (async test client for FastAPI)
- Separate concern — not part of iOS project

---

## Gap 12: Confidence Threshold Mismatch

`CLAUDE.md` defines confidence tiers as High 75-100, Medium 50-74, Low 0-49.
`backend-scanner-spec.md` defines them as High 80-100, Medium 55-79, Low 30-54, Insufficient 0-29.

**Answer:** Use the `backend-scanner-spec.md` values. They are more nuanced (4 tiers vs 3) and match the research.

**Update CLAUDE.md** to match:

```
| Level | Score | Color | Copy Style |
|-------|-------|-------|-----------|
| High | 80-100 | gainGreen | Direct: "Patagonia Better Sweater" |
| Medium | 55-79 | gold | Hedged: "Likely a Patagonia Better Sweater" |
| Low | 30-54 | warning | Cautious: "This might be..." + suggest rescan |
| Insufficient | 0-29 | textTertiary | "Not enough data" + offer manual entry |
```

**Update ConfidenceLevel enum** to add `.insufficient`:

```swift
enum ConfidenceLevel: String, Codable {
    case high         // 80-100
    case medium       // 55-79
    case low          // 30-54
    case insufficient // 0-29
}
```

---

---

## Gap 13: Sold vs Active Price Separation in UI

Research finding: Resellers trust sold prices far more than active listings. The original plan blended them together.

**Answer:**

### UI Layout (Result Screen)

```
┌─────────────────────────────────────────┐
│  SOLD PRICES (Primary — shown first)    │
│  ┌─────────────────────────────────────┐│
│  │ $42 ──────── $67.50 ──────── $95   ││
│  │ low         median           high   ││
│  │ Based on 34 recent sales            ││
│  └─────────────────────────────────────┘│
│                                         │
│  ASKING PRICES (Secondary)              │
│  ┌─────────────────────────────────────┐│
│  │ $55 ──────── $79.99 ──────── $125  ││
│  │ 13 active listings                  ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Design Rules

1. **Sold range** uses full `PriceRangeView` component with `TFFont.display` for median
2. **Active range** uses compact variant: single line, `TFFont.body`, `TFColor.textSecondary`
3. If no sold data: active range becomes primary with caveat copy (see Gap 4, Q4)
4. Comp list is filterable: "Sold" | "Active" | "All" chips using `FilterChip` component
5. Sold comps default to sorted by date (newest first), active by price (lowest first)

### Data Shape

The `ScanResult.pricingBreakdown` replaces the old `priceRange`:

```swift
// OLD (removed):
// let priceRange: PriceRange

// NEW:
let pricingBreakdown: PricingBreakdown
// .sold — primary display (nullable if no sold data)
// .active — secondary display (nullable if no active data)
// .combined — fallback when sold is sparse
```

---

## Gap 14: Cost Estimation + Profit Calculator

The cost to acquire an item comes from the user's store type (set in onboarding quiz), not per-scan input. This eliminates friction during rapid scanning while still providing accurate profit estimates.

**Answer:**

### How Cost Is Determined

1. **Default path (zero friction):** User's `storeType` from onboarding quiz maps to a `defaultCostEstimate`:
   - Goodwill → $7.00
   - Salvation Army → $5.00
   - Consignment → $12.00
   - Vintage → $15.00
   - Garage sale → $3.00
   - Custom → user-set value

2. **Override path (optional):** In the expanded detail card or in My Finds, user can tap the cost amount to edit it for that specific item. This updates `purchasePrice` on the item.

3. **Server-side:** The `defaultCostEstimate` from user settings is used for all profit calculations and buy signal computation. No thrift price field on the scan request.

### Profit Display (Always Visible)

Since cost is always known (from settings default), profit is shown immediately on every result — no "enter price" step needed:

```
┌────────────────────────────────────┐
│  ~$43 profit on eBay               │  ← Compact card (in-store)
└────────────────────────────────────┘

┌────────────────────────────────────┐
│  Estimated cost: $7.00 (Goodwill)  │  ← Expanded card, tappable to edit
│                                    │
│  Best profit: $49.77 on Depop      │
│  ROI: 611%                         │
│  ──────────────────────────────    │
│  Depop:    $49.77 profit  ★ Best   │
│  Whatnot:  $46.60 profit           │
│  Poshmark: $46.00 profit           │
│  Mercari:  $45.25 profit           │
│  eBay:     $43.06 profit           │
└────────────────────────────────────┘
```

### Design Details

- **Cost line:** Shows `"Estimated cost: $X.XX (Store Type)"` — `TFFont.caption`, `TFColor.textSecondary`
- **Tappable cost:** Tap to override with a specific price for this item. Shows `TextField`, `.keyboardType(.decimalPad)`
- **Profit colors:** Positive profit in `TFColor.gainGreen`, negative in `TFColor.warning`
- **Best platform:** marked with star icon, `TFColor.gold`, sorted first
- **Client-side recalculation:** When user edits cost, `netAfterCost = netProfit - newCost` for each platform — instant, no server call

### When User Has Custom Store Type

- If store type is `custom`, the default cost estimate is whatever they set in settings
- Prompt in settings: "What do you typically pay per item?" with dollar input

---

## Gap 15: Buy/Pass Traffic Light Signal

Research finding: The #1 killer feature. No competing app provides a sub-5-second buy/pass decision. This is the core differentiator.

**Answer:**

### Visual Design

```
┌─────────────────────────────────────┐
│                                     │
│        🟢  GOOD BUY                │
│                                     │
│  High sell-through (72%)            │
│  Strong margins on all platforms    │
│                                     │
└─────────────────────────────────────┘
```

### Component: `BuySignalView`

```swift
// BuySignalView.swift
// Top of result sheet, immediately visible

struct BuySignalView: View {
    let signal: BuySignal

    // Signal circle: 64pt diameter
    // GREEN: TFColor.gainGreen, filled circle
    // YELLOW: TFColor.gold, filled circle
    // RED: TFColor.warning, filled circle

    // Label below circle:
    // GREEN: "Good Buy" — TFFont.headline, TFColor.gainGreen
    // YELLOW: "Maybe" — TFFont.headline, TFColor.gold
    // RED: "Pass" — TFFont.headline, TFColor.warning

    // Reason text: TFFont.caption, TFColor.textSecondary
    // ROI (if available): TFFont.title2, below signal
}
```

### Signal Algorithm (Server-Side)

See `backend-scanner-spec.md` Section 5.10 for the full algorithm. Summary:

| Condition | Signal | Copy |
|-----------|--------|------|
| High sell-through + meets profit threshold + medium+ confidence | GREEN | "Good buy" |
| Moderate sell-through OR tight margins OR no thrift price | YELLOW | "Maybe" |
| No sales found OR below profit threshold OR low confidence | RED | "Pass" |
| Insufficient confidence (score < 30) | RED (forced) | "Not enough data to decide" |

Note: "profit threshold" uses the user's `minProfitDollars` from settings (set in onboarding quiz). Cost estimate comes from `defaultCostEstimate` (store type), not per-scan input.

### Placement in Result Sheet

The buy signal is the **first thing the user sees** when results appear:

```
[ResultBottomSheet]
  1. BuySignalView (green/yellow/red circle + label + reason)
  2. ROI / profit summary (always visible — cost from settings)
  3. PricingBreakdown (sold range primary, active secondary)
  4. MarketInsights (sell-through, days to sell, demand)
  5. PlatformComparison (fee-adjusted net per platform)
  6. CompList (filterable sold/active)
  7. ConfidenceBadge + factors
  8. Action buttons (Correct, Share)
```

---

## Gap 16: Multi-Platform Fee Comparison UI

Research finding: Resellers sell on multiple platforms and choose based on net profit. Showing fee-adjusted prices across all 5 platforms requires zero new data — just math.

**Answer:**

### Component: `PlatformComparisonView`

```
┌─────────────────────────────────────┐
│  Where to Sell                      │
│                                     │
│  Depop        $49.77 profit  ★ Best │
│  3.3% fee · $7.50 shipping          │
│                                     │
│  Whatnot      $46.60 profit         │
│  8% fee · $7.50 shipping            │
│                                     │
│  Poshmark     $46.00 profit         │
│  20% fee · free shipping            │
│                                     │
│  Mercari      $45.25 profit         │
│  10% fee · $7.50 shipping           │
│                                     │
│  eBay         $43.06 profit         │
│  13.25% fee · $7.50 shipping        │
└─────────────────────────────────────┘
```

### Design Rules

1. Sorted by `netAfterCost` descending (best profit first). If no cost estimate, sort by `netProfit`.
2. Best platform gets `★` icon in `TFColor.gold` and bold font
3. Platform name: `TFFont.headline`
4. Profit amount: `TFFont.headline`, `TFColor.gainGreen` (or `TFColor.warning` if negative)
5. Fee/shipping line: `TFFont.micro`, `TFColor.textTertiary`
6. If user has `preferredPlatforms` in settings, non-preferred platforms are collapsed under "Show more" toggle
7. Poshmark shows "free shipping" since shipping is baked into buyer cost

---

## Gap 17: Market Insights UI

Research finding: Sell-through rate is what makes resellers trust a price estimate. "Does this item actually sell?" is more important than "what does it sell for?"

**Answer:**

### Component: `MarketInsightsView`

```
┌─────────────────────────────────────┐
│  Market Data                        │
│                                     │
│  72%          8 days       Stable   │
│  sell-through avg to sell  demand   │
│                                     │
│  34 sold · 13 listed (last 90 days) │
└─────────────────────────────────────┘
```

### Design Rules

1. Three stat blocks in a row using `StatCard`-style layout
2. **Sell-through rate:** Large number (`TFFont.title2`), colored by demand level:
   - High (>=65%): `TFColor.gainGreen`
   - Moderate (35-64%): `TFColor.gold`
   - Low (<35%): `TFColor.warning`
3. **Avg days to sell:** `TFFont.title2`, `TFColor.textPrimary`. Shows "—" if no sold data
4. **Volume trend:** Icon + label
   - Rising: `arrow.up.right` + "Rising" in `TFColor.gainGreen`
   - Stable: `arrow.right` + "Stable" in `TFColor.textSecondary`
   - Declining: `arrow.down.right` + "Declining" in `TFColor.warning`
5. Summary line: `TFFont.micro`, `TFColor.textTertiary`

### When Market Data is Sparse

| Situation | Behavior |
|-----------|----------|
| 0 sold, only active | Show sell-through as "0%" in `TFColor.warning`, days to sell as "—", trend as "—" |
| No data at all | Don't show `MarketInsightsView` at all |
| < 5 total comps | Show with caveat: "Limited data" badge |

---

## Gap 18: User Settings System

Research finding: Every reseller has different profit thresholds, preferred platforms, and shipping costs. The app needs to be personalized.

**Answer:**

### Settings Screen (Profile Sheet)

```
┌─────────────────────────────────────┐
│  Settings                    [Done] │
│                                     │
│  PROFIT THRESHOLD                   │
│  ┌─────────────────────────────────┐│
│  │ Minimum profit per item         ││
│  │ [$ 10.00           ] ▼ Dollars  ││
│  └─────────────────────────────────┘│
│                                     │
│  PREFERRED PLATFORMS                │
│  ┌─────────────────────────────────┐│
│  │ ☑ eBay                          ││
│  │ ☑ Poshmark                      ││
│  │ ☐ Mercari                       ││
│  │ ☑ Depop                         ││
│  │ ☐ Whatnot                       ││
│  └─────────────────────────────────┘│
│                                     │
│  SHIPPING COSTS                     │
│  ┌─────────────────────────────────┐│
│  │ Clothing      $ 7.50            ││
│  │ Shoes         $ 12.00           ││
│  │ Heavy items   $ 15.00           ││
│  │ Accessories   $ 5.00            ││
│  └─────────────────────────────────┘│
│                                     │
│  DISPLAY                            │
│  ┌─────────────────────────────────┐│
│  │ Show prices from: [Sold ▼]      ││
│  │ Show all platforms: [ON]        ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### Data Flow

1. Settings stored locally (SwiftData) and synced to server (`PUT /api/v1/settings`)
2. On scan, settings are sent with the request OR applied client-side to the response
3. Buy signal uses user's profit threshold (not a hardcoded default)
4. Platform comparison filters/sorts by preferred platforms
5. Shipping costs use user's configured values per garment type

### Default Values (No Setup Required)

The app works immediately with sensible defaults:
- Profit threshold: $10 minimum
- Preferred platforms: eBay, Poshmark
- Shipping: clothing $7.50, shoes $12, heavy $15, accessories $5
- Show sold prices by default, show all platforms

### When Settings Change

- Changes apply immediately to the current session
- Saved scans in collection are NOT retroactively recalculated (they show what was current at scan time)
- "Re-evaluate" button on saved items lets users recalculate with current settings

---

## Gap 19: Item States (Scanned → Bought)

Every scan auto-saves. Users categorize items into two states. No "collections" table — items ARE the library.

**Answer:**

### Two States for MVP

| State | Meaning | How It Happens |
|-------|---------|----------------|
| `scanned` | Saw it in store, got pricing data | Automatic on every successful scan |
| `bought` | Actually purchased the item | User taps "I Bought This" in My Finds |

### State Transitions

```
[Scan] ──auto-save──> [scanned] ──user action──> [bought]
                                                     │
                                           (optional: enter actual purchase price)
```

### "I Bought This" Flow

1. User views item in My Finds → taps item → expanded detail
2. Taps "I Bought This" button (prominent, `TFColor.gainGreen` outline)
3. Optional: enter actual purchase price (pre-filled with `defaultCostEstimate`)
4. Item moves to "Bought" section, purchase price saved
5. Item now contributes to portfolio calculations in Sell tab

### UI in My Finds

```
┌─────────────────────────────────────┐
│  My Finds                    [⚙️]  │
│                                     │
│  SCANNED (14 items)                 │
│  ┌─────────────────────────────────┐│
│  │ 🟢 Patagonia Sweater · $67.50  ││
│  │ 🟡 Nike Windbreaker · $42.00   ││
│  │ 🔴 H&M Blazer · $15.00        ││
│  └─────────────────────────────────┘│
│                                     │
│  BOUGHT (3 items)                   │
│  ┌─────────────────────────────────┐│
│  │ Patagonia Fleece · Paid $8      ││
│  │   Est. profit: $41 on eBay     ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### Data Model

- `ScanResult.status: ItemStatus` — `.scanned` or `.bought`
- `ScanResult.purchasePrice: Double?` — nil for scanned, set when marked as bought
- No separate collections table — the `scans` table IS the library
- Filter by status in My Finds view

---

## Gap 20: Haul Grouping

Scans done on the same day are auto-grouped into a "haul" for easy review.

**Answer:**

### Auto-Grouping Logic

- Group items by scan date (calendar day, local timezone)
- No manual haul creation — purely date-based
- Section headers in My Finds: "Today", "Yesterday", "Feb 14", etc.

### My Finds Layout

```
┌─────────────────────────────────────┐
│  SCANNED                           │
│                                     │
│  Today (3 items)                    │
│  ├── 🟢 Patagonia Sweater · $67   │
│  ├── 🟡 Nike Windbreaker · $42    │
│  └── 🔴 H&M Blazer · $15         │
│                                     │
│  Yesterday (5 items)                │
│  ├── 🟢 Levi's 501 · $45          │
│  └── ... 4 more                    │
│                                     │
│  Feb 12 (2 items)                   │
│  └── ...                           │
└─────────────────────────────────────┘
```

### Design Rules

1. Date sections use `TFFont.caption`, `TFColor.textSecondary`
2. Item count in parentheses
3. Sections are collapsible (tap header to toggle)
4. Most recent haul expanded by default, older collapsed
5. Bought items section is NOT grouped by date — flat list sorted by purchase date

---

## Gap 21: Portfolio Dashboard

The Sell tab opens with a Robinhood-style portfolio summary showing total investment vs potential value.

**Answer:**

### Portfolio Summary (Top of Sell Tab)

```
┌─────────────────────────────────────┐
│  Your Portfolio                     │
│                                     │
│  $287.00                            │
│  potential profit                   │
│  ▲ 412% ROI                        │
│                                     │
│  Invested: $56.00 (8 items)         │
│  Potential value: $343.00           │
└─────────────────────────────────────┘
```

### Calculation

Only `bought` items contribute to portfolio:
- `totalInvested` = sum of `purchasePrice` for all bought items
- `totalPotentialValue` = sum of `bestNetProfit + purchasePrice` for each bought item (what they'd get after selling)
- `totalPotentialProfit` = `totalPotentialValue - totalInvested`
- `averageROI` = `(totalPotentialProfit / totalInvested) * 100`

### Design Rules

1. Potential profit is the hero number — `TFFont.display`, `TFColor.gainGreen` (or `TFColor.warning` if negative)
2. ROI percentage below in `TFFont.headline`
3. Invested / value line in `TFFont.caption`, `TFColor.textSecondary`
4. Card uses `TFColor.cardSurface` background, `TFRadius.large`
5. If no bought items: "Mark items as bought to see your portfolio" — empty state

### Below Portfolio

List of bought items, each showing:
- Item name + brand
- Purchase price → estimated sell price
- Best platform for this item
- "Create Listing" button (→ listing flow)

---

## Gap 22: eBay Listing Flow

Users can generate AI-drafted eBay listings for their bought items. Scan photos are NOT used — users take new product photos at home.

**Answer:**

### Flow

1. **User taps "Create Listing"** on a bought item in Sell tab
2. **AI generates draft:** Title, description, category, condition, suggested price — all from scan data
3. **Draft review screen** shows the generated listing with editable fields
4. **"Add Photos" section** at top — prominent, empty state:
   ```
   ┌─────────────────────────────────────┐
   │  📸 Add Product Photos             │
   │                                     │
   │  [Front] [Back] [Tag] [Details]     │
   │   empty   empty  empty  empty       │
   │                                     │
   │  Tip: Good photos sell faster.      │
   │  Take them at home with good light. │
   └─────────────────────────────────────┘
   ```
5. **User takes/selects photos** → stored as listing photos (separate from scan images)
6. **"Publish to eBay"** button at bottom → calls eBay Trading API
7. **Success state:** "Listed on eBay!" with link to view listing

### Why Not Use Scan Photos

Scan photos are taken quickly in-store (bad lighting, cluttered background, often just the tag). Product photos for selling need:
- Clean background
- Good lighting
- Multiple angles (front, back, tag, detail/flaw)
- This is standard reseller practice — every guide says "take good photos"

### Listing Draft Data Shape

```swift
struct ListingDraft: Codable, Identifiable {
    let id: String
    let itemId: String
    let platform: String           // "ebay" for MVP
    var title: String              // AI-generated from scan
    var description: String        // AI-generated
    var category: String           // eBay category from scan
    var condition: String          // Pre-owned (default)
    var suggestedPrice: Double     // From pricing data
    var photos: [String]           // URLs — empty on creation
    var status: ListingStatus      // draft → needsPhotos → ready → published
    let createdAt: Date
}

enum ListingStatus: String, Codable {
    case draft          // Just created
    case needsPhotos    // Draft reviewed, no photos yet
    case ready          // Has photos, ready to publish
    case published      // Live on eBay
}
```

### MVP Scope

- **In MVP:** AI draft generation, photo capture UI, eBay publish
- **Build now, connect later:** If eBay API keys aren't approved yet, build the full UI with mock publish. Hook up real API when keys arrive.
- **eBay only:** Other platforms deferred

---

## Gap 23: Compact Card UX (Apple-Style Sheet)

The scan result card uses iOS native sheet presentation with spring physics for a polished, Apple-quality feel.

**Answer:**

### Implementation

```swift
.sheet(isPresented: $showResult) {
    ResultCardView(result: scanResult)
        .presentationDetents([.height(280), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(TFRadius.large)
        .presentationBackgroundInteraction(.enabled(upThrough: .height(280)))
}
```

### Key Behaviors

1. **Compact state (`.height(280)`):** Shows buy signal, item name, price, profit — the "in-store glance"
2. **Expanded state (`.large`):** Full detail view with all pricing, market data, comps, platform comparison
3. **Camera stays interactive** behind compact card (`.presentationBackgroundInteraction(.enabled)`)
4. **Drag indicator** visible at top for affordance
5. **Swipe down from compact** → dismisses card entirely, camera is full screen again
6. **Drag up from compact** → expands to full detail
7. **New scan while card is showing** → replaces card content (previous item auto-saved)

### Compact Card Layout (280pt)

```
┌─────────────────────────────────────┐
│  ─── (drag indicator)               │
│                                     │
│  🟢  Good Buy                      │  ← Signal circle (32pt) + label
│                                     │
│  Patagonia Better Sweater           │  ← TFFont.headline
│  $67.50 median                      │  ← TFFont.title2, sold price
│                                     │
│  ~$43 profit on eBay                │  ← TFFont.caption, TFColor.gainGreen
│  High confidence · 72% sell-through │  ← TFFont.micro, TFColor.textSecondary
└─────────────────────────────────────┘
```

### Animation

- Default iOS sheet spring animation (no custom springs needed)
- Card appears with standard sheet slide-up
- Content within card fades in: signal first (0ms), then details (100ms delay)

### Experience Level Adaptation

| Level | Compact Card Shows |
|-------|-------------------|
| Beginner | Signal + item name + "Worth buying" / "Skip it" |
| Intermediate | Signal + item name + price + profit |
| Expert | Signal + item name + price + profit + confidence + sell-through |

---

## Summary: All 23 Gaps Resolved

| # | Gap | Resolution |
|---|---|---|
| 1 | Open questions from risk doc | 4 sub-questions resolved (confidence, comps, corrections, copy) |
| 2 | Rapid-scan camera flow | Compact card over live camera, auto-save, never leave viewfinder |
| 3 | Onboarding quiz | 3-question quiz (experience, profit, store type) + camera permission |
| 4 | Paywall/upgrade flow | Scan limit, 3+ scans (anon), sell tab, settings |
| 5 | Offline behavior | On-device works, pricing fails gracefully, offline queue |
| 6 | Local persistence | SwiftData + file system, no aggressive API caching |
| 7 | Permissions/entitlements | Camera, photo library, Sign in with Apple, IAP |
| 8 | SPM dependencies | Only supabase-swift; everything else is built-in |
| 9 | Navigation routes | Typed enums + AppRouter @Observable |
| 10 | Error copy | Complete copy table for all 9 states |
| 11 | Testing framework | XCTest (unit + UI), previews with mock data |
| 12 | Confidence tier mismatch | Use 4-tier system from backend spec |
| 13 | Sold vs active separation | Sold primary, active secondary, separate ranges |
| 14 | Cost estimation + profit calc | Cost from store type (quiz), override per-item, always-visible profit |
| 15 | Buy/Pass traffic light | Green/yellow/red signal, first thing users see |
| 16 | Multi-platform fee comparison | 5 platforms sorted by net profit, zero new data |
| 17 | Market insights UI | Sell-through rate, days to sell, volume trend |
| 18 | User settings system | Profit threshold, platforms, shipping, display prefs |
| 19 | Item states | Two states: scanned (auto) → bought (user action), no collections table |
| 20 | Haul grouping | Auto-group by scan date, collapsible sections in My Finds |
| 21 | Portfolio dashboard | Robinhood-style invested vs potential value, top of Sell tab |
| 22 | eBay listing flow | AI draft, separate product photos, publish via Trading API |
| 23 | Compact card UX | iOS sheet with `.presentationDetents`, spring animation, experience-level adaptation |

**The project is now fully specified. Zero ambiguity remains for the build.**
