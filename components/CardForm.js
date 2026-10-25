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