# ID Card QR

Admin panel → add a person (photo, name, blood group, college, address) → get a permanent QR code to print on their ID card. Anyone who scans it sees that person's details in a centered card.

- Admin panel: `/admin` (password protected)
- Public profile (what the QR opens): `/p/<id>`
- The QR never changes, even if you edit the details or photo later.
- Profile links use random IDs, so nobody can guess other people's pages. Profiles are hidden from Google.

## Setup (about 10 minutes, free)

### 1. Supabase (database + photo storage)
1. Create a free project at https://supabase.com
2. Open **SQL Editor**, paste everything from `supabase/schema.sql`, click **Run**.
3. Go to **Project Settings → API** and copy the **Project URL** and the **service_role** key.

### 2. Run it on your computer
```bash
npm install
cp .env.example .env.local     # then fill in the values
npm run dev
```
Open http://localhost:3000/admin and log in with your `ADMIN_PASSWORD`.

### 3. Put it online (Vercel, free)
1. Push this folder to a GitHub repo.
2. Import the repo at https://vercel.com/new
3. Add the same environment variables from `.env.local` in Vercel's settings.
4. Set `NEXT_PUBLIC_SITE_URL` to your final Vercel URL (e.g. `https://myidcards.vercel.app`) and redeploy.

> ⚠️ **Set `NEXT_PUBLIC_SITE_URL` to your final domain before printing any cards.** The QR codes point to that address — if the address changes later, printed QR codes will stop working. Using your own domain is the safest "lifetime" option.

## Using it
1. `/admin` → **+ Add person** → fill details → **Create & generate QR**
2. Download the **SVG** (sharpest for printing) or **PNG** and place it on the ID card.
3. Print at least ~2 cm × 2 cm so phones scan it easily.
4. Scan it with any phone camera to test.

Never share the `SUPABASE_SERVICE_ROLE_KEY` — keep it only in `.env.local` and Vercel settings.
