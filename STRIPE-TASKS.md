# Stripe — your three tasks (plain English)

Everything on the Convex side is done. Three Stripe-dashboard tasks
remain. They only take a few minutes. Do them in this order.

---

## Task 1 — Enable "card" in the payment method settings

The account's default payment-method configuration is **empty**, so the
apps' checkout pages can't show any payment method (that's the "No valid
payment method types" error). Card payments *work* when explicitly
requested, so this one toggle unlocks everything.

**Clicks:**

1. Go to `https://dashboard.stripe.com/settings/payment_methods`
2. Find the **card** payment method.
3. Toggle it **ON** (Enable).
4. There may be a "Payment method configurations" panel — make sure the
   **default** configuration has card enabled.
5. Scroll down and save if prompted.

**How to know it worked:** run this — it should print `card: True`:

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
SK=$(grep '^STRIPE_SECRET_KEY=' .env.wire | cut -d= -f2-)
curl -s "https://api.stripe.com/v1/payment_method_configurations" -u "$SK:" | python3 -c "
import json,sys
for c in json.load(sys.stdin).get('data',[]):
    print(c['id'], '| card enabled:', c['payment_methods'].get('card',{}).get('enabled'))"
```

---

## Task 2 — Grant the key permission to create prices

The `rk_live_…` key can create products but not prices (Stripe blocks it:
"Enabling Prices Write ('plan_write') permissions on this key…").

**Option A (recommended): grant the permission**

1. Open the exact link Stripe gave:
   `https://dashboard.stripe.com/apikeys`
   (it may be
   `https://dashboard.stripe.com/b/acct_1U8PMsHWfIhAnbX5?destination=%2Fapikeys%2Fmk_1U9UUrHWfIhAnbX5Mr8TlXIZ%2Fedit`)
2. Find the key (the one starting `rk_live_…`).
3. Edit its permissions → enable **Prices** → **Write** (`plan_write`).
4. Save.

**Option B: use a full secret key once**

Paste an `sk_live_…` key to me (or run the command below yourself) and
we rotate it tonight anyway.

**Once granted — run the price script** (creates the 3 prices and sets
them on the deployments):

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
bash create-prices.sh
```

Expected output: three `price_…` IDs, then `DONE`.

---

## Task 3 — KitchenOS Organizations (Clerk, 30 seconds)

KitchenOS bills per kitchen, and each kitchen is a Clerk Organization.
The app needs the feature enabled:

1. `https://dashboard.clerk.com` → app **loved-gobbler-9439**
2. **Configure → Organizations**
3. Toggle **Enable organizations**
4. Save.

---

## After all three

Tell me (or run) and I'll verify end-to-end:

```bash
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
bash verify-wiring.sh
```

Then the real test: open any app, sign in, click Upgrade/Buy, pay with a
**real** card (the `4242…` test card only works in test mode), and confirm
the Pro/Premium badge unlocks — that proves the whole loop (checkout →
webhook → Convex → badge) works with live money.

---

## Key rotation reminder

The keys shared in chat (Stripe `rk_live_…` + `whsec_…`, GitHub PAT,
Clerk `sk_test_…`) are compromised. **Rotation is on the calendar for
tonight 20:00.** After rotating, update `.env.wire` and run
`verify-wiring.sh` again.
