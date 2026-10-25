import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import crypto from 'crypto';

const COOKIE = 'idqr_admin';

function sessionToken() {
  return crypto
    .createHmac('sha256', process.env.SESSION_SECRET || '')
    .update(process.env.ADMIN_PASSWORD || '')
    .digest('hex');
}

function safeEqual(a, b) {
  const x = Buffer.from(a || '');
  const y = Buffer.from(b || '');
  return x.length > 0 && x.length === y.length && crypto.timingSafeEqual(x, y);
}

export function checkPassword(password) {
  return safeEqual(password, process.env.ADMIN_PASSWORD);
}

export async function isAdmin() {
  if (!process.env.ADMIN_PASSWORD || !process.env.SESSION_SECRET) return false;
  const value = (await cookies()).get(COOKIE)?.value;
  return safeEqual(value, sessionToken());
}

export async function requireAdmin() {
  if (!(await isAdmin())) redirect('/admin/login');
}

export async function startSession() {
  (await cookies()).set(COOKIE, sessionToken(), {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 24 * 30,
  });
}

export async function endSession() {
  (await cookies()).delete(COOKIE);
}
