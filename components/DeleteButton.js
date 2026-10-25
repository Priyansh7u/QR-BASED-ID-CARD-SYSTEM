'use client';

export default function DeleteButton({ action, id }) {
  return (
    <form
      action={action}
      onSubmit={(e) => {
        if (!confirm('Delete this person? Their QR code will stop working.')) e.preventDefault();
      }}
    >
      <input type="hidden" name="id" value={id} />
      <button className="btn danger">Delete person</button>
    </form>
  );
}
