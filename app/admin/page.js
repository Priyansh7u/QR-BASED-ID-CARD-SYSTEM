import Link from 'next/link';
import { requireAdmin } from '@/lib/auth';
import { db, photoUrl } from '@/lib/supabase';
import { logout } from './actions';

export const dynamic = 'force-dynamic';

export default async function AdminHome({ searchParams }) {
  await requireAdmin();
  const q = String((await searchParams)?.q || '').trim();

  let query = db().from('cards').select('id,name,college,blood_group,photo_path').order('created_at', { ascending: false });
  if (q) query = query.ilike('name', `%${q.replace(/[%_]/g, '')}%`);
  const { data: cards, error } = await query;

  return (
    <main className="admin">
      <header className="admin-top">
        <h1>ID Cards</h1>
        <div className="row">
          <Link className="btn primary" href="/admin/new">+ Add person</Link>
          <form action={logout}><button className="btn ghost">Log out</button></form>
        </div>
      </header>

      <form className="search">
        <input name="q" defaultValue={q} placeholder="Search by name…" />
      </form>

      {error && <p className="msg error">{error.message}</p>}
      {cards?.length === 0 && <p className="muted">No one added yet. Click "Add person" to create the first ID.</p>}

      <ul className="grid">
        {cards?.map((c) => (
          <li key={c.id}>
            <Link href={`/admin/${c.id}`} className="tile">
              <span className="avatar sm">
                {c.photo_path ? <img src={photoUrl(c.photo_path)} alt="" /> : <span className="avatar-empty">{c.name[0]}</span>}
              </span>
              <span className="tile-text">
                <strong>{c.name}</strong>
                <span className="muted">{c.college || '—'}</span>
              </span>
              {c.blood_group && <span className="blood sm">{c.blood_group}</span>}
            </Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
