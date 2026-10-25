import Link from 'next/link';
import { notFound } from 'next/navigation';
import { requireAdmin } from '@/lib/auth';
import { db, photoUrl } from '@/lib/supabase';
import CardForm from '@/components/CardForm';
import QRBox from '@/components/QRBox';
import DeleteButton from '@/components/DeleteButton';
import { updateCard, deleteCard } from '../actions';

export const dynamic = 'force-dynamic';

export default async function EditCard({ params }) {
  await requireAdmin();
  const { id } = await params;
  const { data: card } = await db().from('cards').select('*').eq('id', id).single();
  if (!card) notFound();

  return (
    <main className="admin">
      <Link href="/admin" className="back">← All people</Link>
      <h1>{card.name}</h1>
      <div className="two-col">
        <section className="panel">
          <h2>QR code for ID card</h2>
          <QRBox id={card.id} name={card.name} />
        </section>
        <section className="panel">
          <h2>Details</h2>
          <CardForm action={updateCard} card={card} photo={photoUrl(card.photo_path)} />
          <hr />
          <DeleteButton action={deleteCard} id={card.id} />
        </section>
      </div>
    </main>
  );
}
