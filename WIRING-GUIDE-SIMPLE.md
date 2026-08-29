# How to Turn On Selling in Your Apps — Plain-English Guide

*(For the technical version with all the details, see `WIRING-GUIDE.md`.)*

This guide explains, in everyday words, how to connect your three apps to
the services that make them take money. Anyone can follow it — you do not
need to be a programmer. Some steps ask you to paste a command into the
"terminal" (the black window on your computer). That's okay: copy the
whole line, paste it, press Enter. The instructions tell you exactly what
to change.

---

## The big picture in one minute

Your apps are built and online. What's missing is connecting each app to
three outside services. Think of them like this:

| Service | Real name | What it is, in plain words |
|---|---|---|
| **The ID system** | Clerk | Issues the "Sign in with Google/email" button. One ID works in all your apps. |
| **The filing cabinet** | Convex | Remembers things, like "this person paid for Pro." Each app gets its own cabinet. |
| **The cash register** | Stripe | Takes the credit card payment and (via a "mailman") tells the filing cabinet that payment happened. |

**The one rule that never changes:** a payment is only real when the
cash register's mailman (the *webhook*) tells the filing cabinet. Nobody
gets Pro/Premium any other way. This keeps the system honest.

---

## Before you start: gather your three accounts and two codes

Have these three websites open in browser tabs (all free to create):

1. **Clerk** — `dashboard.clerk.com`
2. **Stripe** — `dashboard.stripe.com`
3. **Convex** — `dashboard.convex.dev`

You already have a Clerk account called **lovely-gobbler-9439**. All three
apps share it, so you only ever need ONE Clerk account. Good.

**The two codes you'll need from each service** (they look like random
gibberish — that's normal, treat them like passwords):

- From **Stripe**: a secret key (starts with `sk_test_…`) and a webhook
  secret (starts with `whsec_test_…`).
- From **Clerk**: a secret key (starts with `sk_test_…`).

**Never** share these codes, paste them into a website, or put them in a
file that gets uploaded. They're the keys to your money.

---

## Step 1 — Subtitle Toolkit Pro (sells for $9, one-time)

### 1a. Create the app's filing cabinet (Convex)

Open the terminal and paste these two commands, one at a time, pressing
Enter after each:

```
cd "/home/rex/Documentos/Software Development/DeepSeek Harness/.subtitle-toolkit-build"
npx convex login
```

A browser window will open — sign in with your Convex account. Then:

```
npx convex deploy
```

**What should happen:** it prints a web address like
`https://something.convex.cloud`. Write it down — you need it in step 1d.

### 1b. Give the filing cabinet its secret codes

Still in the terminal, paste each of these lines, pressing Enter after
each. Replace the `…` parts with your real codes:

```
npx convex env set CLERK_JWT_ISSUER_DOMAIN https://lovely-gobbler-9439.clerk.accounts.dev
npx convex env set STRIPE_SECRET_KEY sk_test_…
npx convex env set STRIPE_WEBHOOK_SECRET whsec_test_…
npx convex env set DASHBOARD_URL https://rhls-softdev.github.io/subtitle-toolkit-launch/app
```

(There's an optional 5th line if you want to use a Stripe price you
created yourself — skip it if you don't know what that means; the app
already knows the $9 price.)

### 1c. Tell Stripe to send the mailman

1. In **Stripe**, go to Developers → Webhooks → **Add endpoint**.
2. Paste this as the address:
   `https://<your-convex-address>.convex.site/stripe/webhook`
   (replace `<your-convex-address>` with the address from step 1a).
3. For the event, choose **`checkout.session.completed`**.
4. Stripe will show you a secret starting with `whsec_test_` — that's the
   code you put in step 1b.

### 1d. Put the filing cabinet's address into the app

Open the file `.env.local` in the `.subtitle-toolkit-build` folder (it's a
hidden file — in the file browser press Ctrl+H to see hidden files), find
the line that says `VITE_CONVEX_URL=…`, and change it to:

```
VITE_CONVEX_URL=https://<your-convex-address>.convex.cloud
```

Save the file.

### 1e. Put the new app online

In the terminal:

```
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
GH_TOKEN=github_pat_… bash deploy-subtitle-toolkit.sh
```

(Replace `github_pat_…` with your GitHub access token. If you don't have
it handy, your developer does — it's the same one used for the other
deploys. You can also skip this step and ask them to run it.)

---

## Step 2 — KitchenOS Premium (sells for $50 per month)

Exactly the same pattern as Step 1, but in the KitchenOS folder and with
its own filing cabinet:

### 2a. Create its filing cabinet

```
cd "/home/rex/Documentos/Software Development/DeepSeek Harness/.kitchenos-build/enterprise"
npx convex login
npx convex deploy
```

Write down the address it prints.

### 2b. Give it the secret codes

```
npx convex env set CLERK_JWT_ISSUER_DOMAIN https://lovely-gobbler-9439.clerk.accounts.dev
npx convex env set STRIPE_SECRET_KEY sk_test_…
npx convex env set STRIPE_WEBHOOK_SECRET whsec_test_…
npx convex env set DASHBOARD_URL https://rhls-softdev.github.io/kitchenos-launch/premium
```

### 2c. Tell Stripe to send the mailman

Same as 1c, but with **three** events instead of one:
`checkout.session.completed`, `customer.subscription.updated`,
`customer.subscription.deleted`. Address:

```
https://<your-kitchenos-convex-address>.convex.site/stripe/webhook
```

Also in **Clerk**: open your app settings and make sure **Organizations**
are turned on (each restaurant kitchen is one "organization" — the app
needs this so each kitchen is billed separately).

### 2d. Put the address into the app

Same as 1d, but in the `.kitchenos-build/enterprise` folder's `.env.local`
file: `VITE_CONVEX_URL=https://<your-kitchenos-convex-address>.convex.cloud`

### 2e. Put the new app online

```
cd "/home/rex/Documentos/Software Development/DeepSeek Harness"
GH_TOKEN=github_pat_… bash deploy-kitchenos.sh
```

---

## Step 3 — Lingua Mundi (mostly done already)

Lingua Mundi's filing cabinet is already online, so you only need to:

1. Give it the secret codes (same lines as 1b, but run them in the
   `LinguaMundi/lingua-mundi/commercial` folder).
2. Set up the Stripe webhook like step 2c (three events), at:
   `https://dusty-turtle-795.convex.site/stripe/webhook`
3. Decide the price (this is a business decision, not technical) — the
   app needs a monthly price you create in Stripe, then one more code:
   `npx convex env set STRIPE_PRO_PRICE_ID price_…`

---

## Step 4 — Test everything with the fake credit card

Stripe gives everyone a **magic test card** so you can practice without
real money:

> Card number: **4242 4242 4242 4242** — any future date, any 3-digit CVC.

For each app: open its website, sign in, click the upgrade/buy button,
and pay with the magic card. **What should happen after paying:** the app
remembers you paid (a "purchased" note appears in the filing cabinet, and
the Pro/Premium badge unlocks). If the badge doesn't unlock, the mailman
isn't arriving — check that the webhook address in Stripe exactly matches
the one from step 1c/2c.

---

## Step 5 — When you're ready for real money

Everything above is **practice mode** (test). Real customers need you to:

1. In **Stripe**, flip the switch from "test" to "live" (top-right of the
   dashboard).
2. Create your real prices in live mode, then repeat the `env set` lines
   with the **live** codes (`sk_live_…`, `whsec_live_…`).
3. Set up a live webhook with the same addresses.
4. In **Clerk**, switch the app from Development to Production (settings
   page — just a switch, no code changes).
5. Run the three deploy commands again (`deploy-subtitle-toolkit.sh`,
   `deploy-kitchenos.sh`, `deploy-to-github-pages.sh`).
6. **Buy it yourself once** with a real card to confirm everything works
   before telling customers.

---

## Bonus — install the KitchenOS desktop app

```
sudo dpkg -i "/home/rex/Documentos/Software Development/DeepSeek Harness/KitchenOS-0.6.0-linux-amd64.deb"
```

---

## Quick checklist

- [ ] Clerk: one account (lovely-gobbler-9439) — done, shared by all apps
- [ ] Subtitle Toolkit: cabinet created, codes set, webhook added, app online
- [ ] KitchenOS: cabinet created, codes set, webhook (3 events) added, Organizations on, app online
- [ ] Lingua Mundi: codes set, webhook added, price decided
- [ ] Tested all three with card 4242 4242 4242 4242 — badges unlock
- [ ] Switched to live mode + production Clerk
- [ ] Bought it once myself with a real card — works

## If something breaks

- The most common problem is a typo in the webhook address or a wrong
  code. Copy-paste, don't retype.
- "Store not connected" on the app just means a step is missing — the app
  is designed to keep working (free features stay free) while you finish
  the setup, so nothing is ever broken for your users.
- For anything confusing, show `WIRING-GUIDE.md` (the technical version)
  to a developer, or ask the assistant — it has every command and the
  exact order to run them.
