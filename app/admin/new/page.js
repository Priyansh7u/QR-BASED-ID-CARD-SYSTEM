import Link from 'next/link';
import { requireAdmin } from '@/lib/auth';
import CardForm from '@/components/CardForm';
import { createCard } from '../actions';

export default async function NewCard() {
  await requireAdmin();
  return (
    <main className="admin narrow">
      <Link href="/admin" className="back">← All people</Link>
      <h1>Add person</h1>
      <div className="panel">
        <CardForm action={createCard} />
      </div>
    </main>
  );
}
