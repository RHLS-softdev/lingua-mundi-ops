# GO-LIVE: wiring the commercial layer end-to-end

One shared Clerk application + one Convex deployment per product + one
Stripe account. The **Stripe webhook is the ONLY path that grants paid
access** in every product — this is intentional and never changes.

## 0. Accounts you need (have them open in three tabs)

| Service | What you need | Where to find it |
|---|---|---|
| **Clerk** | `CLERK_SECRET_KEY` (`sk_test_…`) | dashboard.clerk.com → Application `loved-gobbler-9439` → API Keys |
| **Convex** | your login (browser) | dashboard.convex.dev — `npx convex login` handles it |
| **Stripe** | `STRIPE_SECRET_KEY` (`sk_test_…`), `STRIPE_WEBHOOK_SECRET` (`whsec_test_…`) | dashboard.stripe.com → Developers → API keys / Webhooks |

Shared values (already wired in the code):

- Clerk app: **`loved-gobbler-9439`** — one identity across all products
- Issuer domain (same for every product): `https://loved-gobbler-9439.clerk.accounts.dev`
- Clerk JWT template named **`convex`** already exists in that app (created for Lingua Mundi)
- Clerk publishable key: `pk_test_bG92ZWQtZ29iYmxlci05NDM5LmNsZXJrLmFjY291bnRzLmRldiQ`
  (already in every product's `.env.local`)

---

## 1. Subtitle Toolkit Pro — $9 one-time

Working dir: `.subtitle-toolkit-build`

### 1a. Convex deployment (creates the project the first time)

```bash
cd ".subtitle-toolkit-build"
npx convex login          # opens browser once
npx convex deploy         # creates/deploys project
```

Copy the printed URL (`https://<something>.convex.cloud`) into
`.env.local`:

```bash
# .env.local  →  VITE_CONVEX_URL=https://<something>.convex.cloud
```

Set the backend env vars (they live on the Convex deployment, not in
the repo):

```bash
npx convex env set CLERK_JWT_ISSUER_DOMAIN https://loved-gobbler-9439.clerk.accounts.dev
npx convex env set STRIPE_SECRET_KEY sk_test_…
npx convex env set STRIPE_WEBHOOK_SECRET whsec_test_…
npx convex env set DASHBOARD_URL https://rhls-softdev.github.io/subtitle-toolkit-launch/app
# optional — if unset, checkout uses an inline $9 one-time price:
npx convex env set STRIPE_PRO_PRICE_ID price_…
```

### 1b. Stripe webhook

Dashboard → Developers → Webhooks → **Add endpoint**:

- URL: `https://<your-deployment>.convex.site/stripe/webhook`
- Events: **`checkout.session.completed`** (that's the only one this
  product's webhook reads — one-time payment, no subscriptions)
- Copy the signing secret into `STRIPE_WEBHOOK_SECRET` above.

### 1c. Clerk origin

Register the app origin (or export `CLERK_SECRET_KEY` and let
`deploy-subtitle-toolkit.sh` do it):

```bash
curl -X PATCH https://api.clerk.com/v1/instance \
  -H "Authorization: Bearer $CLERK_SECRET_KEY" -H "Content-Type: application/json" \
  -d '{"allowed_origins":["https://rhls-softdev.github.io/subtitle-toolkit-launch/app/"]}'
```

### 1d. Rebuild + redeploy the frontend

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
GH_TOKEN=github_pat_… bash deploy-subtitle-toolkit.sh
```

This rebuilds the app with `--base=/subtitle-toolkit-launch/app/`, pushes
to GitHub Pages, and (with `CLERK_SECRET_KEY` exported) registers the
Clerk origin.

### 1e. Verify

1. Open `https://rhls-softdev.github.io/subtitle-toolkit-launch/app/`
2. Sign in with Clerk (any account)
3. Click **Upgrade to Pro ($9)** → Stripe Checkout opens
4. Pay with test card `4242 4242 4242 4242` (any future date, any CVC)
5. You land back on `…/app/#pro`; the Pro badge unlocks only after the
   webhook fires (check `convex/purchases.ts` rows in the Convex
   dashboard — a `purchases` doc appears).

---

## 2. KitchenOS Premium — $50/mo per kitchen

Working dir: `.kitchenos-build/enterprise`

### 2a. Convex deployment

```bash
cd ".kitchenos-build/enterprise"
npx convex login          # same Convex account
npx convex deploy
```

Copy the URL into `enterprise/.env.local` → `VITE_CONVEX_URL`.

Backend env vars:

```bash
npx convex env set CLERK_JWT_ISSUER_DOMAIN https://loved-gobbler-9439.clerk.accounts.dev
npx convex env set STRIPE_SECRET_KEY sk_test_…
npx convex env set STRIPE_WEBHOOK_SECRET whsec_test_…
npx convex env set DASHBOARD_URL https://rhls-softdev.github.io/kitchenos-launch/premium
# optional — if unset, checkout uses an inline $50/mo recurring price:
npx convex env set STRIPE_PREMIUM_PRICE_ID price_…
```

### 2b. Stripe webhook

Dashboard → Webhooks → **Add endpoint**:

- URL: `https://<your-deployment>.convex.site/stripe/webhook`
- Events (this product's webhook reads all three):
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
- Signing secret → `STRIPE_WEBHOOK_SECRET`.

### 2c. Clerk

- Same shared app; **Organizations must be enabled** (Dashboard →
  Configure → Organizations). Each kitchen is one Clerk Organization,
  and the checkout requires an active org (`identity.org_id`).
- Register origin `https://rhls-softdev.github.io/kitchenos-launch/premium/`
  (or export `CLERK_SECRET_KEY` and run `deploy-kitchenos.sh`).

### 2d. Rebuild + redeploy

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
GH_TOKEN=github_pat_… bash deploy-kitchenos.sh
```

### 2e. Verify

1. Open `https://rhls-softdev.github.io/kitchenos-launch/premium/`
2. Sign in → **Create your kitchen** (creates a Clerk org)
3. Click **Upgrade to Premium — $50/mo** → Stripe Checkout
4. Pay with `4242 4242 4242 4242`
5. The plan row flips Free → Premium after the webhook fires; canceling
   in Stripe drops it back to Free on `customer.subscription.deleted`.

---

## 3. Lingua Mundi — dashboard already live

Convex deployment **already live**: `dusty-turtle-795.convex.cloud`.
Frontend `.env.local` already points there. What's missing is the
backend env vars + the pricing decision (Phase 0).

Working dir: `LinguaMundi/lingua-mundi/commercial`

### 3a. Backend env vars

```bash
cd "LinguaMundi/lingua-mundi/commercial"
npx convex env set CLERK_JWT_ISSUER_DOMAIN https://loved-gobbler-9439.clerk.accounts.dev
npx convex env set STRIPE_SECRET_KEY sk_test_…
npx convex env set STRIPE_WEBHOOK_SECRET whsec_test_…
npx convex env set DASHBOARD_URL https://rhls-softdev.github.io/lingua-mundi-launch/dashboard
npx convex env set STRIPE_PRO_PRICE_ID price_…          # REQUIRED — checkout throws if unset
npx convex env set LINGUA_MUNDI_API_URL https://<your-api-host>   # FastAPI host
npx convex env set LINGUA_MUNDI_INTERNAL_SECRET <secret>          # must match api/settings.py
```

`LINGUA_MUNDI_INTERNAL_SECRET` must equal the value the FastAPI side
checks (`api/routes/internal.py` reads header `x-internal-secret` via
`require_internal_secret`). Set the same value on both sides.

### 3b. Stripe webhook

Dashboard → Webhooks → **Add endpoint** at
`https://dusty-turtle-795.convex.site/stripe/webhook` with the same
three events as KitchenOS (`checkout.session.completed`,
`customer.subscription.updated`, `customer.subscription.deleted`).

### 3c. Price decision (Phase 0 — your call)

Before selling: pick the Pro price point and whether free users get
analysis keys. `lingua-mundi-phase0-freeze.md` in the workspace has the
full decision sheet. The checkout needs a recurring Price in Stripe for
`STRIPE_PRO_PRICE_ID`.

### 3d. Redeploy frontend (after price/env changes)

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
GH_TOKEN=github_pat_… bash deploy-to-github-pages.sh
```

---

## 4. KitchenOS desktop .deb (bonus)

```bash
sudo dpkg -i "/home/rex/Documentos/Software Development/DeepSeek Harness/KitchenOS-0.6.0-linux-amd64.deb"
```

---

## 5. Go-live checklist (test → real money)

Everything above uses **test mode** (`sk_test_`, `whsec_test_`, card
`4242…`). To actually sell:

1. **Stripe**: flip to Live (Dashboard → toggle). Create live Prices;
   copy `sk_live_…` and the **live** webhook signing secret
   (`whsec_live_…`) into the same `npx convex env set` vars (overwrites
   the test values). Register the live webhook endpoint at the same
   `*.convex.site/stripe/webhook` URLs.
2. **Clerk**: when ready, switch the `loved-gobbler-9439` instance from
   Development to Production (Dashboard → instance settings) — that
   changes nothing in the code, just lifts the dev-mode limits/banner.
3. Re-run the three `deploy-*.sh` scripts so the frontends rebuild with
   the live Convex URLs.
4. **Buy it yourself first**: run one real card purchase per product,
   watch the webhook row appear in Convex, confirm the badge unlocks.
5. Re-verify the links audit (`audit-links.sh`) so every download/checkout
   link still resolves.

## Order of operations (recommended)

1. Convex deploy: KitchenOS → Subtitle Toolkit (LM already done)
2. Set all `npx convex env set` vars per product
3. Create Stripe webhooks + price IDs
4. Register Clerk origins (or run deploy scripts with `CLERK_SECRET_KEY`)
5. Redeploy all three frontends
6. Test purchases with `4242…` on all three
7. KitchenOS .deb install
8. Flip to live keys + production Clerk when ready
