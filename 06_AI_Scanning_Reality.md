# AI Scanning Reality Check
### What AI Vision Can and Cannot Do for Clothing Identification — Honest, Research-Backed

---

## Document Role

This is the capability and limitation baseline for all product claims.

MVP messaging and UX must stay consistent with this document:
1. Tag-forward scanning expectation
2. Confidence-scored outputs
3. Honest low-confidence and unknown states

---

## The Bottom Line

AI clothing scanning **primarily works by reading the tag.** When people say "AI identifies clothing," what's actually happening in ~90% of successful identifications is OCR (text recognition) on the brand label, not magical visual brand detection from the garment itself.

---

## What Works Reliably

| Capability | How It Works | Accuracy | Status |
|-----------|-------------|----------|--------|
| **Read brand from tag/label** | OCR (text recognition) on visible text | 90-95% | Solved |
| **Recognize major logos** | Pattern matching (Nike swoosh, Adidas stripes) | 85-95% | Solved |
| **Identify garment type** | CNN classification (shirt, dress, shoes, etc.) | 99%+ | Solved |
| **Detect color** | Standard computer vision | 95%+ | Solved |
| **Detect pattern** | Stripes, plaid, floral, solid | 90%+ | Solved |
| **Find visually similar items online** | Embedding similarity (Google Lens approach) | Good | Production-ready |
| **Recognize distinctive brand patterns** | Burberry plaid, LV monogram, Gucci stripe | 60-80% | Works for iconic patterns |

## What Does NOT Work Reliably

| Capability | Why Not | Current State |
|-----------|---------|--------------|
| **Brand from plain, unbranded garment** | A plain black Prada sweater looks identical to a plain black Gap sweater. No visual information to differentiate. | Not solvable with current technology |
| **Exact fabric composition** | "60% cotton, 40% polyester" cannot be determined visually | Requires care label or physical testing |
| **Size from appearance** | Can't determine size from a photo unless label is visible | Requires tag |
| **Authentication of luxury items** | Requires examining hardware, stitching, serial numbers, material feel | Not reliable from photos |
| **Condition assessment** | Pilling, staining, fabric wear are difficult to capture/assess from photos | Very limited |

---

## How Existing Scanner Apps Actually Work

### ThriftAI
- Recommends photographing **"labels, tags, and distinguishing features"** — confirms brand ID relies on the tag
- Uses image recognition + cross-references against "millions of sold listings"
- Does NOT disclose whether it uses GPT-4V, Claude, or a custom model
- **User reviews:** Slow (2-3 min), inaccurate, crashes, "formulaic" pricing

### Google Lens
- Uses MobileNetV3 on-device for initial detection (<50ms)
- Sends compressed feature vector to server for matching against 50+ billion products
- **This is visual search (reverse image matching), not brand classification**
- ~80-90% accuracy for mainstream clothing, 85-95% for luxury with visible branding
- Returns results in 1-2 seconds

### Key Insight
The apps that work well (Google Lens) are doing **similarity search against a massive product database.** The apps that don't work well (ThriftAI) are trying to run fresh AI inference from scratch on every scan.

---

## Research-Backed Accuracy Numbers

### By Method

| Identification Method | Accuracy | Source |
|----------------------|----------|--------|
| Brand from visible logo/label (OCR) | 85-95% | Multiple commercial OCR benchmarks |
| Garment type classification (CNN) | 99.65% | Fashion-MNIST (MDPI Mathematics 2024) |
| Fashion image classification (DINOv2) | 98.53% | Meta DINO research |
| Clothing brand logo recognition | 62.59% | CBL Dataset paper (IEEE 2020) |
| Fashion retrieval (FashionSigLIP) | +57% MRR vs. CLIP | Marqo benchmarks |
| Brand from unbranded garment | Very low | "Brand > Logo" paper (Springer 2019) — works statistically across many images but not reliable for single-image classification |
| LLM fabric identification | ~80% for basic categories | Tandfonline 2018 |

### GPT-4o / Claude Vision for Clothing

- GPT-4o can identify products when **logos or distinctive design elements are visible** (confirmed in real tests)
- GPT-4o is **prone to hallucination** — will confidently state a brand name even when guessing. >50% of GPT-4o references can be fabricated (StudyFinds)
- Claude Vision is strong for **describing** clothing attributes and **categorizing** items, but faces the same limitation: cannot identify brand without visible branding
- Both work well with **multiple images** (tag + garment + care label in one call)

---

## The Practical Workflow That Actually Works

For a thrift store scanning app, the honest workflow is:

### Step 1: On-device (instant)
- **OCR reads the tag** → brand name, size, material, RN number
- **YOLO detects garment type** → shirt, jacket, shoes
- **MobileCLIP generates embedding** → 512-dim vector for similarity search

### Step 2: Server-side (<500ms)
- **Vector similarity search** against database of millions of products
- **Text lookup** for brand + category from OCR results
- **Cache lookup** for pre-computed sold comps

### Step 3: AI fallback (3-8 seconds, only when needed)
- For 20% of items where vector search returns low confidence
- Send multiple images to Claude Haiku 4.5
- Get structured JSON response with identification + estimate

### What Users See
- Results presented as **suggestions with confidence scores**, not definitive answers
- "94% match: Patagonia Better Sweater, $62-115" vs. "43% — review carefully"
- Users can always correct/confirm (corrections improve the system)

---

## The RN Number Hack

**RN (Registered Number) and CA numbers on care labels are a goldmine.** These are FTC registration numbers that identify the manufacturer. Even when a brand name tag is worn off or removed, the RN number on the care label can identify the brand with near-100% accuracy.

The FTC maintains a public database. RN number → manufacturer → brand. This is a reliable fallback that no existing scanner app uses prominently.

---

## Specialized Fashion AI APIs Available

| API | What It Does | Brand ID? | Pricing |
|-----|-------------|-----------|---------|
| **Ximilar Fashion Tagging** | 100+ attributes (color, style, material, fit) | No (can be customized) | EUR 59/mo for 100K credits |
| **Pixyle.ai** | 20,000+ fashion attributes, 0.2s/image | Unknown | Enterprise only |
| **Nyckel** | Clothing brand classifier | Yes (limited brands) | Free tier |
| **API4AI Fashion** | Object detection for clothing | No | Free tier |
| **Marqo-FashionSigLIP** | Fashion-specific embeddings for similarity search | Via matching | Free (open source) |

---

## What This Means For The Product

**The scanner is not magic. It's a combination of:**
1. OCR reading the tag (reliable, boring, effective)
2. Visual similarity matching against a product database (fast, scalable)
3. AI vision as a fallback for ambiguous items (slower, more expensive, but handles edge cases)

**The honest value proposition is:**
"Scan the tag and item, we auto-fill your listing and estimate the price — in under a second instead of 15 minutes manually."

NOT: "Point at any garment and we magically know everything about it."

---

*Sources: Apple MobileCLIP, Marqo-FashionSigLIP, MDPI Mathematics (Fashion-MNIST), Meta DINOv2, CBL Dataset (IEEE), Springer "Brand > Logo" paper, TechCrunch (GPT-4V flaws), StudyFinds (hallucination rates), Google Lens architecture, Ximilar docs, Anthropic Vision docs, CVPR 2025, ACL 2025*
