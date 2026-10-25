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