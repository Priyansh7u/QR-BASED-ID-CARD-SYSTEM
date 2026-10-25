# 🪪 Official Legend ID™ — QR Code ID Card System
 
> Scan the QR on an ID card → see the person's profile instantly.
> Built with **Next.js** + **Supabase**. Works on every phone & tablet. 📱

![Next.js](https://img.shields.io/badge/Next.js-15-black?logo=next.js)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)
![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase&logoColor=white)
![Vercel](https://img.shields.io/badge/Deploy-Vercel-000?logo=vercel)

---

## ✨ Features

- 🔐 **Admin panel** — password-protected dashboard to add, edit, search & delete people
- 🔳 **Lifetime QR codes** — every person gets a permanent QR; editing details never changes it
- 📥 **Download QR** as **PNG** or **SVG** (sharp for printing on ID cards)
- 😎 **Meme-style profile page** — comic design, vibe meter, stickers & a hidden crush reveal 🙈
- 📱 **Fully responsive** — fits small phones, big phones, landscape, tablets and laptops
- 🛡️ **Private by design** — random unguessable links, hidden from Google, database locked
- 🖼️ **Photo upload** stored in Supabase Storage

## 📋 Details shown on the card

| Field | Shown as |
|---|---|
| Photo | Tilted polaroid with 😎 sticker |
| Name | Big comic-style title |
| Blood group | 🩸 Red badge |
| Friendly or not | Vibe-check meter |
| Favourite food | 🍕 Fuel source |
| Son of | 👨‍👦 Son of |
| Husband of | 💍 Husband of (taken!) |
| No. of kids | 🍼 With a funny caption |
| Crush on | 😳 Hidden until tapped |
| College | 🎓 Studies at (allegedly) |
| Address | 🏠 Base of operations |

Empty fields are hidden automatically.

---

## 🛠️ Tech Stack

- **Frontend & Server:** Next.js 15 (App Router, Server Actions), React 19
- **Database & Storage:** Supabase (PostgreSQL + Storage)
- **QR Codes:** `qrcode` (High error-correction — still scans if the card gets scratched)
- **Hosting:** Vercel

---

## 🚀 Getting Started

### 1. Requirements
- [Node.js](https://nodejs.org) 20 or newer (LTS)
- A free [Supabase](https://supabase.com) account

### 2. Set up Supabase
1. Create a new project on Supabase.
2. Go to **SQL Editor → New query**, paste the contents of [`supabase/schema.sql`](supabase/schema.sql) and click **Run**.
3. Go to **Project Settings → API Keys** and copy your **Project URL** and **Secret key**.

> Upgrading an older install? Run [`supabase/update-v2.sql`](supabase/update-v2.sql) once to add the new fields.

### 3. Clone & configure
```bash
git clone https://github.com/YOUR-USERNAME/id-card-qr.git
cd id-card-qr
```

Create a file named `.env.local` in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sb_secret_xxxxxxxxxxxxx
ADMIN_PASSWORD=your-admin-password
SESSION_SECRET=any-long-random-string
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

| Variable | What it is |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase secret key (**never share this**) |
| `ADMIN_PASSWORD` | Password to log in to `/admin` |
| `SESSION_SECRET` | Random text used to secure the login cookie |
| `NEXT_PUBLIC_SITE_URL` | The website address the QR codes point to |

### 4. Run it

**Windows (easiest):** double-click `start.bat` — it sets everything up and opens the admin panel.

**Any OS:**
```bash
npm install
npm run dev
```

Open 👉 **http://localhost:3000/admin**

---

## 📖 How to Use

1. Log in at `/admin` with your admin password.
2. Click **+ Add person**, upload a photo and fill in the details.
3. Click **Create & generate QR**.
4. Download the **SVG** (best for print) or **PNG**.
5. Print it on the ID card (at least **2 cm × 2 cm**).
6. Scan with any phone camera → the profile opens. 🎉

---

## 🌐 Deploy to Vercel

1. Push this repo to GitHub.
2. Go to [vercel.com/new](https://vercel.com/new) and import the repo.
3. Add all 5 environment variables from `.env.local` in **Settings → Environment Variables**.
4. Deploy, then set `NEXT_PUBLIC_SITE_URL` to your live URL (e.g. `https://my-id-cards.vercel.app`) and **Redeploy**.

> ⚠️ **Important:** Set `NEXT_PUBLIC_SITE_URL` to your final domain **before printing any cards**.
> QR codes point to this address — if it changes later, printed cards will stop working.
> Using your own custom domain is the safest choice for truly lifetime QR codes.

---

## 📁 Project Structure

```
id-qr/
├── app/
│   ├── admin/
│   │   ├── [id]/page.js      # Edit person + QR code
│   │   ├── login/page.js     # Admin login
│   │   ├── new/page.js       # Add person
│   │   ├── actions.js        # Create / update / delete logic
│   │   └── page.js           # People list + search
│   ├── p/[id]/page.js        # Public profile (what the QR opens)
│   ├── globals.css           # Meme theme + responsive styles
│   └── layout.js
├── components/
│   ├── CardForm.js           # Add/edit form
│   ├── QRBox.js              # QR preview + downloads
│   └── DeleteButton.js
├── lib/
│   ├── auth.js               # Admin login session
│   ├── options.js            # Blood groups & vibe options
│   └── supabase.js           # Database client
├── supabase/
│   ├── schema.sql            # Fresh install
│   └── update-v2.sql         # Upgrade for new fields
├── run.ps1 / start.bat       # One-click Windows launcher
└── .env.example
```

---

## 🔒 Security

- The database has **Row Level Security** enabled with no public policies — only the server can read or write.
- Profile links use **random 10-character IDs**, so no one can guess other profiles.
- Profile pages are marked **noindex**, so they don't appear on Google.
- `.env.local` is in `.gitignore` — **never commit your secret key**.
- If your secret key is ever exposed, create a new one in Supabase and delete the old one.

---

## 🧯 Troubleshooting

| Problem | Fix |
|---|---|
| `'npm' is not recognized` | Install Node.js and restart the terminal |
| "Wrong password" on login | Check `ADMIN_PASSWORD` in `.env.local`, then restart `npm run dev` |
| Error about `cards` table or missing column | Run `supabase/schema.sql` (or `update-v2.sql`) in Supabase |
| Photo upload fails | Make sure the `photos` bucket exists in Supabase → Storage |
| QR doesn't open on phone | `localhost` only works on your PC — deploy online or use your PC's IP address |
| Changes to `.env.local` not working | Stop the app (`Ctrl + C`) and run `npm run dev` again |

---

## 📄 License

MIT — free to use and modify.

---

<p align="center">Made with ☕ Priyanshu · <i>You scanned it. You now know too much.</i> 👀</p>
