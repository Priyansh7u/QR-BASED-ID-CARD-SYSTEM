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