'use client';

import { useActionState } from 'react';
import { login } from '../actions';

export default function LoginPage() {
  const [state, action, pending] = useActionState(login, null);
  return (
    <main className="center-screen">
      <form action={action} className="panel login">
        <h1>Admin login</h1>
        <label>
          Password
          <input type="password" name="password" required autoFocus />
        </label>
        {state?.error && <p className="msg error">{state.error}</p>}
        <button className="btn primary" disabled={pending}>{pending ? 'Checking…' : 'Log in'}</button>
      </form>
    </main>
  );
}
