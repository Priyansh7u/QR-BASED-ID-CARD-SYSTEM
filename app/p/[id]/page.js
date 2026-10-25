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
          <span className="id-title">ID CARDS</span>
          <span className="id-sub">Verified by the USAR EDC IPU</span>
        </header>

        <div className="stamp" aria-hidden="true">developer<br />Priyanshu</div>

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