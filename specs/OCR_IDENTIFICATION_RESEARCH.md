# OCR to Product Identification Pipeline: Comprehensive Research Report for ThriftFlip

> **Purpose**: Research compilation for ThriftFlip, an iOS app that scans thrift store clothing tags and identifies the item + brand for resale pricing.
>
> **Date**: February 16, 2026

---

## Table of Contents

1. [OCR for Clothing Tags](#1-ocr-for-clothing-tags)
2. [RN Number Lookup](#2-rn-number-lookup)
3. [Product Identification Pipeline](#3-product-identification-pipeline)
4. [On-Device ML for iOS](#4-on-device-ml-for-ios)
5. [Confidence Scoring for Identification](#5-confidence-scoring-for-identification)
6. [Recommended Architecture for ThriftFlip](#6-recommended-architecture-for-thriftflip)
7. [Sources](#7-sources)

---

## 1. OCR for Clothing Tags

### 1.1 OCR Engine Comparison

#### Apple Vision Framework (VNRecognizeTextRequest) -- Recommended

- Built into iOS, zero additional dependencies, no network required.
- Two recognition levels: `.fast` (~0.05s) and `.accurate` (~0.31s on iPhone 12).
- **`customWords` property**: Supply an array of brand names (e.g., "Patagonia", "Lululemon", "Brunello Cucinelli") so the NLP post-processing layer does not "autocorrect" unusual brand names into common dictionary words. This is critical for ThriftFlip -- without it, "BAPE" might become "BAKE" or "BASE."
- Returns per-observation `confidence` score (Float, 0.0-1.0). In practice, Apple's confidence tends to cluster at 0.5 or 1.0 in `.accurate` mode rather than providing smoothly distributed values.
- Supports 18 languages as of iOS 18, including Cyrillic and Arabic scripts.
- Returns bounding boxes (`CGRect` in normalized coordinates) for each recognized text block, enabling spatial analysis of tag layout.
- Runs on the Apple Neural Engine, so it does not compete with GPU workloads from other models.

#### Google ML Kit (On-Device Text Recognition)

- Cross-platform (iOS + Android).
- Approximately 6x faster than Apple Vision (~0.05s vs ~0.31s on iPhone 12).
- Latin script only in the base on-device model (no CJK support).
- No `customWords` equivalent -- cannot bias recognition toward specific brand names.
- Good choice if speed-critical real-time preview is needed, but less configurable for domain-specific text.

#### Tesseract (via SwiftOCR or Wrapper)

- Open source, highly configurable, supports custom training data.
- Significantly slower and less accurate on mobile than Apple Vision or ML Kit.
- Requires manual memory management and image preprocessing.
- Not recommended for a modern iOS app when Apple Vision is available for free.

#### Recommendation

Use **Apple Vision** as the primary OCR engine. The `customWords` feature alone justifies the choice -- preload hundreds of known clothing brand names so that "PATAGONIA" is never misread as "PARAGONIA." The `.accurate` mode at ~0.31s is acceptable for a "scan tag" interaction where the user holds the camera steady for a moment.

### 1.2 Clothing Tag Types and Their Text Content

A typical garment has 2-4 physical labels. Here is what each contains:

#### Brand Label (main label, usually at back neck or waistband)

- Brand name and/or logo (often stylized fonts, embroidered or woven)
- Sometimes: tagline, website URL, "Made in [Country]"
- **OCR challenge**: Highly stylized fonts, often woven rather than printed, may be logo-only with no machine-readable text

#### Care/Content Label (usually sewn into side seam or below brand label)

- **Fiber content**: "100% Cotton", "60% Polyester / 40% Rayon"
- **Care symbols**: Laundry icons (graphical, not text -- OCR cannot read these)
- **Care instructions in text**: "Machine wash cold", "Tumble dry low"
- **Country of origin**: "Made in China", "Made in USA"
- **RN/CA number**: "RN 77388" or "CA 12345"
- Sometimes: style number, cut number, lot number

#### Size Label

- Size designation: "M", "L", "32x30", "US 8 / EU 40"
- Sometimes integrated into the brand label or care label rather than appearing separately

#### Hangtag (Removable, Often Missing on Thrift Items)

- Brand name, style name, original retail price, barcode/SKU
- Rarely present on thrift store items -- most have been removed

### 1.3 Common OCR Challenges with Clothing Tags

| Challenge | Description | Mitigation |
|-----------|-------------|------------|
| Curved/folded text | Tags sewn in curves or creased from laundering | Guide user to flatten tag; apply perspective correction |
| Worn/faded text | Repeated laundering degrades printed labels | Contrast enhancement, adaptive thresholding |
| Stylized fonts | Brand logos in non-standard or decorative typefaces | Rely on visual brand detection (CLIP/YOLO) rather than OCR for logos |
| Poor lighting | Thrift stores often have dim or uneven fluorescent lighting | Enable camera torch/flash; use HDR capture mode |
| Low contrast | White text on light-colored tags, dark text on dark tags | Adaptive binarization (Otsu's method or adaptive Gaussian) |
| Small text | RN numbers and fiber content percentages often printed in 4-6pt font | 2x bicubic upscaling of cropped tag region before OCR |
| Multi-language | Care instructions printed in English/French/Spanish on same label | Set `recognitionLanguages` on `VNRecognizeTextRequest` to `["en", "fr", "es"]` |
| Overlapping info | Multiple data types crammed onto one small label | Use bounding box positions for spatial segmentation of text blocks |
| Glossy/reflective tags | Satin care labels create glare spots under flash | Use diffused lighting or polarized camera filter; capture multiple frames |

### 1.4 Preprocessing Best Practices for Tag Images

Based on the YOLO11+OCR fashion scanner pipeline research and general OCR best practices:

1. **Crop to tag region**: Use a YOLO model or user-guided ROI to isolate just the tag area, removing garment fabric background noise. The YOLO11+OCR approach feeds only cropped regions to the OCR engine, yielding maximum accuracy.

2. **Upscale small crops**: Apply 2x bicubic interpolation on cropped tag images. Small digits (RN numbers, size text) benefit significantly from additional pixels.

3. **Target 300 DPI equivalent**: OCR engines perform best at approximately 300 DPI; lower than 200 DPI or higher than 600 DPI degrades accuracy.

4. **Adaptive thresholding**: Convert to grayscale, then apply Otsu's or adaptive Gaussian thresholding to handle variable lighting conditions common in thrift stores.

5. **Denoise**: Apply gentle bilateral filtering to reduce camera noise without losing text edges. Avoid aggressive Gaussian blur which destroys thin strokes.

6. **Deskew**: Detect text line orientation via Hough transform or `VNRecognizeTextRequest` bounding box angles, then rotate the image to horizontal.

7. **Trim non-text elements**: If care symbols or decorative elements appear adjacent to text, crop them out to prevent OCR confusion.

8. **Regex post-processing**: After OCR returns raw text, apply regex patterns to extract structured data:
   - RN pattern: `RN\s*\d{4,6}`
   - CA pattern: `CA\s*\d{5}`
   - Fiber content: `\d{1,3}%\s*(Cotton|Polyester|Nylon|Wool|Rayon|Spandex|Elastane|Silk|Linen|Acrylic|Viscose|Modal|Cashmere|Merino)`
   - Size: `(Size\s*)?(XXS|XS|S|M|L|XL|XXL|XXXL|\d{1,2})`
   - Country: `Made\s+in\s+(\w+(\s\w+)?)`
   - Style number: `Style\s*#?\s*(\w+)`

---

## 2. RN Number Lookup

### 2.1 What is an RN Number?

A **Registered Identification Number (RN)** is a numerical identifier issued by the U.S. Federal Trade Commission (FTC) to businesses involved in manufacturing, importing, distributing, or selling textile, wool, or fur products. The format is the prefix "RN" followed by digits (e.g., "RN 77388").

Businesses can legally use the RN on product labels **instead of** their company name. This means the RN is sometimes the only identifier linking a garment to its manufacturer or brand.

**Where found**: On the care/content label, typically printed as "RN 77388" or "RN77388". Some labels also include "WPL" (Wool Products Label) numbers, an older designation that serves a similar purpose.

**Historical dating value** (useful for vintage resale):
- RN 00101-04086: Registered between 1952-1959
- Five-digit RNs: Often 1960s-1970s
- Six-digit RNs: Generally post-1980s

### 2.2 FTC RN Database

**URL**: https://rn.ftc.gov/Account/RNSearch (also referenced at https://www.ftc.gov/rn-database/search)

**Search fields available**:
- RN Number (most useful for ThriftFlip)
- Company Name (DBA)
- Legal Business Name
- Business Type
- City, State, ZIP
- Product Line

**Data returned per record**:
- Company legal name
- DBA (doing business as) name -- often the consumer-facing brand
- Mailing address
- Business type (manufacturer, importer, retailer, wholesaler, etc.)
- Product line information

**Access limitations**:
- Web-based search interface only -- **no public REST API exists**
- The FTC has a general developer API program (https://www.ftc.gov/developer), but the RN database is not among the exposed endpoints
- The FTC recently moved the RN search to a system that may require account creation
- Data may be outdated if the registrant has not updated their information since original application

**Programmatic access strategies for ThriftFlip**:

Since there is no official API, the practical approaches are:

1. **Build a local cache/database** (Recommended for v1): Compile a lookup table of common RN numbers mapped to consumer-facing brand names. Many reseller communities have published these lists. Store as a bundled SQLite database or JSON file in the app.

2. **Server-side proxy**: Build a lightweight backend that queries the FTC web form, parses the HTML response, and caches results. Be mindful of FTC terms of service and rate limits.

3. **Crowdsourced mapping**: Let ThriftFlip users contribute RN-to-brand mappings when they confirm an identification. Over time this builds a comprehensive database.

### 2.3 RN to Brand Mapping Complexity

The relationship between RN numbers and consumer-facing brands is not always one-to-one:

- **One parent company, many RNs**: A corporation like VF Corporation may hold dozens of RNs for different brands (The North Face, Vans, Timberland, Wrangler, Lee).
- **RN maps to parent, not brand**: An RN may return "Hanesbrands Inc." but the garment is actually "Champion" -- a subsidiary brand. ThriftFlip needs a secondary mapping table from parent companies to their brand portfolios.
- **RNs change over time**: Corporate acquisitions cause RN ownership transfers. A vintage garment may have an RN that now maps to a different company than originally.
- **Multiple RNs on one garment**: Some labels show two RNs -- one for the brand/designer and one for the actual manufacturer.

Despite these complexities, RN lookup is considered one of the **most reliable and definitive** methods for brand identification. When an RN is present and readable, it provides a high-confidence identification of at least the parent company.

### 2.4 CA Numbers (Canadian Equivalent)

**What it is**: A 5-digit number preceded by "CA" (e.g., CA 12345), issued by the **Competition Bureau of Canada**. It serves the same purpose as the U.S. RN -- identifying the company responsible for a textile product.

**Database URL**: https://ised-isde.canada.ca/app/cb/can/public/srchFrm.html

**Search capabilities**:
- Search by CA Identification Number
- Search by company name
- Search by province
- Returns up to 100 records per query

**Data returned**:
- Company name
- Registration status (active or cancelled)
- Province of registration

**Registration cost**: One-time $100 CAD fee. Response within 5 business days for online applications.

**Limitations**:
- Web form only, no API
- Less commonly seen on garments sold in U.S. thrift stores
- Primarily appears on Canadian-made or Canadian-imported garments

### 2.5 RN/CA Reliability Summary

| Signal | Reliability | Notes |
|--------|-------------|-------|
| RN number found + FTC lookup succeeds | **Very High** | Definitive identification of parent company |
| RN found, maps to parent company (need brand mapping) | **High** | Need secondary parent-to-brand mapping table |
| RN found but FTC data is outdated | **Medium** | Company may have changed names or been acquired |
| No RN present (brand name printed instead) | N/A | Fall back to OCR of brand name text |
| CA number found + lookup succeeds | **High** | Less common in U.S. thrift stores |

---

## 3. Product Identification Pipeline

### 3.1 From OCR Text to Product Identification

The pipeline should extract and combine multiple text signals into a structured product profile:

```
OCR Output (raw text from tag scan):
  "PATAGONIA"
  "Size M"
  "100% Organic Cotton"
  "RN 77388"
  "Made in Vietnam"
  "Style 39174"

Parsed into structured data:
  Brand: "Patagonia"
  Size: "M"
  Material: "100% Organic Cotton"
  RN: "77388"
  Country: "Vietnam"
  Style#: "39174"

Generated search query:
  "Patagonia men's medium organic cotton shirt style 39174"
```

**Step-by-step flow**:

1. **OCR scan**: Apple Vision processes tag image, returns raw text blocks with bounding boxes and confidence scores.

2. **Text classification**: Regex patterns + simple NLP categorize each text block into: brand name, size, fiber content, RN/CA number, care instruction, country of origin, style number.

3. **RN lookup**: If an RN is detected, query the local cache (or server proxy) to confirm or identify the brand.

4. **Brand resolution**: Reconcile OCR-detected brand text with the RN lookup result. If they agree, confidence is high. If they conflict, flag for review.

5. **Visual classification**: Run the garment photo (not the tag) through MobileCLIP and/or YOLOv8n to determine clothing type (shirt, jacket, pants, dress, etc.) and extract visual style features.

6. **Feature assembly**: Combine all signals: brand + clothing type + size + material + color (extracted from garment image) + style number.

7. **Search query generation**: Construct a marketplace search query from the assembled features.

### 3.2 How Google Lens, Amazon StyleSnap, and Similar Tools Work

#### Google Lens

- Uses deep CNNs to analyze visual attributes: color, shape, texture, pattern, silhouette.
- Compares the query image against a massive index built from Google Shopping product feeds and web-crawled images.
- Combines visual similarity scores with a product knowledge graph for ranking.
- Primarily cloud-based with lightweight on-device preprocessing (image encoding, region selection).
- Does not use tag text -- purely visual matching against catalog imagery.

#### Amazon StyleSnap

- Uses **multiple CNNs** with a divide-and-conquer architecture:
  - **Detection/classification network**: Identifies the garment type and segments it from the background.
  - **Similarity network** (larger): Compares the segmented garment against Amazon's product catalog using visual embeddings.
- Trains with **3D product models rendered on varied backgrounds** to handle angle, viewpoint, and lighting variation.
- Fully cloud-based pipeline.
- Matches user photos to the closest Amazon catalog products for purchase.

#### Key Insight for ThriftFlip

Google Lens and StyleSnap match a **photo of a garment** to catalog product images. ThriftFlip has a different (and complementary) problem: matching a **tag** (text signals) plus a garment photo to identify a specific product for **resale pricing**. The tag gives ThriftFlip text signals (brand, RN, style number, material) that purely visual tools lack. This is ThriftFlip's competitive advantage -- combining text + visual yields higher accuracy than either alone.

### 3.3 Role of Visual Embeddings (CLIP, MobileCLIP, FashionCLIP)

#### How CLIP-Based Models Help

CLIP (Contrastive Language-Image Pretraining) encodes images and text into a **shared embedding space**. This means you can:
- Encode a garment photo into a vector.
- Encode text descriptions like "Patagonia Better Sweater Fleece Jacket" into vectors.
- Compute cosine similarity between the image vector and text vector.
- The highest-similarity text description identifies the product.

This enables **zero-shot classification** -- you do not need to train a custom classifier for every brand or product. You just compare against text descriptions.

#### FashionCLIP (Fashion Domain Fine-Tuned)

- Trained on 800K image-text pairs from Farfetch (fashion e-commerce).
- Uses ViT-B/32 architecture (same backbone as OpenAI CLIP).
- Outperforms generic CLIP on all fashion benchmarks (higher weighted macro F1 for category, subcategory, brand, color, material classification).
- FashionCLIP 2.0 further improves by starting from the LAION CLIP checkpoint rather than OpenAI CLIP.

#### Marqo-FashionSigLIP (Current State-of-the-Art, 2024)

- **+57% MRR improvement** over FashionCLIP 2.0 on averaged benchmarks.
- Trained with **Generalized Contrastive Learning (GCL)** on categories, styles, colors, materials, keywords, and fine-grained details.
- Evaluated across 7 public fashion datasets: Atlas, DeepFashion (In-shop), DeepFashion (Multimodal), Fashion200k, iMaterialist, KAGL, and Polyvore.
- Category-to-product precision@1: **0.758**
- Text-to-image recall@1: **0.121** (averaged across all 7 datasets -- note this is a hard retrieval task across very large galleries)
- Best available model for fashion product matching if you can run it server-side (too large for on-device).

### 3.4 Combining Text Features (From Tag) + Visual Features (From Photo)

Research on multimodal product recognition consistently shows significant accuracy gains from combining modalities.

#### Fusion Approaches

**1. Late Fusion (Recommended for ThriftFlip v1)**
- Run the OCR pipeline independently to get brand, size, material, type.
- Run visual embedding (MobileCLIP) independently to get garment type and style features.
- Combine scores at decision time using weighted averaging.
- Simplest to implement, easiest to debug, and allows each component to be improved independently.

**2. Early Fusion**
- Concatenate the text embedding vector and image embedding vector into a single combined vector.
- Feed the combined vector into a classifier or similarity search.
- Better theoretical accuracy but requires labeled training data for the fusion layer.

**3. Attention-Based Fusion**
- Cross-attention mechanism between text features and image features.
- Most powerful but most complex; used primarily in research systems.
- Requires substantial training data and compute.

#### Accuracy Data from Research

A multimodal YOLO+OCR fusion approach tested on retail products found:
- Image-only product recognition: ~84% accuracy
- Image + OCR text fusion: **~94.2% accuracy** (+10% from adding OCR)
- OCR text detection accuracy alone: 96.3%
- OCR text recognition accuracy alone: 94.1%

This demonstrates that combining visual and text features is not merely additive -- the modalities compensate for each other's weaknesses.

### 3.5 Generating an eBay Search Query

#### eBay Browse API (Active Listings)

- Supports keyword search + aspect filtering (Brand, Color, Size, Condition, etc.).
- Returns `aspectDistributions` that reveal available filter values (e.g., all sizes found for a brand).
- Free tier available for registered developers.
- Good for showing the user what is currently available and at what price.

#### eBay Marketplace Insights API (Sold/Completed Listings)

- Searches sold items from the **last 90 days**.
- Provides **actual sale prices** -- essential for accurate resale pricing.
- Supports filtering by keyword, category, eBay product ID (ePID), or GTIN.
- **Requires eBay Business account approval** for access.
- The older Finding API's `findCompletedItems` was decommissioned in February 2025; Marketplace Insights is the replacement.

#### Query Construction Strategy

```
Input signals:
  brand = "Patagonia"
  type = "jacket" (from YOLO)
  subtype = "fleece" (from material OCR + visual)
  size = "M"
  color = "blue" (from image analysis)
  style = "Better Sweater" (from tag OCR or visual match)

Tier 1 (most specific):
  Query: "Patagonia Better Sweater fleece jacket"
  Filters: Size=M, Color=Blue, Condition=Pre-owned
  Expected: <20 results, highly relevant

Tier 2 (if Tier 1 returns <3 results):
  Query: "Patagonia fleece jacket"
  Filters: Size=M, Condition=Pre-owned
  Expected: 20-100 results

Tier 3 (broadest fallback):
  Query: "Patagonia jacket"
  Filters: Condition=Pre-owned
  Expected: 100+ results
```

**Best practices**:
- Lead with brand name + most specific product identifier (style name or style number).
- Include garment type but avoid overly specific terms that reduce result count.
- Use aspect filters for size and color rather than putting them in the keyword string (avoids false negatives from eBay's keyword matching).
- If a style number is available (e.g., "#39174"), include it -- this is the most precise identifier and often returns the exact product.
- Fall back to progressively broader queries if specific queries return zero or very few results.
- For pricing, **sold listings** (Marketplace Insights API) are far more reliable than active listing prices, which often reflect aspirational rather than actual market prices.

---

## 4. On-Device ML for iOS

### 4.1 MobileCLIP Performance Comparison

MobileCLIP is Apple's family of efficient CLIP models designed specifically for mobile deployment. All variants have official Core ML models available from Apple on Hugging Face (`apple/coreml-mobileclip`).

| Variant | Image Encoder Params | Text Encoder Params | Total Params | Image Latency | Text Latency | Total Latency | ImageNet Zero-Shot Accuracy |
|---------|---------------------|--------------------:|--------------|---------------|-------------|---------------|-----------------------------|
| **MobileCLIP-S0** | 11.4M | 42.4M | 53.8M | 1.5ms | 1.6ms | **3.1ms** | **67.8%** |
| **MobileCLIP-S1** | 21.5M | 63.4M | 84.9M | 2.5ms | 3.3ms | **5.8ms** | **72.6%** |
| MobileCLIP-S2 | 35.7M | 63.4M | 99.1M | 3.6ms | 3.3ms | 6.9ms | 74.4% |
| MobileCLIP-B | 86.3M | 63.4M | 149.7M | 10.4ms | 3.3ms | 13.7ms | 76.8% |

*Latency measured on iPhone 12 Pro Max, iOS 17.0.3, via Core ML Tools v7.0.*

**Key reference points**:
- MobileCLIP-S0 achieves similar zero-shot performance to OpenAI's ViT-B/16 while being **4.8x faster** and **2.8x smaller**.
- MobileCLIP-S2 achieves better average zero-shot performance than SigLIP's ViT-B/16 while being **2.3x faster** and **2.1x smaller**.
- MobileCLIP-S1 averaged across 38 evaluation datasets: 61.3% vs S0's 58.1% -- a meaningful gap.

#### MobileCLIP-S0 vs MobileCLIP-S1 for Clothing

**MobileCLIP-S0**:
- 67.8% ImageNet zero-shot at 3.1ms total latency.
- Extremely fast, suitable for real-time camera preview classification.
- May struggle with fine-grained clothing distinctions (e.g., "fleece jacket" vs "puffer jacket").
- Image encoder is only 11.4M parameters -- limited representational capacity.

**MobileCLIP-S1**:
- 72.6% ImageNet zero-shot at 5.8ms total latency.
- +4.8% absolute accuracy improvement for only 2.7ms additional latency.
- Still comfortably real-time (5.8ms = 172 FPS theoretical).
- 21.5M parameter image encoder provides meaningfully richer feature representations.

**Recommendation**: Use **MobileCLIP-S1** for ThriftFlip. The 2.7ms latency cost is imperceptible to users, and the +4.8% ImageNet accuracy translates to meaningfully better garment classification where fine-grained visual distinctions matter (distinguishing a henley from a crew neck, a bomber jacket from a trucker jacket, etc.).

**Limitation**: Neither MobileCLIP variant has fashion-specific fine-tuning. For highest accuracy on fashion tasks, Marqo-FashionSigLIP would outperform generic MobileCLIP, but it requires server-side inference due to its larger size. A hybrid approach (MobileCLIP on-device for instant feedback, FashionSigLIP server-side for refined matching) could be considered for future versions.

### 4.2 Apple Vision Framework OCR on iOS 17+

Key capabilities and configuration for ThriftFlip:

- **`VNRecognizeTextRequest`** with `.accurate` recognition level for tag scanning.
- **`customWords`**: Preload an array of 500+ brand names for improved recognition. Example brands to include: Patagonia, Arc'teryx, Lululemon, The North Face, Supreme, Bape, Carhartt, Ralph Lauren, Brunello Cucinelli, Loro Piana, Burberry, etc.
- **`recognitionLanguages`**: Set to `["en"]` for U.S. clothing tags. Add `"fr"` and `"es"` for Canadian bilingual labels or imported garments.
- **iOS 18 improvements**: Expanded to 18 languages, improved accuracy on small text and challenging fonts.
- **Return type**: `VNRecognizedTextObservation` containing:
  - `topCandidates(maxCount)`: Multiple text hypotheses ranked by confidence (request 3-5 candidates for ambiguous text).
  - `confidence`: Float from 0.0 to 1.0 per candidate.
  - `boundingBox`: `CGRect` in normalized image coordinates (0,0 = bottom-left, 1,1 = top-right).
- **`minimumTextHeight`**: Set to filter out noise from very small background text. For tag scanning, a value of 0.02-0.05 (2-5% of image height) is reasonable.
- **Execution**: Runs on the Apple Neural Engine -- no GPU contention with YOLO or CLIP models running simultaneously.
- **No network required**: Fully on-device processing.

### 4.3 YOLOv8n for Garment Detection

#### Model Specifications (Nano Variant)

- **Parameters**: ~3.2M
- **Model size**: ~6 MB (FP32), ~3.2 MB (FP16), ~2 MB (INT8 quantized)
- **Input resolution**: 640x640 pixels
- **Inference latency**: ~5-8ms on iPhone Neural Engine
- **Architecture**: CSPDarknet53 backbone + PANet neck + Detect head

#### Pre-Trained Clothing Detection Models Available

**`kesimeg/yolov8n-clothing-detection`** (Hugging Face):
- 4 broad classes: Clothing, Shoes, Bags, Accessories
- Trained on Fashionpedia (46.8K images)
- Good starting point but too coarse for ThriftFlip's needs

**DeepFashion2 categories** (13 classes, better for fine-grained detection):
1. short_sleeved_shirt
2. long_sleeved_shirt
3. short_sleeved_outwear
4. long_sleeved_outwear
5. vest
6. sling
7. shorts
8. trousers
9. skirt
10. short_sleeved_dress
11. long_sleeved_dress
12. vest_dress
13. sling_dress

**For ThriftFlip**, you would want to either:
- Fine-tune YOLOv8n on DeepFashion2's 13 categories for garment type detection, or
- Use a simpler classifier head on top of MobileCLIP-S1 embeddings for type classification (fewer moving parts).

#### Brand Logo Detection

YOLOv8n can also be trained for brand logo detection (e.g., Nike swoosh, Adidas trefoil), but this requires:
- A custom dataset of brand logos on clothing (LogoDet-3K or similar).
- Fine-tuning for the specific brands you want to detect.
- This is a "nice to have" for ThriftFlip v2, not essential for v1 since OCR of brand name text and RN lookup are more reliable.

### 4.4 Core ML Conversion and Optimization

#### Conversion Toolchain

- **`coremltools` v7+** for PyTorch to Core ML conversion.
- Export as **`.mlpackage`** (ML Program format), optimized for Neural Engine.
- Do **not** use the older `.mlmodel` (Neural Network format) for new projects.

#### YOLOv8 Export to Core ML

```python
from ultralytics import YOLO
model = YOLO('yolov8n.pt')
model.export(format='coreml', imgsz=640)  # produces .mlpackage
```

#### Quantization Options

| Method | Size Reduction | Accuracy Impact | Best For |
|--------|---------------|-----------------|----------|
| FP16 (default) | ~50% vs FP32 | Negligible | Default choice |
| INT8 weight-only | ~75% vs FP32 | Minimal (<1% drop) | Reducing app download size |
| W8A8 (INT8 weights + activations) | ~75% vs FP32 | Small (1-2% drop) | Best latency on A17 Pro / M4 Neural Engine |
| 6-bit palettization | ~81% vs FP32 | Minimal | Alternative compression |
| 4-bit palettization | ~87% vs FP32 | Moderate (2-5% drop) | Extreme size constraints |

**Post-training quantization** can be applied directly to a converted `.mlpackage` using `coremltools.optimize.coreml` -- no retraining required. For most use cases, 8-bit quantization applied in a few minutes yields excellent results.

**W8A8 quantization** (INT8 weights + INT8 activations) leverages the faster int8-int8 compute path supported on A17 Pro and M4 chips, providing significant latency benefits on the Neural Engine.

#### MLTensor (iOS 18 / Core ML 7)

New in iOS 18, `MLTensor` enables stitching multiple models into a single pipeline with intermediate tensor operations between model stages. This is ideal for ThriftFlip's multi-model pipeline (YOLO detection -> crop -> CLIP embedding -> classification).

### 4.5 Can the Entire Pipeline Run On-Device?

**Yes, with one exception** (eBay API requires network):

| Component | On-Device? | Notes |
|-----------|-----------|-------|
| Camera capture + preprocessing | Yes | AVFoundation + Core Image |
| OCR (Apple Vision) | Yes | Fully on-device, ~300ms |
| Tag text parsing (regex + string matching) | Yes | Trivial CPU task, <5ms |
| Garment type detection (YOLOv8n) | Yes | ~5-8ms on Neural Engine |
| Visual embedding (MobileCLIP-S1) | Yes | ~5.8ms on Neural Engine |
| RN lookup | Partial | Local cache: yes. Full FTC database: requires network |
| Brand name matching (fuzzy match) | Yes | Local fuzzy match against bundled brand database |
| Confidence scoring | Yes | On-device computation |
| **eBay price lookup** | **No** | **Requires eBay API call (network)** |

**Total pipeline latency estimate**:

| Step | Latency |
|------|---------|
| Image preprocessing (crop, upscale, threshold) | ~20ms |
| OCR (`.accurate` mode) | ~300ms |
| Text parsing + brand matching | ~5ms |
| YOLOv8n garment detection | ~8ms |
| MobileCLIP-S1 embedding | ~6ms |
| Confidence scoring + fusion | ~1ms |
| **Total on-device** | **~340ms** |
| eBay API network call | ~200-500ms |
| **Total end-to-end** | **~540-840ms** |

The identification pipeline runs fully on-device in under 350ms. The user sees the brand identification and garment type almost instantly. The eBay pricing data arrives within about half a second after that, depending on network conditions.

---

## 5. Confidence Scoring for Identification

### 5.1 OCR Confidence Scoring

#### Apple Vision Confidence Values

- `VNRecognizedTextObservation.confidence`: Overall observation confidence (0.0-1.0).
- `VNRecognizedText` candidates from `topCandidates()`: Each candidate has its own confidence score.
- In practice, Apple Vision's confidence distribution tends to be **bimodal** -- values cluster at ~0.5 and ~1.0 rather than being uniformly distributed. A confidence of 1.0 means high certainty; 0.5 means the engine is uncertain; below 0.3 typically indicates an incorrect reading.

#### Practical Confidence Tiers for Brand Name OCR

| Scenario | Raw OCR Confidence | Interpretation |
|----------|-------------------|----------------|
| "PATAGONIA" read clearly, exact match in `customWords` | 0.95-1.0 | Very High -- brand definitively identified |
| "PATAG0NIA" read with minor OCR error (0 vs O), fuzzy match succeeds | 0.70-0.94 | High -- brand identified after correction |
| "P_TAG_NIA" partially readable, fuzzy match has multiple candidates | 0.30-0.69 | Medium -- needs visual confirmation |
| Unreadable, garbled, or no text detected on brand label | <0.30 | Low -- fall back to visual-only identification |

### 5.2 Multi-Signal Confidence Framework

ThriftFlip should compute an **aggregate confidence score** from multiple independent signals rather than relying on any single source:

```
Identification Confidence = weighted_sum(
    OCR_brand_confidence     * 0.35,
    RN_lookup_confidence     * 0.25,
    Visual_match_confidence  * 0.25,
    Garment_type_confidence  * 0.15
)
```

#### Signal Definitions

**1. OCR Brand Confidence (Weight: 0.35)**
- Derived from Apple Vision's `VNRecognizedText.confidence` for the brand name text.
- Boosted if the recognized text exactly matches an entry in the `customWords` brand list.
- Reduced if fuzzy matching was required (edit distance > 0).
- Set to 0.0 if no brand text was detected (does not penalize -- just means this signal is absent).

**2. RN Lookup Confidence (Weight: 0.25)**
- RN found and maps directly to a known consumer brand: **1.0**
- RN found and maps to a parent company (brand inferred from subsidiary list): **0.8**
- RN found but FTC lookup returned no results or outdated data: **0.3**
- No RN present on the tag: **0.0** (neutral -- not a negative signal, since many modern tags omit the RN)

**3. Visual Match Confidence (Weight: 0.25)**
- Computed as cosine similarity between the MobileCLIP-S1 embedding of the garment photo and text descriptions of candidate products.
- Example: compare garment embedding against "Patagonia Better Sweater fleece jacket" vs "Nike Dri-FIT running shirt" vs "Levi's 501 jeans."
- Similarity > 0.3 with a CLIP model typically indicates a strong match; < 0.15 indicates a weak match.
- Can also compare against a database of reference images for known products if available.

**4. Garment Type Confidence (Weight: 0.15)**
- YOLOv8n detection confidence for the garment category (shirt, jacket, pants, etc.).
- Used for cross-checking: if OCR/RN says "Levi's" (known for jeans) but YOLO detects "long_sleeved_outwear," the mismatch should reduce overall confidence or surface an alternative interpretation.

### 5.3 Agreement and Disagreement Handling

#### When Signals Agree

OCR says "Patagonia" + RN confirms Patagonia + MobileCLIP visual embedding matches a fleece jacket:

- Aggregate confidence is **high** (>0.85).
- Present the result with full confidence to the user.
- Auto-generate and execute the eBay search query.
- Show estimated resale price range.

#### When Signals Partially Agree

OCR says "Patagonia" + no RN present + visual embedding is ambiguous between fleece and synthetic jacket:

- Aggregate confidence is **medium** (0.50-0.84).
- Present the result with a note: "We think this is a Patagonia fleece jacket -- is this correct?"
- Show the top 2-3 candidate identifications.
- Let the user confirm or correct before running the eBay search.

#### When Signals Disagree

OCR says "Nike" + RN maps to Adidas:

- Flag as a **conflict**.
- Investigate possible causes: misread brand label, garment has been relabeled, or the RN database entry is outdated.
- **Weight the RN lookup result higher** than OCR for brand identification (RN is more authoritative -- it is a legal registration, not an OCR interpretation).
- Present both possibilities to the user: "RN 12345 is registered to Adidas, but we also read 'Nike' on the label. Which is correct?"
- Let the user resolve the conflict.

#### When Nothing is Confident

No readable brand text + no RN + weak visual match:

- Aggregate confidence is **low** (<0.20).
- Do not guess.
- Prompt user: "We couldn't identify this item. Try scanning a different tag, or enter the brand manually."
- Offer manual brand entry as fallback.

### 5.4 Confidence Thresholds and Required Data Points

| Confidence Level | Score Range | Required Data Points | User Experience |
|-----------------|------------|---------------------|-----------------|
| **High** | 0.85-1.0 | Brand confirmed by 2+ independent signals (e.g., OCR + RN, or OCR + strong visual match) | Auto-populate search query, show pricing immediately |
| **Medium** | 0.50-0.84 | Brand from 1 signal, garment type confirmed by at least 1 other signal | Show result with "Verify" prompt, let user confirm |
| **Low** | 0.20-0.49 | Partial text, no RN, weak visual match with multiple ambiguous candidates | Show top 3 candidates, ask user to select |
| **Unidentified** | <0.20 | No readable text, no RN, no visual match above threshold | Prompt user to try another tag/angle, offer manual entry |

#### Minimum Requirements for High Confidence

At least **2 of the following 4 conditions** must be met:

1. Clear brand name from OCR with confidence > 0.9 and exact match in brand database.
2. RN number successfully found and mapped to a consumer-facing brand.
3. MobileCLIP visual embedding matches the identified brand's typical product style with cosine similarity > 0.25.
4. Garment type from YOLO matches the expected product category for the identified brand (e.g., Levi's -> pants/jeans).

---

## 6. Recommended Architecture for ThriftFlip

### End-to-End Pipeline Diagram

```
[Camera Feed]
     |
     v
[Image Capture] -- AVFoundation, capture both tag close-up and garment overview
     |
     +--------+----------------------------+
     |                                     |
     v                                     v
[Tag Image Path]                   [Garment Photo Path]
     |                                     |
[Preprocessing]                    [Preprocessing]
(crop, upscale 2x,                 (resize to 640x640
 adaptive threshold,                for YOLO, 256x256
 deskew)                            for CLIP)
     |                                     |
     v                                     +----------+----------+
[Apple Vision OCR]                         |                     |
(.accurate mode,                    [YOLOv8n]             [MobileCLIP-S1]
 customWords=brands[])              (garment type          (visual embedding
     |                               detection)             vector)
     v                                     |                     |
[Text Parser]                              v                     v
(regex extraction:               [Garment Category]      [Embedding Vector]
 brand, RN, size,                (shirt, jacket,          (512-dim float)
 material, style#,               pants, dress, etc.)            |
 country)                              |                        |
     |                                  |                        |
     +----> [RN Lookup] <-- local SQLite cache                  |
     |      (brand confirmation                                 |
     |       or identification)                                 |
     |           |                                              |
     +-----------+----------------------------------------------+
                 |
                 v
          [Multimodal Fusion]
          (late fusion: weighted confidence
           scoring across all signals)
                 |
                 v
          [Brand + Product Identification]
          (brand name, garment type, size,
           material, color, confidence score)
                 |
                 v
          [eBay Query Generator]
          (tiered query construction:
           specific -> broad fallback)
                 |
                 v
          [eBay Browse API /            <-- requires network
           Marketplace Insights API]
                 |
                 v
          [Resale Price Display]
          (price range, recent sold
           listings, suggested list price)
```

### Model Size Budget on Device

| Model | Size (FP16) | Size (INT8) | Latency | Purpose |
|-------|------------|------------|---------|---------|
| Apple Vision OCR | Built-in (0 MB) | N/A | ~300ms | Text recognition from tag images |
| YOLOv8n (clothing, 13-class) | ~6 MB | ~3 MB | ~8ms | Garment type detection |
| MobileCLIP-S1 | ~170 MB | ~85 MB | ~6ms | Visual embedding for product matching |
| Brand name database | ~2 MB | N/A | <1ms | Fuzzy string matching for brand identification |
| RN lookup cache | ~5 MB | N/A | <1ms | RN number to brand mapping |
| **Total** | **~183 MB** | **~95 MB** | **~315ms** | |

With INT8 quantization of both ML models, the total on-device footprint can be kept under 100 MB, which is acceptable for an iOS app.

### Key Implementation Priorities

1. **Preload `customWords`** with a comprehensive list of clothing brands, especially high-value resale brands: Patagonia, Arc'teryx, Lululemon, The North Face, Supreme, Bape, Carhartt, Stone Island, CP Company, Acne Studios, Maison Margiela, Issey Miyake, Comme des Garcons, Ralph Lauren, Burberry, Barbour, Canada Goose, Moncler, etc.

2. **Build a local RN cache** of the most common RN numbers mapped to consumer-facing brand names (not just parent companies). Seed from community-compiled lists, and let users contribute corrections over time.

3. **Use MobileCLIP-S1 over S0** -- the 2.7ms latency cost is imperceptible and the +4.8% accuracy gain is meaningful for fine-grained clothing classification.

4. **Prioritize RN lookup** as the highest-authority brand signal when available -- it is legally definitive. OCR of brand name text is second. Visual matching is a supporting and confirming signal.

5. **Construct eBay queries** in a tiered approach: try specific query first (brand + style number + type), then broader (brand + type + size), then broadest (brand + type) as fallbacks.

6. **Show confidence to the user** in a simple way (e.g., green checkmark for high confidence, yellow question mark for medium, manual entry prompt for low) so they know when to trust the result and when to verify.

---

## 7. Sources

### OCR and Text Recognition
- [Comparing On-device OCR Frameworks: Apple Vision and Google MLKit](https://www.bitfactory.io/de/dev-blog/comparing-on-device-ocr-frameworks-apple-vision-and-google-mlkit/)
- [Apple VNRecognizeTextRequest Documentation](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Apple customWords Documentation](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/customwords)
- [YOLO11 + OCR: AI-Based Fashion Brand Scanner](https://www.labellerr.com/blog/ai-based-fashion-brand-scanner-ocr/)

### RN and CA Numbers
- [FTC RN Database Search](https://www.ftc.gov/rn-database/search)
- [FTC Registered Identification Number FAQ](https://www.ftc.gov/business-guidance/industry/registered-identification-number-frequently-asked)
- [RN and CA Numbers on Clothing Labels](https://www.rapidtags.com/rn-numbers-ca-identification-numbers-clothing-labels/)
- [RN Numbers on Clothing Labels](https://www.rapidtags.com/rn-numbers-clothing-labels/)
- [CA Identification Number - Competition Bureau Canada](https://competition-bureau.canada.ca/en/contact-competition-bureau-canada/ca-identification-number)
- [Vintage Sheet Patterns RN Number Guide](https://vintagesheetpatterns.com/rn-numbers/)
- [Get Lucky Vintage: Decoding RN/WPL Numbers](https://www.getluckyvintage.com/blogs/the-vintage-insider-trends-tips-and-tales/decoding-rn-wpl-numbers)
- [FTC Threading Your Way Through Labeling Requirements](https://www.ftc.gov/business-guidance/resources/threading-your-way-through-labeling-requirements-under-textile-wool-acts)

### Clothing Labels and Tag Types
- [Garment Labelling Requirements (Sewport)](https://sewport.com/learn/garment-labeling-and-requirements)
- [All About Labels: A Guide to Apparel Labeling (AJG)](https://ajgfashionconsulting.com/blog/all-about-labels-everything-you-need-to-know)
- [Types of Clothing Labels and Their Purpose (Apprintable)](https://www.apprintable.com/types-of-clothing-labels.html)
- [How to Identify Clothing Brand from Label (ManufacturingClothes)](https://www.manufacturingclothes.com/the-complete-handbook-discovering-the-clothing-brand-via-its-label/)

### Visual Search and Product Identification
- [Amazon StyleSnap Science](https://www.amazon.science/latest-news/the-science-behind-amazons-new-stylesnap-for-home-feature)
- [Google Lens Transforming Product Discovery](https://www.flipflow.io/en/blog-en/google-lens-transforming-product-discovery/)
- [Visual Search: A Comprehensive Guide](https://ignitevisibility.com/visual-search/)

### CLIP and Fashion Embeddings
- [MobileCLIP GitHub Repository (Apple)](https://github.com/apple/ml-mobileclip)
- [MobileCLIP Core ML Models on Hugging Face](https://huggingface.co/apple/coreml-mobileclip)
- [Marqo FashionCLIP / FashionSigLIP GitHub](https://github.com/marqo-ai/marqo-FashionCLIP)
- [Marqo FashionSigLIP on Hugging Face](https://huggingface.co/Marqo/marqo-fashionSigLIP)
- [Marqo FashionSigLIP Leaderboard](https://github.com/marqo-ai/marqo-FashionCLIP/blob/main/LEADERBOARD.md)
- [Marqo Releases FashionCLIP and FashionSigLIP (MarkTechPost)](https://www.marktechpost.com/2024/08/17/marqo-releases-marqo-fashionclip-and-marqo-fashionsiglip-a-family-of-embedding-models-for-e-commerce-and-retail/)

### YOLO for Fashion Detection
- [YOLOv8n Clothing Detection Model (Hugging Face)](https://huggingface.co/kesimeg/yolov8n-clothing-detection)
- [YOLOv8 + CoreML for Fashion Object Detection (Medium)](https://medium.com/@harshvardhankushwaha/train-once-run-anywhere-yolov8-coreml-for-fashion-object-detection-728921e57900)
- [Clothing Detection and Classification with YOLO (Springer)](https://link.springer.com/chapter/10.1007/978-3-031-36819-6_11)
- [Fashion Object Detection with YOLOv8 (Kaggle)](https://www.kaggle.com/code/rohitgadhwar/fashion-object-detection-yolov8)

### Core ML and iOS ML
- [Core ML Optimization Overview (Apple)](https://apple.github.io/coremltools/docs-guides/source/opt-overview.html)
- [Core ML Optimization Workflow (Apple)](https://apple.github.io/coremltools/docs-guides/source/opt-workflow.html)
- [Core ML New Features (Apple)](https://apple.github.io/coremltools/docs-guides/source/new-features.html)

### eBay APIs
- [eBay Browse API Documentation](https://developer.ebay.com/api-docs/buy/browse/resources/item_summary/methods/search)
- [eBay Marketplace Insights API](https://developer.ebay.com/api-docs/buy/marketplace-insights/resources/item_sales/methods/search)
- [eBay Browse API Overview](https://developer.ebay.com/api-docs/buy/browse/overview.html)

### Existing Thrift Store Apps (Competitive Reference)
- [ThriftAI: Profit Identifier](https://www.thrifting.app/)
- [FlipIQ](https://flipiq.app/)
- [Revalue](https://getrevalue.com/)
- [Thrift Store Price Checker Guide (Underpriced)](https://www.underpriced.app/blog/thrift-store-price-checker-app-guide)
