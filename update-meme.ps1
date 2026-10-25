# ==========================================================
#  update-meme.ps1  -  patches your EXISTING id-qr project
#  Changes only code files. Does NOT touch .env.local,
#  node_modules or your Supabase data.
#
#  Usage (from inside your id-qr folder):
#    powershell -ExecutionPolicy Bypass -File .\update-meme.ps1
#  Or point it at the folder:
#    powershell -ExecutionPolicy Bypass -File .\update-meme.ps1 -ProjectPath "C:\path\to\id-qr"
# ==========================================================
param([string]$ProjectPath = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectPath)) { $ProjectPath = (Get-Location).Path }
$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).ProviderPath

if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'package.json'))) {
    Write-Host "package.json not found in '$ProjectPath'. Put this script inside your id-qr folder or pass -ProjectPath." -ForegroundColor Red
    exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $ProjectPath "_backup-$stamp"

function Put-File([string]$rel, [string]$content) {
    $full = [System.IO.Path]::Combine($ProjectPath, $rel)
    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($full))
    if ([System.IO.File]::Exists($full)) {
        $bk = [System.IO.Path]::Combine($backup, $rel)
        [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($bk))
        [System.IO.File]::Copy($full, $bk, $true)
    }
    [System.IO.File]::WriteAllText($full, $content.Replace("`r`n", "`n"), $utf8)
    Write-Host "  updated  $rel" -ForegroundColor Green
}

Write-Host "`nPatching project at: $ProjectPath" -ForegroundColor Cyan

Put-File 'lib/options.js' @'
// Shared by server and client code (no server-only imports here)

export const BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

export const FRIENDLY = {
  yes: { label: 'Friendly 😇', meme: 'Certified wholesome. Pets allowed.', level: 100 },
  food: { label: 'Friendly after food 🍔', meme: 'Feed first. Talk later.', level: 70 },
  mood: { label: 'Depends on mood 😐', meme: 'Check horoscope before approaching.', level: 45 },
  no: { label: 'Not friendly 💀', meme: 'Approach at your own risk.', level: 10 },
};
'@

Put-File 'lib/supabase.js' @'
import { createClient } from '@supabase/supabase-js';
import crypto from 'crypto';

let client;

// Server-only client. Never import this from a 'use client' file.
export function db() {
  if (!client) {
    client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    });
  }
  return client;
}

export function photoUrl(path) {
  if (!path) return null;
  return `${process.env.SUPABASE_URL}/storage/v1/object/public/photos/${path}`;
}

const ALPHABET = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

// Random, unguessable id so nobody can browse other people's profiles
export function newId(len = 10) {
  const bytes = crypto.randomBytes(len);
  let out = '';
  for (let i = 0; i < len; i++) out += ALPHABET[bytes[i] % ALPHABET.length];
  return out;
}

export { BLOOD_GROUPS } from './options';
'@

Put-File 'app/admin/actions.js' @'
'use server';

import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { db, newId } from '@/lib/supabase';
import { BLOOD_GROUPS, FRIENDLY } from '@/lib/options';
import { checkPassword, startSession, endSession, requireAdmin } from '@/lib/auth';

export async function login(_prev, formData) {
  if (!checkPassword(String(formData.get('password') || ''))) {
    return { error: 'Wrong password' };
  }
  await startSession();
  redirect('/admin');
}

export async function logout() {
  await endSession();
  redirect('/admin/login');
}

function readFields(fd) {
  const text = (k) => String(fd.get(k) || '').trim() || null;
  const blood = String(fd.get('blood_group') || '');
  const friendly = String(fd.get('friendly') || '');
  const kidsRaw = String(fd.get('kids') ?? '').trim();
  const kids = kidsRaw === '' ? null : Number.parseInt(kidsRaw, 10);
  return {
    name: String(fd.get('name') || '').trim(),
    blood_group: BLOOD_GROUPS.includes(blood) ? blood : null,
    college: text('college'),
    address: text('address'),
    fav_food: text('fav_food'),
    friendly: FRIENDLY[friendly] ? friendly : null,
    son_of: text('son_of'),
    husband_of: text('husband_of'),
    kids: Number.isInteger(kids) && kids >= 0 && kids <= 99 ? kids : null,
    crush_on: text('crush_on'),
  };
}

async function uploadPhoto(file) {
  if (!file || typeof file === 'string' || file.size === 0) return null;
  if (!file.type.startsWith('image/')) throw new Error('Photo must be an image file');
  if (file.size > 5 * 1024 * 1024) throw new Error('Photo must be under 5 MB');
  const ext = (file.type.split('/')[1] || 'jpg').replace('jpeg', 'jpg').replace(/[^a-z0-9]/gi, '');
  const path = `${newId(16)}.${ext}`;
  const { error } = await db().storage.from('photos').upload(path, file, { contentType: file.type });
  if (error) throw new Error(error.message);
  return path;
}

export async function createCard(_prev, fd) {
  await requireAdmin();
  const fields = readFields(fd);
  if (!fields.name) return { error: 'Name is required' };

  const id = newId(10);
  try {
    const photo_path = await uploadPhoto(fd.get('photo'));
    const { error } = await db().from('cards').insert({ id, ...fields, photo_path });
    if (error) return { error: error.message };
  } catch (e) {
    return { error: e.message };
  }
  revalidatePath('/admin');
  redirect(`/admin/${id}`);
}

export async function updateCard(_prev, fd) {
  await requireAdmin();
  const id = String(fd.get('id') || '');
  const fields = readFields(fd);
  if (!fields.name) return { error: 'Name is required' };

  try {
    const { data: existing } = await db().from('cards').select('photo_path').eq('id', id).single();
    const newPhoto = await uploadPhoto(fd.get('photo'));
    const update = { ...fields, updated_at: new Date().toISOString() };
    if (newPhoto) update.photo_path = newPhoto;

    const { error } = await db().from('cards').update(update).eq('id', id);
    if (error) return { error: error.message };

    if (newPhoto && existing?.photo_path) {
      await db().storage.from('photos').remove([existing.photo_path]);
    }
  } catch (e) {
    return { error: e.message };
  }
  revalidatePath('/admin');
  revalidatePath(`/admin/${id}`);
  revalidatePath(`/p/${id}`);
  return { ok: 'Saved. The QR code stays the same.' };
}

export async function deleteCard(fd) {
  await requireAdmin();
  const id = String(fd.get('id') || '');
  const { data } = await db().from('cards').select('photo_path').eq('id', id).single();
  await db().from('cards').delete().eq('id', id);
  if (data?.photo_path) await db().storage.from('photos').remove([data.photo_path]);
  revalidatePath('/admin');
  redirect('/admin');
}
'@

Put-File 'components/CardForm.js' @'
'use client';

import { useActionState, useState } from 'react';
import { BLOOD_GROUPS, FRIENDLY } from '@/lib/options';

export default function CardForm({ action, card, photo }) {
  const [state, formAction, pending] = useActionState(action, null);
  const [preview, setPreview] = useState(photo || null);

  return (
    <form action={formAction} className="form">
      {card && <input type="hidden" name="id" value={card.id} />}

      <label className="photo-pick">
        <span className="avatar lg">
          {preview ? <img src={preview} alt="" /> : <span className="avatar-empty">Add photo</span>}
        </span>
        <input
          type="file"
          name="photo"
          accept="image/*"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) setPreview(URL.createObjectURL(f));
          }}
        />
        <span className="hint">{card ? 'Tap to change photo' : 'Tap to choose a photo'}</span>
      </label>

      <label>
        Full name *
        <input name="name" required defaultValue={card?.name || ''} placeholder="e.g. Riya Sharma" />
      </label>

      <div className="form-2">
        <label>
          Blood group 🩸
          <select name="blood_group" defaultValue={card?.blood_group || ''}>
            <option value="">Select</option>
            {BLOOD_GROUPS.map((b) => (
              <option key={b} value={b}>{b}</option>
            ))}
          </select>
        </label>

        <label>
          Friendly or not? 🐶
          <select name="friendly" defaultValue={card?.friendly || ''}>
            <option value="">Select</option>
            {Object.entries(FRIENDLY).map(([k, v]) => (
              <option key={k} value={k}>{v.label}</option>
            ))}
          </select>
        </label>
      </div>

      <label>
        Favourite food 🍕
        <input name="fav_food" defaultValue={card?.fav_food || ''} placeholder="e.g. Chole bhature" />
      </label>

      <div className="form-2">
        <label>
          Son of 👨‍👦
          <input name="son_of" defaultValue={card?.son_of || ''} placeholder="Father's name" />
        </label>
        <label>
          Husband of 💍
          <input name="husband_of" defaultValue={card?.husband_of || ''} placeholder="Leave empty if single" />
        </label>
      </div>

      <div className="form-2">
        <label>
          No. of kids 👶
          <input type="number" name="kids" min="0" max="99" defaultValue={card?.kids ?? ''} placeholder="0" />
        </label>
        <label>
          Crush on 😳
          <input name="crush_on" defaultValue={card?.crush_on || ''} placeholder="Hidden until tapped" />
        </label>
      </div>

      <label>
        College 🎓
        <input name="college" defaultValue={card?.college || ''} placeholder="College / institute name" />
      </label>

      <label>
        Address 🏠
        <textarea name="address" rows={3} defaultValue={card?.address || ''} placeholder="Full address" />
      </label>

      {state?.error && <p className="msg error">{state.error}</p>}
      {state?.ok && <p className="msg ok">{state.ok}</p>}

      <button className="btn primary" disabled={pending}>
        {pending ? 'Saving…' : card ? 'Save changes' : 'Create & generate QR'}
      </button>
    </form>
  );
}
'@

Put-File 'app/p/[id]/page.js' @'
import { notFound } from 'next/navigation';
import { db, photoUrl } from '@/lib/supabase';
import { FRIENDLY } from '@/lib/options';

export const dynamic = 'force-dynamic';

async function getCard(id) {
  if (!/^[A-Za-z0-9]{6,32}$/.test(id)) return null;
  const { data } = await db()
    .from('cards')
    .select('name,blood_group,college,address,photo_path,fav_food,friendly,son_of,husband_of,kids,crush_on')
    .eq('id', id)
    .single();
  return data;
}

export async function generateMetadata({ params }) {
  const card = await getCard((await params).id);
  return {
    title: card ? `${card.name} — Official Legend ID™` : 'Not found',
    robots: { index: false, follow: false },
  };
}

function kidsText(n) {
  if (n === 0) return { emoji: '🕊️', text: '0 — free as a bird' };
  if (n === 1) return { emoji: '👶', text: '1 — the chosen one' };
  if (n <= 3) return { emoji: '👶'.repeat(n), text: `${n} — manageable chaos` };
  if (n <= 6) return { emoji: '👶'.repeat(n), text: `${n} — basically a cricket team` };
  return { emoji: '👶👶👶➕', text: `${n} — sir, this is a school` };
}

function Stat({ icon, label, children, tilt = 0 }) {
  return (
    <div className="stat" style={{ '--tilt': `${tilt}deg` }}>
      <span className="stat-icon" aria-hidden="true">{icon}</span>
      <div>
        <div className="stat-label">{label}</div>
        <div className="stat-value">{children}</div>
      </div>
    </div>
  );
}

export default async function Profile({ params }) {
  const card = await getCard((await params).id);
  if (!card) notFound();
  const photo = photoUrl(card.photo_path);
  const vibe = card.friendly ? FRIENDLY[card.friendly] : null;
  const kids = card.kids != null ? kidsText(card.kids) : null;

  return (
    <main className="meme-bg">
      <article className="id-card">
        <header className="id-head">
          <span className="id-title">OFFICIAL LEGEND ID™</span>
          <span className="id-sub">Verified by the internet · No refunds</span>
        </header>

        <div className="stamp" aria-hidden="true">100% REAL<br />NOT FAKE</div>

        <div className="hero">
          <div className="polaroid">
            {photo ? <img src={photo} alt={card.name} /> : <span className="avatar-empty">{card.name[0]}</span>}
            <span className="sticker" aria-hidden="true">😎</span>
          </div>
          <h1 className="meme-name">{card.name}</h1>
          {card.blood_group && (
            <div className="blood">
              🩸 Blood group <strong>{card.blood_group}</strong>
            </div>
          )}
        </div>

        {vibe && (
          <section className="vibe">
            <div className="vibe-top">
              <span className="stat-label">Vibe check</span>
              <strong>{vibe.label}</strong>
            </div>
            <div className="meter" role="meter" aria-valuenow={vibe.level} aria-valuemin={0} aria-valuemax={100}>
              <span style={{ width: `${vibe.level}%` }} />
            </div>
            <p className="vibe-meme">{vibe.meme}</p>
          </section>
        )}

        <section className="stats">
          {card.fav_food && <Stat icon="🍕" label="Fuel source" tilt={-1}>{card.fav_food}</Stat>}
          {card.son_of && <Stat icon="👨‍👦" label="Son of" tilt={1}>{card.son_of}</Stat>}
          {card.husband_of && <Stat icon="💍" label="Husband of (taken!)" tilt={-1}>{card.husband_of}</Stat>}
          {kids && (
            <Stat icon="🍼" label="No. of kids" tilt={1}>
              {kids.text}
              <span className="kids-row" aria-hidden="true">{kids.emoji}</span>
            </Stat>
          )}
          {card.crush_on && (
            <Stat icon="😳" label="Crush on" tilt={-1}>
              <details className="spoiler">
                <summary>Tap to reveal 🙈</summary>
                <span>{card.crush_on}</span>
              </details>
            </Stat>
          )}
          {card.college && <Stat icon="🎓" label="Studies at (allegedly)" tilt={1}>{card.college}</Stat>}
          {card.address && <Stat icon="🏠" label="Base of operations" tilt={0}>{card.address}</Stat>}
        </section>

        <footer className="id-foot">You scanned it. You now know too much. 👀</footer>
      </article>
    </main>
  );
}
'@

Put-File 'app/layout.js' @'
import './globals.css';

export const metadata = { title: 'Official Legend ID™' };
export const viewport = { width: 'device-width', initialScale: 1, themeColor: '#ffd23f' };

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Bangers&family=Comic+Neue:wght@400;700&display=swap"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
'@

Put-File 'app/not-found.js' @'
export default function NotFound() {
  return (
    <main className="meme-bg">
      <div className="id-card" style={{ textAlign: 'center', padding: '40px 24px' }}>
        <div style={{ fontSize: '4rem' }}>🤷</div>
        <h1 className="meme-name">404: Legend not found</h1>
        <p className="vibe-meme">This person has left the chat (or was never here).</p>
      </div>
    </main>
  );
}
'@

Put-File 'app/globals.css' @'
/* ======== Meme / comic theme ======== */
:root {
  --yellow: #ffd23f;
  --pink: #ff5ca8;
  --blue: #3bceac;
  --purple: #7b5cff;
  --red: #ee4266;
  --ink: #111111;
  --paper: #fffdf5;
  --muted: #555049;
  --line: var(--ink);
  --radius: 14px;
  --shadow: 5px 5px 0 var(--ink);
  --font-head: 'Bangers', 'Impact', 'Arial Black', sans-serif;
  --font-body: 'Comic Neue', 'Comic Sans MS', 'Chalkboard SE', system-ui, sans-serif;
}

* { box-sizing: border-box; }
html, body { margin: 0; }
body {
  color: var(--ink);
  font-family: var(--font-body);
  line-height: 1.45;
  background-color: var(--yellow);
  /* comic halftone dots */
  background-image: radial-gradient(rgba(0, 0, 0, 0.13) 1.4px, transparent 1.6px);
  background-size: 14px 14px;
}
h1, h2 { font-family: var(--font-head); letter-spacing: 0.04em; font-weight: 400; }
h1 { font-size: 2.2rem; margin: 0 0 1rem; }
h2 { font-size: 1.5rem; margin: 0 0 1rem; }
a { color: inherit; }
img { display: block; }
.muted { color: var(--muted); }
.hint { color: var(--muted); font-size: 0.85rem; margin: 0.5rem 0 0; }
hr { border: 0; border-top: 2px dashed var(--ink); margin: 1.5rem 0; }

/* ======== Public meme ID card ======== */
.meme-bg {
  min-height: 100dvh;
  display: grid;
  place-items: center;
  padding: 28px 16px 40px;
  background:
    repeating-conic-gradient(from 0deg at 50% 30%, rgba(255, 255, 255, 0.35) 0 8deg, transparent 8deg 16deg);
}
.id-card {
  position: relative;
  width: 100%;
  max-width: 400px;
  background: var(--paper);
  border: 4px solid var(--ink);
  border-radius: 22px;
  box-shadow: 9px 9px 0 var(--ink);
  overflow: hidden;
  animation: pop 0.5s cubic-bezier(0.2, 1.6, 0.4, 1) both;
}
@keyframes pop {
  from { transform: scale(0.85) rotate(-3deg); opacity: 0; }
  to { transform: scale(1) rotate(0); opacity: 1; }
}
.id-head {
  background: var(--pink);
  border-bottom: 4px solid var(--ink);
  padding: 12px 16px 10px;
  text-align: center;
  display: grid;
}
.id-title {
  font-family: var(--font-head);
  font-size: 1.9rem;
  letter-spacing: 0.06em;
  color: #fff;
  -webkit-text-stroke: 1.5px var(--ink);
  text-shadow: 3px 3px 0 var(--ink);
}
.id-sub { font-size: 0.8rem; font-weight: 700; }

.stamp {
  position: absolute;
  top: 82px;
  right: 10px;
  transform: rotate(14deg);
  border: 3px solid var(--red);
  color: var(--red);
  font-family: var(--font-head);
  font-size: 0.95rem;
  line-height: 1.05;
  text-align: center;
  padding: 5px 8px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.85);
  z-index: 2;
}

.hero { text-align: center; padding: 26px 18px 6px; }
.polaroid {
  position: relative;
  width: 168px;
  margin: 0 auto;
  background: #fff;
  border: 3px solid var(--ink);
  padding: 9px 9px 30px;
  transform: rotate(-4deg);
  box-shadow: var(--shadow);
}
.polaroid img, .polaroid .avatar-empty {
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  display: grid;
  place-items: center;
  background: var(--blue);
  font-family: var(--font-head);
  font-size: 4rem;
  color: var(--ink);
}
.sticker {
  position: absolute;
  bottom: -14px;
  right: -16px;
  font-size: 2.6rem;
  transform: rotate(16deg);
  filter: drop-shadow(2px 2px 0 var(--ink));
}
.meme-name {
  font-size: 2.6rem;
  line-height: 1;
  margin: 26px 0 12px;
  color: var(--yellow);
  -webkit-text-stroke: 2px var(--ink);
  text-shadow: 4px 4px 0 var(--ink);
  word-break: break-word;
}

.blood {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: var(--red);
  color: #fff;
  border: 3px solid var(--ink);
  box-shadow: 3px 3px 0 var(--ink);
  padding: 5px 14px;
  border-radius: 999px;
  font-weight: 700;
}
.blood strong { font-family: var(--font-head); font-size: 1.35rem; letter-spacing: 0.05em; }
.blood.sm { padding: 1px 10px; box-shadow: none; border-width: 2px; font-size: 0.9rem; }

.vibe {
  margin: 18px 16px 0;
  border: 3px solid var(--ink);
  border-radius: var(--radius);
  background: var(--blue);
  padding: 10px 12px;
  box-shadow: 4px 4px 0 var(--ink);
}
.vibe-top { display: flex; justify-content: space-between; align-items: baseline; gap: 8px; flex-wrap: wrap; }
.meter {
  height: 16px;
  margin: 8px 0 6px;
  border: 3px solid var(--ink);
  border-radius: 999px;
  background: #fff;
  overflow: hidden;
}
.meter span {
  display: block;
  height: 100%;
  background: repeating-linear-gradient(45deg, var(--pink) 0 10px, var(--purple) 10px 20px);
  animation: fill 1.1s ease-out both 0.3s;
  transform-origin: left;
}
@keyframes fill { from { transform: scaleX(0); } }
.vibe-meme { margin: 0; font-weight: 700; font-style: italic; font-size: 0.9rem; }

.stats { display: grid; gap: 12px; padding: 18px 16px 6px; }
.stat {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  background: #fff;
  border: 3px solid var(--ink);
  border-radius: var(--radius);
  padding: 10px 12px;
  box-shadow: 4px 4px 0 var(--ink);
  transform: rotate(var(--tilt, 0deg));
}
.stat:nth-child(3n + 1) { background: #fff4c2; }
.stat:nth-child(3n + 2) { background: #ffe0ef; }
.stat:nth-child(3n) { background: #dcf8f1; }
.stat-icon { font-size: 1.8rem; line-height: 1; }
.stat-label {
  font-family: var(--font-head);
  letter-spacing: 0.06em;
  font-size: 1rem;
  color: var(--muted);
}
.stat-value { font-weight: 700; font-size: 1.05rem; white-space: pre-line; word-break: break-word; }
.kids-row { display: block; font-size: 1.1rem; letter-spacing: 2px; }

.spoiler summary {
  cursor: pointer;
  list-style: none;
  display: inline-block;
  background: var(--ink);
  color: var(--yellow);
  padding: 2px 10px;
  border-radius: 6px;
}
.spoiler summary::-webkit-details-marker { display: none; }
.spoiler[open] summary { display: none; }
.spoiler span { animation: pop 0.4s cubic-bezier(0.2, 1.6, 0.4, 1) both; display: inline-block; }

.id-foot {
  margin-top: 16px;
  background: var(--ink);
  color: var(--yellow);
  text-align: center;
  padding: 10px 14px;
  font-weight: 700;
  font-size: 0.9rem;
}

/* ======== Avatars (admin) ======== */
.avatar {
  border-radius: 50%;
  overflow: hidden;
  background: var(--blue);
  border: 3px solid var(--ink);
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
.avatar img { width: 100%; height: 100%; object-fit: cover; }
.avatar.lg { width: 110px; height: 110px; }
.avatar.sm { width: 50px; height: 50px; }
.avatar-empty { font-family: var(--font-head); font-size: 1rem; letter-spacing: 0.04em; }

/* ======== Admin ======== */
.center-screen { min-height: 100dvh; display: grid; place-items: center; padding: 24px 16px; }
.admin { max-width: 1000px; margin: 0 auto; padding: 24px 16px 60px; }
.admin.narrow { max-width: 560px; }
.admin-top { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; margin-bottom: 16px; }
.admin-top h1 { margin: 0; }
.back { display: inline-block; margin-bottom: 12px; font-weight: 700; text-decoration: none; }
.panel {
  background: var(--paper);
  border: 3px solid var(--ink);
  border-radius: var(--radius);
  padding: 20px;
  box-shadow: var(--shadow);
}
.login { width: 100%; max-width: 360px; display: grid; gap: 14px; }
.two-col { display: grid; gap: 20px; grid-template-columns: 1fr; }
@media (min-width: 820px) { .two-col { grid-template-columns: 1fr 1fr; align-items: start; } }

.search input { margin-bottom: 16px; }
.grid { list-style: none; padding: 0; margin: 0; display: grid; gap: 14px; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }
.tile {
  display: flex; align-items: center; gap: 12px;
  background: var(--paper); border: 3px solid var(--ink); border-radius: var(--radius);
  padding: 12px; text-decoration: none; box-shadow: 4px 4px 0 var(--ink);
  transition: transform 0.12s, box-shadow 0.12s;
}
.tile:hover { transform: translate(-2px, -2px) rotate(-0.5deg); box-shadow: 6px 6px 0 var(--ink); }
.tile-text { display: grid; flex: 1; min-width: 0; }
.tile-text > * { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.form { display: grid; gap: 14px; }
.form-2 { display: grid; gap: 14px; grid-template-columns: 1fr 1fr; }
@media (max-width: 420px) { .form-2 { grid-template-columns: 1fr; } }
label { display: grid; gap: 6px; font-size: 0.95rem; font-weight: 700; }
input, select, textarea {
  width: 100%;
  font: inherit;
  font-weight: 400;
  color: var(--ink);
  background: #fff;
  border: 2px solid var(--ink);
  border-radius: 10px;
  padding: 10px 12px;
}
input:focus, select:focus, textarea:focus { outline: 3px solid var(--pink); outline-offset: 1px; }
.photo-pick { justify-items: center; cursor: pointer; }
.photo-pick input[type='file'] { display: none; }

.row { display: flex; gap: 8px; flex-wrap: wrap; justify-content: center; }
.btn {
  display: inline-flex; align-items: center; justify-content: center;
  font-family: var(--font-head); font-size: 1.1rem; letter-spacing: 0.05em; font-weight: 400;
  padding: 8px 16px; border-radius: 10px; cursor: pointer;
  border: 3px solid var(--ink); background: #fff; color: var(--ink);
  text-decoration: none; box-shadow: 3px 3px 0 var(--ink);
  transition: transform 0.1s, box-shadow 0.1s;
}
.btn:active { transform: translate(3px, 3px); box-shadow: none; }
.btn.primary { background: var(--pink); color: #fff; -webkit-text-stroke: 0.5px var(--ink); }
.btn.ghost { background: var(--paper); }
.btn.danger { background: var(--red); color: #fff; }
.btn:disabled { opacity: 0.6; cursor: wait; }
.msg { margin: 0; font-weight: 700; }
.msg.error { color: var(--red); }
.msg.ok { color: #0b7a5e; }

.qr-box { display: grid; gap: 12px; justify-items: center; text-align: center; }
.qr-img { background: #fff; padding: 12px; border-radius: 12px; border: 3px solid var(--ink); box-shadow: var(--shadow); }
.qr-img img, .qr-loading { width: 240px; height: 240px; }
.qr-url { font-family: ui-monospace, monospace; font-size: 0.8rem; word-break: break-all; margin: 0; }

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; }
}
'@

Put-File 'supabase/schema.sql' @'
-- Run this once in Supabase → SQL Editor

create table if not exists public.cards (
  id          text primary key,          -- random id used in the QR link (never changes)
  name        text not null,
  blood_group text,
  college     text,
  address     text,
  photo_path  text,
  fav_food    text,
  friendly    text,
  son_of      text,
  husband_of  text,
  kids        int,
  crush_on    text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Lock the table: no public access at all.
-- Only the website's server (using the service role key) can read/write.
alter table public.cards enable row level security;

-- Public bucket for profile photos (file names are random, so they can't be guessed)
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;
'@

Put-File 'supabase/update-v2.sql' @'
-- Run this ONCE in Supabase → SQL Editor to add the new meme fields
alter table public.cards
  add column if not exists fav_food   text,
  add column if not exists friendly   text,
  add column if not exists son_of     text,
  add column if not exists husband_of text,
  add column if not exists kids       int,
  add column if not exists crush_on   text;
'@

# Clear Next.js cache so the new styles show up
$nextDir = Join-Path $ProjectPath '.next'
if (Test-Path -LiteralPath $nextDir) { Remove-Item -LiteralPath $nextDir -Recurse -Force; Write-Host "  cleared  .next cache" -ForegroundColor Green }

Write-Host "`nDone! Old files backed up to: $backup" -ForegroundColor Cyan
Write-Host "NEXT: run supabase\update-v2.sql once in Supabase SQL Editor, then:  npm run dev" -ForegroundColor Yellow
