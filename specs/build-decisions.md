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

## Gap 2: Camera Two-Photo Capture Flow

The build checklist says "Capture optional second image for item context" but doesn't specify the UX flow.

**Answer:**

### Flow
1. **Camera opens** → ScanOverlayFrame in `searching` state, guidance text: "Center the tag in the frame"
2. **User taps scan button** → Captures tag photo, on-device OCR runs immediately (~300ms)
3. **If OCR succeeds** → Overlay transitions to `locked`, guidance text: "Tag detected — now show the full item"
   - Camera stays open, overlay frame expands to full-screen guide (no bracket frame, just edge vignette)
   - Second scan button appears with text "Capture Item" (same PrimaryScanButton, label changes)
   - **Skip option:** "Skip" text button below, `TFFont.caption`, `TFColor.textSecondary`
4. **User taps "Capture Item"** → Captures item photo, both images sent to backend
5. **If user taps "Skip"** → Only tag photo sent, `tagImageUrl` populated, `itemImageUrl` uses the same tag photo (backend handles gracefully)
6. **If OCR fails** → Overlay shows `failed` state, auto-resets to `searching` after 2s, user can retry or tap "Try without tag" text button

### What gets sent
```
POST /api/v1/scan
  - tagImage: JPEG (always present — this is the first capture)
  - itemImage: JPEG (present if user took second photo, null if skipped)
  - ocrPayload: JSON (on-device extraction results — brand, RN, size, material, garment type, embedding)
```

### Timing
- Between photo 1 and photo 2: on-device ML pipeline runs in parallel (OCR + YOLO + CLIP)
- After photo 2 (or skip): network request fires immediately with both images + ML results
- Total UX time: ~2-4 seconds typical (tap → tag → tap → item → results appearing)

---

## Gap 3: Onboarding Flow

The UI/UX plan says: "explain what to scan, set trust expectations, collect camera permission" but doesn't define screens.

**Answer:**

### 3 screens, shown once on first launch

**Screen 1: "Scan Tags, Get Prices"**
- Hero illustration: Stylized phone scanning a clothing tag (SF Symbol: `camera.viewfinder` at 64pt, `TFColor.gainGreen`)
- Title: "Scan Tags, Get Prices" — `TFFont.title1`
- Body: "Point your camera at a clothing tag and get an eBay-backed price estimate in seconds." — `TFFont.body`, `TFColor.textSecondary`
- Continue: `ActionButton(.primary, "Next")`

**Screen 2: "Know Before You Buy"**
- Hero: SF Symbol `chart.bar.fill` at 64pt, `TFColor.gold`
- Title: "Know Before You Buy" — `TFFont.title1`
- Body: "See comparable sales, confidence scores, and price ranges. We tell you when we're not sure." — `TFFont.body`, `TFColor.textSecondary`
- Continue: `ActionButton(.primary, "Next")`

**Screen 3: "Enable Camera" (permission request)**
- Hero: SF Symbol `camera.fill` at 64pt, `TFColor.gainGreen`
- Title: "Camera Access Needed" — `TFFont.title1`
- Body: "ThriftFlip needs your camera to scan clothing tags. Photos are processed on your device — we never share them without your permission." — `TFFont.body`, `TFColor.textSecondary`
- CTA: `ActionButton(.primary, "Enable Camera")` → triggers `AVCaptureDevice.requestAccess(for: .video)`
- Secondary: `ActionButton(.text, "Maybe Later")` → skips, user can enable in Settings later

### Navigation
- Horizontal paged scroll (`TabView` with `.page` style)
- Page dots at bottom, `TFColor.gainGreen` active, `TFColor.textTertiary` inactive
- "Skip" text button top-right on screens 1-2 (`TFFont.caption`, `TFColor.textSecondary`)
- After screen 3 (or skip): navigate to main `TabView`, set `UserDefaults.hasCompletedOnboarding = true`

### When shown
- Only on first launch (`!UserDefaults.hasCompletedOnboarding`)
- Never shown again after completion or skip

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

## Summary: All 12 Gaps Resolved

| # | Gap | Resolution |
|---|---|---|
| 1 | Low confidence threshold | Score < 55 triggers low-confidence UI |
| 2 | Min comp count for tight range | 10+ for P15-P85, 20+ for P10-P90 |
| 3 | Mandatory correction fields | At least 1 of brand/itemName/category |
| 4 | Sparse coverage copy | Tiered copy based on comp count |
| 5 | Camera two-photo flow | Tag first → item second → skip option |
| 6 | Onboarding flow | 3 screens: value prop, trust, camera permission |
| 7 | Paywall triggers | Scan limit, 3+ scans (anon), sell tab, settings |
| 8 | Offline behavior | On-device works, pricing fails gracefully, offline queue |
| 9 | Local persistence | SwiftData + file system, no aggressive API caching |
| 10 | Permissions/entitlements | Camera, photo library, Sign in with Apple, IAP |
| 11 | SPM dependencies | Only supabase-swift; everything else is built-in |
| 12 | Navigation routes | Typed enums + AppRouter @Observable |
| — | Error copy | Complete copy table for all 9 states |
| — | Testing framework | XCTest (unit + UI), previews with mock data |
| — | Confidence tier mismatch | Use 4-tier system from backend spec |

**The project is now fully specified. Every screen, every state, every algorithm, every constant, every error message, and every architectural decision has a concrete answer.**
