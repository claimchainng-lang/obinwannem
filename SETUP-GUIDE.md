# Obinwannem Foundation Worldwide — Website Setup Guide

## What You Have
- `index.html` — The complete website + member dashboard (single deployable file)
- `supabase-schema.sql` — Full database schema to run in Supabase

---

## STEP 1 — Create Your Supabase Project

1. Go to **https://supabase.com** and sign up (free)
2. Click **New Project**
3. Name it: `obinwannem-foundation`
4. Set a strong database password (save it)
5. Choose region: **Frankfurt, EU (eu-central-1)** — closest to Hamburg HQ
6. Click **Create new project** and wait ~2 minutes

---

## STEP 2 — Run the Database Schema

1. In your Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **New query**
3. Open `supabase-schema.sql` from this package
4. Copy ALL contents and paste into the SQL editor
5. Click **Run** (green button)
6. You should see: *"Success. No rows returned"*

This creates all your tables:
- `profiles` — member data & identity
- `membership_payments` — dues & donations
- `events` — cultural calendar
- `event_registrations` — who registered for what
- `member_connections` — member networking
- `member_content` — exclusive articles & docs
- `notifications` — member alerts

---

## STEP 3 — Get Your API Keys

1. In Supabase dashboard → **Project Settings** → **API**
2. Copy:
   - **Project URL** (looks like: `https://xxxxxxxxxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ…`)

---

## STEP 4 — Add Keys to Your Website

Open `index.html` and find these two lines near the bottom (inside the `<script>` tag):

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace with your actual values:

```javascript
const SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## STEP 5 — Configure Supabase Auth

1. In Supabase → **Authentication** → **Providers**
2. **Email** is enabled by default ✓
3. Go to **Authentication** → **Settings (URL Configuration)**
4. Set **Site URL** to your deployed domain (e.g. `https://obinwannem.org`)
5. For testing locally, set it to `http://localhost` or use file:// path

### Optional: Disable email confirmation for faster testing
- **Authentication** → **Settings** → Toggle off **"Enable email confirmations"**
- Re-enable before going live

---

## STEP 6 — Deploy the Website

### Option A — Netlify (Recommended, Free)
1. Go to **https://netlify.com** → Sign up
2. Drag and drop the `ofw-website` folder onto the Netlify dashboard
3. Your site is live instantly at a `.netlify.app` URL
4. Add your custom domain (e.g. `obinwannem.org`) in Site Settings → Domains

### Option B — Vercel (Also Free)
1. Go to **https://vercel.com** → Sign up
2. Install Vercel CLI: `npm i -g vercel`
3. Run `vercel` inside the `ofw-website` folder
4. Follow prompts — site is live in seconds

### Option C — GitHub Pages
1. Push the folder to a GitHub repo
2. Go to repo Settings → Pages → Deploy from main branch
3. Site live at `https://yourusername.github.io/ofw-website`

---

## STEP 7 — Admin Access (Managing Members)

In Supabase, you can manage all members directly from the **Table Editor**:
- View all member profiles → `profiles` table
- Verify members → set `is_verified = true`
- Change membership status → update `membership_status`
- View all payments → `membership_payments` table
- Add content → insert rows in `member_content`
- Add events → insert rows in `events`

For a proper admin dashboard, this can be built as a second page (just ask!).

---

## STEP 8 — Payment Gateway (Optional Next Step)

The current payments tab records payment intent. To accept real money:

### Stripe (Europe — recommended for Hamburg)
1. Create account at **https://stripe.com**
2. Add Stripe.js to `index.html`
3. Replace the `recordPayment()` function with Stripe Checkout

### Paystack (Nigeria — recommended for Nsukka HQ)
1. Create account at **https://paystack.com**
2. Add Paystack inline script
3. Connect to payment buttons

---

## Feature Summary

| Feature | Status |
|---|---|
| Public website (hero, pillars, tiers, events, impact) | ✅ Built |
| Member registration with tier selection | ✅ Built |
| Member login / logout | ✅ Built |
| Member profile (edit name, bio, location, Igbo identity, socials) | ✅ Built |
| Membership tier display + upgrade | ✅ Built |
| Event listing + registration | ✅ Built |
| Member-only content with tier gating | ✅ Built |
| Member directory + connection requests | ✅ Built |
| Payment history + dues recording | ✅ Built |
| Notifications system | ✅ Built |
| Row-level security (members see only their data) | ✅ Built |
| Auto-generated membership numbers (OFW-FM-1001 etc.) | ✅ Built |
| Admin dashboard | 🔜 Next step |
| Stripe / Paystack payment gateway | 🔜 Next step |
| Email notifications | 🔜 Next step |
| Mobile app (React Native) | 🔜 Future |

---

## Support
Built by Obinwannem Global Media Group Tech Division.
For technical issues, contact your web administrator.

*Obinwannem — One People. One Purpose.*
