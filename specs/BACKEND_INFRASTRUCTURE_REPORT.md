# ThriftFlip Backend Infrastructure Report
## Clothing Scanner MVP — iOS (SwiftUI) + Python FastAPI

*Compiled: February 2026*

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Database](#2-database)
3. [Image Storage](#3-image-storage)
4. [Hosting for FastAPI](#4-hosting-for-fastapi)
5. [Rate Limiting and Quotas](#5-rate-limiting-and-quotas)
6. [Background Jobs](#6-background-jobs)
7. [User Correction Loop](#7-user-correction-loop)
8. [Cost Analysis](#8-cost-analysis)
9. [Architectural Recommendation](#9-architectural-recommendation)

---

## 1. Authentication

### Provider Comparison

| Feature | Supabase Auth | Firebase Auth | Auth0 |
|---|---|---|---|
| **Free MAU** | 50,000 | 50,000 | 25,000 |
| **Paid MAU cost** | $0.00325/MAU (Pro) | ~$0.0055-$0.0025/MAU (tiered) | Starts $35/mo for 500 MAU (B2C) |
| **Apple Sign-In** | Native iOS support via supabase-swift | Native iOS support via Firebase SDK | Native iOS support via Auth0.swift |
| **Anonymous/Guest** | Built-in `signInAnonymously()` with upgrade path | Built-in anonymous auth with account linking | Not natively supported on free tier |
| **iOS SDK** | supabase-swift (SPM, actively maintained, 116 releases) | firebase-ios-sdk (mature, widely used) | Auth0.swift (iOS 14+, Universal Links on 17.4+) |
| **Free tier base cost** | $0 | $0 | $0 |
| **Bundled services** | DB, Storage, Realtime, Edge Functions | Firestore, Storage, Cloud Functions | Auth only |

### Apple Sign-In Integration Details

**Supabase Auth:**
- Uses Apple's native `AuthenticationServices` framework directly on iOS.
- The supabase-swift SDK supports `signInWithApple()` natively — no browser redirect needed.
- One caveat: Apple's identity token does not include the user's full name. You must capture it from Apple's native response and manually call `updateUser()`.
- No secret key rotation needed for native flow (only required for OAuth web flow, which rotates every 6 months).

**Firebase Auth:**
- Mature integration with `AuthenticationServices` on iOS.
- Requires `UIApplicationDelegateAdaptor` in SwiftUI apps and disabling app delegate swizzling.
- Account linking for anonymous-to-Apple upgrade is well-documented.
- The most battle-tested option for iOS apps.

**Auth0:**
- Auth0.swift SDK supports native Apple Sign-In without browser redirect.
- On iOS 17.4+ it uses Universal Links for callbacks; falls back to custom URL scheme on older versions.
- More complex setup than Supabase or Firebase for a simple use case.
- The pricing jump from free to paid ($35/mo for just 500 MAU on B2C) is steep.

### Anonymous/Guest Mode

**Supabase (Recommended for ThriftFlip):**
```swift
// Swift SDK
let session = try await supabase.auth.signInAnonymously()
// User gets a real UID, can use RLS-protected tables
// Later, upgrade to permanent account:
try await supabase.auth.linkIdentity(provider: .apple)
```
- Anonymous users get a real `auth.uid()` — works with Row Level Security.
- Data persists through the upgrade; UID stays the same.
- Enable captcha for anonymous sign-ins to prevent abuse.

**Firebase:**
```swift
Auth.auth().signInAnonymously { authResult, error in
    // User gets a temporary UID
    // Later, link Apple credentials:
    let credential = OAuthProvider.credential(...)
    authResult?.user.link(with: credential)
}
```
- Well-documented upgrade path from anonymous to Apple/Google.
- UID persists through account linking.

**Auth0:**
- No built-in anonymous auth on the free tier. You would need to implement guest mode at the application level (local-only state, no server identity), then create the account on signup. This means no server-side data association during the guest period.

### Recommendation: Supabase Auth

**Why:** Supabase Auth bundles authentication with the database, storage, and RLS in a single platform. The 50K MAU free tier matches Firebase. The anonymous sign-in with seamless upgrade to Apple Sign-In is exactly what ThriftFlip needs for try-before-signup. The Swift SDK is actively maintained and supports native Apple Sign-In without browser redirects. Since you are already going to need Postgres for the main database and pgvector, Supabase gives you auth + database + storage in one bill.

---

## 2. Database

### Provider Comparison

| Feature | Supabase Postgres | Neon | PlanetScale |
|---|---|---|---|
| **Free tier** | 500 MB, pauses after 1 week idle | 0.5 GB/project, 100 CU-hours/mo, never expires | **No free tier** (removed April 2024) |
| **Paid starting** | $25/mo (Pro: 8GB DB, 100K MAU, 100GB storage) | $19/mo (Launch: 10GB storage, 300 CU-hours) | $39/mo (Scaler) or $5/mo (single node) |
| **pgvector** | Yes, built-in | Yes, native support | No (Postgres is new, limited extension support) |
| **Serverless** | No (always-on shared compute on free) | Yes (scale to zero, wake on query) | Yes |
| **RLS** | Built-in with auth integration | Standard Postgres RLS (no auth integration) | Not applicable (MySQL heritage) |
| **Bundled** | Auth, Storage, Realtime, Edge Functions | Database only | Database only |

### Schema Design

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    scan_quota_remaining INT DEFAULT 5,
    quota_reset_at TIMESTAMPTZ DEFAULT (now() + interval '1 day'),
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Scans table (one row per camera scan)
CREATE TABLE public.scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,           -- R2/Storage URL for original image
    thumbnail_url TEXT,                -- Resized version
    status TEXT DEFAULT 'pending',     -- pending, processing, completed, failed
    -- ML results
    predicted_brand TEXT,
    predicted_category TEXT,           -- shirt, pants, jacket, etc.
    predicted_condition TEXT,          -- excellent, good, fair, poor
    predicted_size TEXT,
    predicted_color TEXT,
    predicted_material TEXT,
    confidence_score FLOAT,
    -- Pricing
    estimated_price_low DECIMAL(10,2),
    estimated_price_high DECIMAL(10,2),
    -- Metadata
    raw_ml_response JSONB,            -- Full ML API response for debugging
    processing_time_ms INT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Corrections table (user feedback on scan results)
CREATE TABLE public.corrections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,          -- 'brand', 'category', 'size', etc.
    original_value TEXT,               -- What ML predicted
    corrected_value TEXT NOT NULL,     -- What user said it should be
    created_at TIMESTAMPTZ DEFAULT now()
);
-- Append-only: never UPDATE or DELETE corrections; they form an audit log.

-- Collections table (user-curated groups of scans)
CREATE TABLE public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.collection_items (
    collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (collection_id, scan_id)
);

-- Scan embeddings for similarity search
CREATE TABLE public.scan_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    embedding vector(512),             -- CLIP/FashionCLIP produces 512-dim vectors
    model_version TEXT NOT NULL,       -- Track which model produced this embedding
    created_at TIMESTAMPTZ DEFAULT now()
);

-- HNSW index for fast approximate nearest neighbor search
CREATE INDEX ON public.scan_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Indexes
CREATE INDEX idx_scans_user_id ON public.scans(user_id);
CREATE INDEX idx_scans_created_at ON public.scans(created_at DESC);
CREATE INDEX idx_corrections_scan_id ON public.corrections(scan_id);
CREATE INDEX idx_corrections_field ON public.corrections(field_name, corrected_value);
CREATE INDEX idx_collection_items_scan ON public.collection_items(scan_id);
```

### pgvector for Similarity Search

**Is it production-ready?** Yes, for ThriftFlip's scale.

- pgvector 0.8.0 (released on Aurora) delivers up to 9x faster query processing and introduced iterative index scans for filtered vector searches.
- For datasets under 10M vectors with sub-100ms latency requirements, pgvector works well. ThriftFlip at 10K users doing 5 scans/day = ~1.5M vectors/year. This is comfortably within pgvector's sweet spot.
- pgvectorscale achieves 471 QPS at 99% recall on 50M vectors — far exceeding ThriftFlip's needs.
- The 150x speedup over the past year (HNSW indexes, parallel builds, iterative scans) has made pgvector competitive with dedicated vector databases for datasets under 50M vectors.

**How to store and query visual embeddings:**

```python
# Generate embedding with FashionCLIP (512-dim)
from fashion_clip.fashion_clip import FashionCLIP
fclip = FashionCLIP('fashion-clip')
embedding = fclip.encode_images([image])[0]  # Returns 512-dim vector

# Store in Postgres
await db.execute(
    "INSERT INTO scan_embeddings (scan_id, embedding, model_version) "
    "VALUES ($1, $2, $3)",
    scan_id, embedding.tolist(), "fashionclip-v1"
)

# Find similar items (cosine similarity)
similar = await db.fetch("""
    SELECT s.*, 1 - (se.embedding <=> $1::vector) AS similarity
    FROM scan_embeddings se
    JOIN scans s ON s.id = se.scan_id
    WHERE s.user_id = $2  -- RLS would handle this automatically
    ORDER BY se.embedding <=> $1::vector
    LIMIT 10
""", query_embedding, user_id)
```

**Why FashionCLIP over standard CLIP:** FashionCLIP is fine-tuned on the Farfetch dataset with fashion-specific image-text pairs. It outperforms standard CLIP on fashion retrieval tasks and has been scaled to 3.2M unique SKUs in production.

### Row-Level Security for Multi-Tenant Data

```sql
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corrections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_embeddings ENABLE ROW LEVEL SECURITY;

-- Users can only read/update their own profile
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (id = auth.uid());

-- Users can only see their own scans
CREATE POLICY "Users can view own scans"
    ON public.scans FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own scans"
    ON public.scans FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can only see/create corrections for their own scans
CREATE POLICY "Users can view own corrections"
    ON public.corrections FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert corrections for own scans"
    ON public.corrections FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Collections: users see their own + public collections
CREATE POLICY "Users can view own or public collections"
    ON public.collections FOR SELECT
    USING (user_id = auth.uid() OR is_public = true);

CREATE POLICY "Users can manage own collections"
    ON public.collections FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Service role bypasses RLS for backend processing
-- FastAPI backend uses the service_role key for ML pipeline writes
```

### Recommendation: Supabase Postgres

**Why:** Supabase bundles Postgres with pgvector, auth, storage, and RLS in one platform. The tight integration between `auth.uid()` and RLS policies means you get multi-tenant data isolation with zero application code. For ThriftFlip, this eliminates an entire class of security bugs. Neon is a strong alternative if you only need a database, but Supabase's bundled offering is more cost-effective when you factor in auth and storage.

---

## 3. Image Storage

### Provider Comparison

| Feature | Supabase Storage | Cloudflare R2 | AWS S3 |
|---|---|---|---|
| **Free tier storage** | 1 GB | 10 GB | 5 GB (12 months only) |
| **Storage cost/GB** | $0.021/GB (Pro) | $0.015/GB | $0.023/GB |
| **Egress cost/GB** | $0.09/GB beyond 250GB | **$0 (zero egress)** | $0.09/GB |
| **Free bandwidth** | 2 GB (Free), 250 GB (Pro) | Unlimited (zero egress) | 100 GB (12 months) |
| **Presigned URLs** | Yes (via Supabase SDK) | Yes (S3-compatible API) | Yes (native) |
| **CDN** | Supabase CDN (basic) | Cloudflare CDN (global, best-in-class) | CloudFront (separate service, adds cost) |
| **Image transforms** | Basic (via image-transformation add-on) | Cloudflare Images ($0.50/1K transforms, 5K free) | Lambda@Edge (complex setup) |
| **Class A ops (PUT)** | Included in bandwidth | $4.50/million | $5.00/million |
| **Class B ops (GET)** | Included in bandwidth | $0.36/million | $0.40/million |

### Presigned URL Upload Pattern

This is the recommended architecture for iOS image uploads:

```
iOS App                    FastAPI Backend              Cloudflare R2
  |                              |                          |
  |  1. POST /scans/upload       |                          |
  |  (request presigned URL)     |                          |
  |----------------------------->|                          |
  |                              |  2. Generate presigned   |
  |                              |     PUT URL (boto3)      |
  |                              |------------------------->|
  |                              |  3. Return URL + key     |
  |  4. Presigned URL            |<-------------------------|
  |<-----------------------------|                          |
  |                              |                          |
  |  5. PUT image directly       |                          |
  |  (URLSession upload)         |                          |
  |-------------------------------------------------------->|
  |                              |                          |
  |  6. 200 OK                   |                          |
  |<--------------------------------------------------------|
  |                              |                          |
  |  7. POST /scans/confirm      |                          |
  |  (notify upload complete)    |                          |
  |----------------------------->|                          |
  |                              |  8. Trigger ML pipeline  |
  |                              |  (background job)        |
```

**FastAPI presigned URL generation (R2):**
```python
import boto3
from botocore.config import Config

r2_client = boto3.client(
    's3',
    endpoint_url=f'https://{ACCOUNT_ID}.r2.cloudflarestorage.com',
    aws_access_key_id=R2_ACCESS_KEY,
    aws_secret_access_key=R2_SECRET_KEY,
    config=Config(signature_version='s3v4'),
    region_name='auto'
)

@app.post("/scans/upload")
async def request_upload_url(user_id: str = Depends(get_current_user)):
    key = f"scans/{user_id}/{uuid4()}.jpg"
    presigned_url = r2_client.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': 'thriftflip-images',
            'Key': key,
            'ContentType': 'image/jpeg',
        },
        ExpiresIn=300  # 5 minutes
    )
    return {"upload_url": presigned_url, "key": key}
```

**iOS client upload (Swift):**
```swift
func uploadImage(_ image: UIImage, to presignedURL: URL) async throws {
    guard let imageData = image.jpegData(compressionQuality: 0.85) else {
        throw UploadError.compressionFailed
    }
    var request = URLRequest(url: presignedURL)
    request.httpMethod = "PUT"
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    let (_, response) = try await URLSession.shared.upload(for: request, from: imageData)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw UploadError.uploadFailed
    }
}
```

### Image Optimization/Resizing Pipeline

**Recommended approach: Cloudflare Image Transformations (on-demand)**

Instead of pre-generating multiple sizes, use Cloudflare's image transformation on read:

```
Original: https://images.thriftflip.app/scans/{user_id}/{uuid}.jpg
Thumbnail: https://images.thriftflip.app/cdn-cgi/image/width=300,height=300,fit=cover/scans/{user_id}/{uuid}.jpg
Detail: https://images.thriftflip.app/cdn-cgi/image/width=800,quality=80/scans/{user_id}/{uuid}.jpg
```

- 5,000 free unique transformations per month.
- $0.50 per 1,000 unique transformations beyond that.
- Each unique size/quality combo is only billed once per month, regardless of how many times it is served.
- Transformed images are cached at Cloudflare's edge (330+ cities).

**Alternative: Backend resize with Pillow (for ML preprocessing):**
```python
from PIL import Image
import io

def resize_for_ml(image_bytes: bytes, target_size: int = 224) -> bytes:
    """Resize image for CLIP/FashionCLIP inference (224x224)."""
    img = Image.open(io.BytesIO(image_bytes))
    img = img.convert('RGB')
    img = img.resize((target_size, target_size), Image.LANCZOS)
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG', quality=85)
    return buffer.getvalue()
```

### CDN Strategy

With Cloudflare R2, you automatically get Cloudflare's CDN. Connect a custom domain (`images.thriftflip.app`) to your R2 bucket, and all images are served through Cloudflare's global edge network at zero egress cost.

### Recommendation: Cloudflare R2

**Why:** Zero egress fees are the killer feature. For an image-heavy app like ThriftFlip, egress costs would dominate your storage bill on S3 or Supabase Storage. R2's 10GB free tier is 10x Supabase's 1GB. The S3-compatible API means presigned URLs work identically. Cloudflare's CDN is included for free. Image transformations at $0.50/1K (with 5K free) replace the need for a resize pipeline. The only trade-off is managing a separate service from Supabase, but the cost savings justify it.

---

## 4. Hosting for FastAPI

### Provider Comparison

| Feature | Railway | Render | Fly.io |
|---|---|---|---|
| **Free tier** | $5 credit (Trial) | Free tier (750 hrs/mo, sleeps after 15 min) | Free allowances (~3 shared VMs) |
| **Cheapest always-on** | ~$5/mo (Hobby plan, usage-based) | $7/mo (Starter: 512MB, 0.5 CPU) | ~$2.32/mo (shared-1x, 256MB) |
| **Cold starts** | None (always-on) | None on paid tiers; 30-50s on free tier | None (Machines stay running) or auto-stop/start |
| **Auto-scaling** | Manual (or scale with usage-based billing) | Manual instance count | Yes (Fly Autoscaler, metrics-based) |
| **Background workers** | Separate service (same project) | Background Workers ($7/mo+) | Process groups (web + worker in same app) |
| **Pricing model** | $5/mo + $0.000463/min vCPU + $0.000231/min/GB RAM | Flat monthly per instance size | Per-second usage-based |
| **Deploy method** | Git push or Dockerfile | Git push or Dockerfile | Dockerfile (flyctl deploy) |
| **Region options** | Limited | Oregon, Ohio, Frankfurt, Singapore | 35+ regions globally |

### Cost at Different Traffic Levels

**Assumptions:** FastAPI with 1 Uvicorn worker, ~50ms average response time, 256MB-512MB RAM.

| Traffic Level | Railway | Render | Fly.io |
|---|---|---|---|
| **100 req/day** | ~$5/mo (Hobby, minimal usage within credits) | $7/mo (Starter) | ~$3.50/mo (shared-1x 256MB + vol) |
| **1,000 req/day** | ~$7/mo (slightly above Hobby credits) | $7/mo (Starter sufficient) | ~$3.50/mo (same instance handles it) |
| **10,000 req/day** | ~$12-15/mo (Pro plan advisable) | $7-25/mo (may need Standard: 2GB) | ~$7-14/mo (shared-2x 512MB or dedicated) |
| **100,000 req/day** | ~$30-50/mo | $85/mo (Pro: 4GB, 2 CPU) | ~$30-60/mo (performance-1x) |

### Always-On vs Cold Start Implications

For ThriftFlip, cold starts are unacceptable for the scan API (users expect near-instant response after taking a photo). All three platforms support always-on on paid tiers:

- **Railway:** Always-on by default on Hobby/Pro. No cold starts.
- **Render:** Always-on on all paid tiers ($7/mo+). Free tier sleeps after 15 minutes of inactivity (30-50 second cold start).
- **Fly.io:** Can configure machines to stay running or auto-stop. For always-on, just run a single machine 24/7. For cost optimization, use auto-stop/auto-start (sub-second wake-up via Fly Proxy).

### Background Job Support

- **Railway:** Deploy a separate service in the same project for workers. Both services share the same internal network. You would run your ARQ worker as a separate Railway service.
- **Render:** Native Background Workers as a service type. Same pricing as web services. Supports cron jobs (up to 12-hour runtime).
- **Fly.io:** Best option for workers. Use process groups in `fly.toml` to run `web` and `worker` processes in the same app. The worker Machines can auto-stop when the queue is empty and auto-start when jobs arrive. The built-in metrics-based autoscaler can scale workers based on Redis queue depth.

### Recommendation: Fly.io

**Why:** Cheapest always-on option ($2.32/mo base). Process groups let you run web + worker in a single app, simplifying deployment. The metrics-based autoscaler can scale worker Machines based on Redis queue depth — critical when ML inference tasks spike. 35+ global regions mean you can colocate with Supabase's database region. The Fly.io pricing model (per-second billing) means you pay only for what you use, and you can auto-stop worker machines during off-peak hours.

**Runner-up: Render** — if you prefer simplicity over cost optimization. The $7/mo Starter plan is dead simple, and the Background Workers feature is first-class.

---

## 5. Rate Limiting and Quotas

### Implementing "5 Free Scans Per Day"

There are two layers to this: **API-level rate limiting** (protecting against abuse) and **business-logic quota** (the 5-scans-per-day feature limit).

#### Layer 1: API Rate Limiting with slowapi

```python
from fastapi import FastAPI, Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Use Upstash Redis for distributed rate limiting
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri="rediss://default:TOKEN@endpoint.upstash.io:6379",
    default_limits=["100/minute"]  # Global rate limit
)

app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/scans")
@limiter.limit("10/minute")  # Per-user burst limit
async def create_scan(request: Request):
    ...
```

#### Layer 2: Business Quota (5 Scans/Day)

**Calendar day vs rolling 24-hour window:**

| Approach | Pros | Cons |
|---|---|---|
| **Calendar day (midnight UTC reset)** | Simple to implement, predictable for users ("resets at midnight") | Users who join at 11pm get a fresh 5 at midnight |
| **Rolling 24-hour window** | Fairer distribution | More complex, confusing to explain to users |

**Recommendation: Calendar day reset (midnight UTC).** Simpler for users to understand ("You have 3 scans left today"). The edge case of midnight gaming is not worth the complexity for an MVP.

**Implementation with Redis (Upstash):**

```python
import redis.asyncio as redis
from datetime import date

redis_client = redis.from_url("rediss://default:TOKEN@endpoint.upstash.io:6379")

async def check_and_decrement_quota(user_id: str) -> tuple[bool, int]:
    """Returns (allowed, remaining_scans)."""
    key = f"quota:{user_id}:{date.today().isoformat()}"

    # INCR is atomic — safe for concurrent requests
    count = await redis_client.incr(key)

    if count == 1:
        # First scan today — set expiry to end of day + buffer
        await redis_client.expire(key, 90000)  # 25 hours (safety margin)

    if count > 5:
        return False, 0

    return True, 5 - count


@app.post("/scans")
async def create_scan(request: Request, user_id: str = Depends(get_current_user)):
    allowed, remaining = await check_and_decrement_quota(user_id)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail={
                "error": "daily_quota_exceeded",
                "message": "You've used all 5 free scans today. Upgrade for unlimited scans.",
                "remaining": 0,
                "resets_at": "midnight UTC"
            }
        )
    # Proceed with scan...
    return {"remaining_scans": remaining}
```

**Why Redis (Upstash) and not the database?**
- Atomic INCR operations prevent race conditions from concurrent scan requests.
- Sub-millisecond latency (vs ~5ms for a Postgres query).
- Keys auto-expire — no cleanup cron needed.
- Upstash free tier: 500K commands/month. At 10K users x 5 scans/day x 2 commands/scan = 300K/month. Fits within free tier.

### Upstash Redis Pricing

| Tier | Cost | Limits |
|---|---|---|
| **Free** | $0 | 256 MB storage, 500K commands/month |
| **Pay-as-you-go** | $0.20/100K requests | 100 GB storage, first 200GB bandwidth free |
| **Fixed (Pro-250)** | $10/mo | 250 MB, predictable cost |

### slowapi Configuration for ThriftFlip

```python
# Rate limits by endpoint
@app.post("/scans")
@limiter.limit("10/minute", key_func=get_user_id)        # Scan creation
async def create_scan(...): ...

@app.get("/scans/{scan_id}")
@limiter.limit("60/minute", key_func=get_user_id)        # Scan retrieval
async def get_scan(...): ...

@app.post("/scans/{scan_id}/corrections")
@limiter.limit("30/minute", key_func=get_user_id)        # Corrections
async def submit_correction(...): ...

@app.get("/search/similar")
@limiter.limit("20/minute", key_func=get_user_id)        # Similarity search
async def search_similar(...): ...
```

---

## 6. Background Jobs

### Task Queue Comparison

| Feature | ARQ | Celery | Dramatiq |
|---|---|---|---|
| **Async native** | Yes (built on asyncio) | No (sync-first, async bolted on) | No (sync with threading) |
| **Broker** | Redis only | Redis, RabbitMQ, SQS | Redis, RabbitMQ |
| **Complexity** | Minimal | Heavy (many config options) | Moderate |
| **Monitoring** | Basic (arq dashboard) | Flower (mature) | Built-in middleware |
| **Task acknowledgment** | After completion | On pull (bad default, configurable) | After completion (safe default) |
| **Performance** | Good for I/O-bound | Best for CPU-bound at scale | Very good (10x faster than RQ) |
| **Dependencies** | Minimal (redis, asyncio) | Heavy (kombu, billiard, vine) | Moderate |
| **FastAPI fit** | Excellent (both asyncio) | Poor (async mismatch) | Decent |
| **Community size** | Small but growing | Very large | Medium |

### Recommendation: ARQ

**Why ARQ for ThriftFlip:**
1. **Native asyncio** — ARQ is built on asyncio, matching FastAPI's async architecture. No impedance mismatch.
2. **Redis-only** — You already need Redis for rate limiting (Upstash). ARQ uses the same Redis.
3. **Lightweight** — Minimal dependencies, simple configuration. Perfect for an MVP.
4. **I/O-bound tasks** — ThriftFlip's background tasks are mostly I/O (API calls to eBay, uploading to R2, fetching ML results). ARQ's asyncio foundation handles concurrent I/O efficiently.

### What Tasks Should Be Async?

| Task | Sync or Async? | Why |
|---|---|---|
| **Image preprocessing** (resize for ML) | Async (ARQ) | CPU-bound, ~500ms, would block request |
| **ML inference** (FashionCLIP embedding) | Async (ARQ) | GPU/CPU-bound, 1-5 seconds |
| **Brand/item classification** | Async (ARQ) | External API or model inference, 1-3 seconds |
| **Price estimation** (eBay API lookup) | Async (ARQ) | External API call, 500ms-2s, may retry |
| **Image upload to R2** | Sync (presigned URL) | Client uploads directly, no server involvement |
| **Store scan result** | Sync (in request) | Fast DB write, <10ms |
| **Generate thumbnail** | Async (ARQ) or on-demand | Can use Cloudflare transforms on-demand instead |
| **Embedding similarity search** | Sync (in request) | Fast pgvector query, <50ms |

### ARQ Setup for ThriftFlip

```python
# worker.py
from arq import create_pool
from arq.connections import RedisSettings

REDIS_SETTINGS = RedisSettings(
    host='endpoint.upstash.io',
    port=6379,
    password='TOKEN',
    ssl=True
)

async def process_scan(ctx, scan_id: str, image_key: str):
    """Main scan processing pipeline."""
    try:
        # 1. Download image from R2
        image_bytes = await download_from_r2(image_key)

        # 2. Preprocess for ML
        processed = resize_for_ml(image_bytes)

        # 3. Generate FashionCLIP embedding
        embedding = await generate_embedding(processed)

        # 4. Classify brand/category/condition
        classification = await classify_item(processed)

        # 5. Estimate price via eBay API
        price_range = await estimate_price(
            brand=classification['brand'],
            category=classification['category'],
            condition=classification['condition']
        )

        # 6. Store results in Postgres
        await update_scan_result(scan_id, classification, price_range)
        await store_embedding(scan_id, embedding)

        # 7. Update scan status
        await update_scan_status(scan_id, 'completed')

    except Exception as e:
        await update_scan_status(scan_id, 'failed', error=str(e))
        raise  # ARQ will retry based on settings

async def estimate_price(ctx, brand: str, category: str, condition: str):
    """Separate job for eBay price lookup (can be retried independently)."""
    ...

class WorkerSettings:
    functions = [process_scan, estimate_price]
    redis_settings = REDIS_SETTINGS
    max_jobs = 10           # Concurrent jobs per worker
    job_timeout = 300       # 5 minutes max per job
    max_tries = 3           # Retry failed jobs up to 3 times
    retry_defer = 5.0       # Wait 5 seconds between retries
    health_check_interval = 30
```

### Job Retry and Failure Handling

```python
# Custom retry logic for external API calls
async def estimate_price(ctx, scan_id: str, brand: str, category: str):
    """eBay price lookup with exponential backoff."""
    attempt = ctx.get('job_try', 1)

    try:
        prices = await ebay_api.search_completed(
            query=f"{brand} {category}",
            condition=condition
        )
        await update_scan_prices(scan_id, prices)
    except EbayRateLimitError:
        if attempt < 3:
            # Exponential backoff: 30s, 60s, 120s
            defer = 30 * (2 ** (attempt - 1))
            raise Retry(defer=defer)
        else:
            # After 3 attempts, mark as needs-manual-pricing
            await update_scan_status(scan_id, 'partial', note='price_lookup_failed')
    except Exception as e:
        await log_job_failure(scan_id, 'estimate_price', str(e))
        raise
```

---

## 7. User Correction Loop

### Design Philosophy: Append-Only Audit Log

**Why append-only (not update-in-place):**

1. **Full history** — You can see every correction a user made, enabling analysis of which ML predictions are systematically wrong.
2. **Training data** — Each correction is a labeled training example: `(image, field, wrong_value, right_value)`.
3. **No data loss** — If a user corrects something, then corrects it again, you have both data points.
4. **Compliance** — Append-only logs are easier to audit and harder to tamper with.

### Schema (from Section 2, detailed here)

```sql
CREATE TABLE public.corrections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,          -- 'brand', 'category', 'size', 'condition', 'color', 'material'
    original_value TEXT,               -- What the ML model predicted
    corrected_value TEXT NOT NULL,     -- What the user says it should be
    confidence_at_prediction FLOAT,   -- Model's confidence when it made the prediction
    source TEXT DEFAULT 'user',       -- 'user', 'admin', 'model_v2' (for re-predictions)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Never UPDATE or DELETE. Only INSERT.
-- Index for analyzing systematic errors:
CREATE INDEX idx_corrections_field_original
    ON public.corrections(field_name, original_value);
CREATE INDEX idx_corrections_field_corrected
    ON public.corrections(field_name, corrected_value);

-- Materialized view for "latest corrected value per scan per field"
CREATE MATERIALIZED VIEW public.scan_corrected_values AS
SELECT DISTINCT ON (scan_id, field_name)
    scan_id,
    field_name,
    corrected_value AS current_value,
    created_at AS corrected_at
FROM public.corrections
ORDER BY scan_id, field_name, created_at DESC;

-- Refresh periodically or via trigger
CREATE INDEX idx_corrected_values_scan ON public.scan_corrected_values(scan_id);
```

### API Design for Corrections

```python
from pydantic import BaseModel
from typing import Optional

class CorrectionRequest(BaseModel):
    field_name: str  # 'brand', 'category', 'size', etc.
    corrected_value: str

class ScanWithCorrections(BaseModel):
    id: str
    predicted_brand: str
    predicted_category: str
    # ... other predicted fields
    corrections: dict[str, str]  # field_name -> latest corrected value
    # The display layer shows corrected values where they exist,
    # falling back to predicted values.

@app.post("/scans/{scan_id}/corrections")
async def submit_correction(
    scan_id: str,
    correction: CorrectionRequest,
    user_id: str = Depends(get_current_user)
):
    # Fetch current predicted value
    scan = await get_scan(scan_id)
    original_value = getattr(scan, f"predicted_{correction.field_name}", None)

    # Insert correction (append-only)
    await db.execute("""
        INSERT INTO corrections (scan_id, user_id, field_name, original_value,
                                 corrected_value, confidence_at_prediction)
        VALUES ($1, $2, $3, $4, $5, $6)
    """, scan_id, user_id, correction.field_name, original_value,
         correction.corrected_value, scan.confidence_score)

    # Refresh materialized view (or do this on a schedule)
    await db.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY scan_corrected_values")

    return {"status": "correction_saved"}
```

### Using Corrections to Improve Future Scans

#### Short-term: Correction-Weighted Results

```python
async def get_brand_correction_stats():
    """Find brands that are systematically misidentified."""
    return await db.fetch("""
        SELECT original_value AS predicted_brand,
               corrected_value AS actual_brand,
               COUNT(*) AS correction_count
        FROM corrections
        WHERE field_name = 'brand'
        GROUP BY original_value, corrected_value
        HAVING COUNT(*) >= 3
        ORDER BY correction_count DESC
    """)
    # Example output:
    # predicted: "Zara" -> actual: "H&M" (15 corrections)
    # predicted: "Nike" -> actual: "Adidas" (8 corrections)
    # Use this to build a correction map for post-processing
```

#### Medium-term: Fine-tuning Pipeline

```python
async def export_training_data():
    """Export corrections as training data for model fine-tuning."""
    return await db.fetch("""
        SELECT s.image_url,
               c.field_name,
               c.original_value AS model_prediction,
               c.corrected_value AS ground_truth,
               c.confidence_at_prediction
        FROM corrections c
        JOIN scans s ON s.id = c.scan_id
        WHERE c.source = 'user'
        ORDER BY c.created_at
    """)
    # Output: labeled dataset for fine-tuning
    # (image_url, "brand", "Zara", "H&M", 0.72)
    # This becomes training data for the next model version
```

#### Long-term: Correction-Based Post-Processing

```python
# Maintain an in-memory correction map (refreshed hourly)
CORRECTION_MAP = {}  # {("brand", "Zara"): {"H&M": 15, "Zara": 200}}

async def apply_correction_heuristics(prediction: dict) -> dict:
    """Post-process ML predictions using accumulated corrections."""
    brand = prediction['brand']
    key = ("brand", brand)
    if key in CORRECTION_MAP:
        corrections = CORRECTION_MAP[key]
        total = sum(corrections.values())
        # If >30% of users correct this brand to something else...
        for corrected_brand, count in corrections.items():
            if corrected_brand != brand and count / total > 0.3:
                prediction['brand'] = corrected_brand
                prediction['brand_source'] = 'correction_heuristic'
                break
    return prediction
```

---

## 8. Cost Analysis

### Assumptions

- Each scan: ~2MB original image, ~200KB thumbnail
- Each user: 5 scans/day
- 30 days/month
- ML inference on server (FashionCLIP + classification)
- eBay API calls for pricing

### 100 Users (500 scans/day = 15,000 scans/month)

| Service | Provider | Monthly Cost |
|---|---|---|
| **Auth** | Supabase Auth (free tier, <50K MAU) | $0 |
| **Database** | Supabase Postgres (free tier, 500MB) | $0 |
| **Image Storage** | Cloudflare R2 (15K x 2.2MB = ~33GB stored cumulative after month 1, growing) | ~$0.50 |
| **Image Egress** | Cloudflare R2 (zero egress) | $0 |
| **R2 Operations** | ~30K PUTs + ~150K GETs/mo | ~$0.20 |
| **Cloudflare Transforms** | ~3 sizes x 15K = 45K unique (beyond 5K free) | ~$20 |
| **FastAPI Hosting** | Fly.io (shared-1x, 256MB, always-on) | ~$3.50 |
| **Background Worker** | Fly.io (shared-1x, 256MB, auto-stop) | ~$2-5 |
| **Redis** | Upstash (free tier, ~150K commands) | $0 |
| **Image Transforms** | Use Cloudflare on-demand | (included above) |
| **eBay API** | Free tier (5,000 calls/day) | $0 |
| **TOTAL** | | **~$26-29/month** |

**Note:** Month 1 image storage is ~33GB. By month 6 it is ~200GB, costing ~$3/mo. The Supabase free tier 500MB database will last several months at this scale (~2KB per scan record + embeddings).

### 1,000 Users (5,000 scans/day = 150,000 scans/month)

| Service | Provider | Monthly Cost |
|---|---|---|
| **Auth** | Supabase Auth (free tier, <50K MAU) | $0 |
| **Database** | Supabase Pro ($25/mo, 8GB — needed for pgvector at this scale) | $25 |
| **Image Storage** | Cloudflare R2 (~330GB stored after month 1, growing) | ~$5 |
| **Image Egress** | Cloudflare R2 (zero egress) | $0 |
| **R2 Operations** | ~300K PUTs + ~1.5M GETs/mo | ~$2 |
| **Cloudflare Transforms** | ~450K unique transforms | ~$225 |
| **FastAPI Hosting** | Fly.io (shared-2x, 512MB or dedicated-cpu-1x) | ~$7-15 |
| **Background Worker** | Fly.io (dedicated-cpu-1x for ML inference) | ~$15-30 |
| **Redis** | Upstash (pay-as-you-go, ~1.5M commands) | ~$3 |
| **eBay API** | Free tier (5,000 calls/day — may need batching) | $0 |
| **TOTAL** | | **~$282-305/month** |

**Cost optimization:** Reduce Cloudflare Transforms cost by pre-generating only 2 sizes (thumbnail + display) via background job instead of on-demand, using Pillow. This drops transforms to near-zero, saving ~$200/mo. Revised total: **~$57-80/month**.

### 10,000 Users (50,000 scans/day = 1,500,000 scans/month)

| Service | Provider | Monthly Cost |
|---|---|---|
| **Auth** | Supabase Pro (included in $25, up to 100K MAU) | $0 (included) |
| **Database** | Supabase Pro ($25 base + compute overage for pgvector) | ~$50-100 |
| **Image Storage** | Cloudflare R2 (~3.3TB stored after month 1) | ~$50 |
| **Image Egress** | Cloudflare R2 (zero egress) | $0 |
| **R2 Operations** | ~3M PUTs + ~15M GETs/mo | ~$19 |
| **Image Resizing** | Pillow in background worker (pre-generate 2 sizes) | $0 (compute cost below) |
| **FastAPI Hosting** | Fly.io (2x dedicated-cpu-1x, 1GB each) | ~$60 |
| **Background Workers** | Fly.io (3x dedicated-cpu-1x for ML + resize) | ~$90 |
| **Redis** | Upstash (pay-as-you-go, ~15M commands) | ~$30 |
| **eBay API** | May need paid tier or smart caching | $0-50 |
| **TOTAL** | | **~$299-399/month** |

### Cost Cliffs — When You Must Upgrade

| Trigger | What Happens | Action Required | New Cost |
|---|---|---|---|
| **DB > 500MB** | Supabase free tier full | Upgrade to Supabase Pro ($25/mo) | +$25/mo |
| **MAU > 50K** | Supabase auth overage | $0.00325/MAU beyond 100K on Pro | Variable |
| **R2 > 10GB stored** | Beyond R2 free tier | $0.015/GB (already cheap) | Gradual |
| **Redis > 500K commands/mo** | Upstash free tier limit | Pay-as-you-go ($0.20/100K) | +$1-30/mo |
| **ML inference latency** | Shared CPU too slow | Upgrade to dedicated CPU on Fly.io | +$15-30/mo |
| **pgvector > 1M embeddings** | Query latency increases | Add Supabase compute add-on or optimize indexes | +$25-50/mo |
| **50K+ scans/day** | Single worker can't keep up | Add more Fly.io worker Machines | +$30/worker |
| **eBay API > 5K calls/day** | Free tier exceeded | Cache aggressively or upgrade eBay API tier | Variable |

### Cost Summary Chart

```
Monthly Cost Trajectory:

$400 |                                              xxxxxxx  10,000 users
     |                                        xxxxx
$300 |                                   xxxxx
     |                              xxxxx
$200 |
     |
$100 |                   xxxxxxxxx  1,000 users (optimized)
     |              xxxxx
 $50 |         xxxxx
     |    xxxxx
 $25 | xxx  100 users
     |x
  $0 +-----|------|------|------|------|-----> months
     0     1      2      3      4      5
```

---

## 9. Architectural Recommendation

### Recommended Stack for ThriftFlip MVP

```
+------------------+     +-------------------+     +------------------+
|   iOS App        |     |   FastAPI on       |     |   Supabase       |
|   (SwiftUI)      |<--->|   Fly.io           |<--->|   (Postgres +    |
|                  |     |                   |     |    Auth + RLS)   |
|  - supabase-swift|     |  - Uvicorn        |     |  - pgvector      |
|  - Apple Sign-In |     |  - slowapi        |     |  - 500MB free    |
|  - URLSession    |     |  - ARQ workers    |     |                  |
+------------------+     +-------------------+     +------------------+
        |                        |
        |                        |
        v                        v
+------------------+     +------------------+
| Cloudflare R2    |     | Upstash Redis    |
| (Image Storage)  |     | (Rate Limits +   |
|                  |     |  Job Queue)      |
| - Zero egress    |     | - 500K free/mo   |
| - 10GB free      |     | - ARQ broker     |
| - CDN included   |     |                  |
+------------------+     +------------------+
```

### Why This Stack?

1. **Supabase** — One platform for auth (50K MAU free), Postgres (with pgvector), and RLS. The Swift SDK provides native Apple Sign-In and anonymous auth. You get auth + database + row-level security in a single service with a single bill.

2. **Cloudflare R2** — Zero egress fees save hundreds of dollars per month at scale. The 10GB free tier is generous. Presigned URL uploads keep images off your FastAPI server. Cloudflare's CDN is included.

3. **Fly.io** — Cheapest always-on hosting ($2.32/mo base). Process groups let you run web + worker in one app. Metrics-based autoscaling for background workers. 35+ global regions. Per-second billing means you pay only for actual usage.

4. **Upstash Redis** — Free 500K commands/month covers rate limiting + job queue for the MVP. Serverless — no server to manage. Works as both slowapi backend and ARQ broker.

5. **ARQ** — Native asyncio task queue, perfect for FastAPI. Lightweight, minimal dependencies. Uses the same Upstash Redis you already need for rate limiting.

### Day-One MVP Cost: ~$0/month

On free tiers alone, you can run ThriftFlip for 0-100 users:
- Supabase Free: Auth + DB + 500MB ($0)
- Cloudflare R2: 10GB images ($0)
- Fly.io: Free tier allowances ($0)
- Upstash: 500K commands ($0)

### First Upgrade: ~$32/month

When you hit ~500 users or 500MB database:
- Supabase Pro: $25/mo
- Fly.io: Shared instance always-on: ~$3.50/mo
- Fly.io: Worker instance: ~$3.50/mo
- Everything else: still free tier

### Scale to 10K users: ~$300-400/month

All services at paid tiers, multiple worker instances, dedicated CPUs for ML inference. Still dramatically cheaper than the equivalent AWS/GCP setup.

---

## Sources

### Authentication
- [Supabase Pricing](https://supabase.com/pricing)
- [Firebase Auth Pricing](https://firebase.google.com/pricing)
- [Auth0 Pricing](https://auth0.com/pricing)
- [Supabase Anonymous Sign-Ins](https://supabase.com/docs/guides/auth/auth-anonymous)
- [Firebase Anonymous Auth on iOS](https://firebase.google.com/docs/auth/ios/anonymous-auth)
- [Supabase Apple Sign-In](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Firebase Apple Sign-In on iOS](https://firebase.google.com/docs/auth/ios/apple)
- [Auth0 Apple Sign-In Native](https://auth0.com/docs/connections/social/apple-native)
- [Auth0.swift SDK](https://github.com/auth0/Auth0.swift)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Supabase Native Mobile Auth](https://supabase.com/blog/native-mobile-auth)

### Database
- [Neon Serverless Postgres Pricing 2026](https://vela.simplyblock.io/articles/neon-serverless-postgres-pricing-2026/)
- [Neon pgvector Extension](https://neon.com/docs/extensions/pgvector)
- [PlanetScale Pricing](https://planetscale.com/pricing)
- [PlanetScale Postgres Launch](https://www.infoq.com/news/2025/10/planetscale-metal-postgres/)
- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [pgvector 150x Speedup Review](https://jkatz05.com/post/postgres/pgvector-performance-150x-speedup/)
- [pgvector 0.8.0 on Aurora](https://aws.amazon.com/blogs/database/supercharging-vector-search-performance-and-relevance-with-pgvector-0-8-0-on-amazon-aurora-postgresql/)
- [FashionCLIP GitHub](https://github.com/patrickjohncyh/fashion-clip)
- [FashionCLIP for Product Similarity](https://www.width.ai/post/product-similarity-search-with-fashion-clip)
- [Supabase RLS Documentation](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase RLS Best Practices](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices)

### Image Storage
- [Cloudflare R2 Pricing](https://developers.cloudflare.com/r2/pricing/)
- [Cloudflare R2 Presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/)
- [Cloudflare Images Pricing](https://developers.cloudflare.com/images/pricing/)
- [AWS S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [Supabase Storage Pricing](https://supabase.com/docs/guides/storage/pricing)
- [R2 vs S3 Comparison](https://www.pump.co/blog/cloudflare-vs-s3)
- [Migration from Supabase Storage to R2](https://medium.com/@vishalsharma05052002/how-i-saved-300-year-by-migrating-from-supabase-storage-to-cloudflare-r2-f503d57b0732)

### Hosting
- [Railway Pricing](https://railway.com/pricing)
- [Railway Pricing Docs](https://docs.railway.com/reference/pricing/plans)
- [Render Pricing](https://render.com/pricing)
- [Render Background Workers](https://render.com/docs/background-workers)
- [Fly.io Pricing](https://fly.io/pricing/)
- [Fly.io Resource Pricing](https://fly.io/docs/about/pricing/)
- [Fly.io Python Async Workers](https://fly.io/blog/python-async-workers-on-fly-machines/)
- [Fly.io Autoscale by Metric](https://fly.io/docs/launch/autoscale-by-metric/)
- [Railway vs Render vs Fly.io Comparison](https://medium.com/ai-disruption/railway-vs-fly-io-vs-render-which-cloud-gives-you-the-best-roi-2e3305399e5b)

### Rate Limiting
- [Upstash Redis Pricing](https://upstash.com/pricing/redis)
- [Upstash New Pricing Announcement](https://upstash.com/blog/redis-new-pricing)
- [slowapi GitHub](https://github.com/laurentS/slowapi)
- [Rate Limiting FastAPI with Redis](https://bryananthonio.com/blog/implementing-rate-limiter-fastapi-redis/)
- [Upstash Python Rate Limiting](https://upstash.com/docs/redis/tutorials/python_rate_limiting)

### Background Jobs
- [ARQ Documentation](https://arq-docs.helpmanual.io/)
- [ARQ GitHub](https://github.com/python-arq/arq)
- [FastAPI + ARQ Comparison](https://davidmuraya.com/blog/fastapi-background-tasks-arq-vs-built-in/)
- [Celery vs ARQ](https://leapcell.io/blog/celery-versus-arq-choosing-the-right-task-queue-for-python-applications)
- [Python Task Queue Benchmarks](https://stevenyue.com/blogs/exploring-python-task-queue-libraries-with-load-test)
- [Python Background Tasks 2025 Comparison](https://devproportal.com/languages/python/python-background-tasks-celery-rq-dramatiq-comparison-2025/)

### User Correction Loop
- [AI Feedback Loops](https://www.clarifai.com/blog/closing-the-loop-how-feedback-loops-help-to-maintain-quality-long-term-ai-results)
- [Building ML Pipelines - Feedback Loops](https://www.oreilly.com/library/view/building-machine-learning/9781492053187/ch13.html)
