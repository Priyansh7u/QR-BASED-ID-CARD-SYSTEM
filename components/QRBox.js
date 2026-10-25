'use client';

import { useEffect, useState } from 'react';
import QRCode from 'qrcode';

export default function QRBox({ id, name }) {
  const [url, setUrl] = useState('');
  const [png, setPng] = useState('');
  const [svg, setSvg] = useState('');
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const base = (process.env.NEXT_PUBLIC_SITE_URL || window.location.origin).replace(/\/$/, '');
    const link = `${base}/p/${id}`;
    setUrl(link);
    // 'H' error correction keeps the QR readable even if the card gets scratched
    const opts = { errorCorrectionLevel: 'H', margin: 2, color: { dark: '#000000', light: '#ffffff' } };
    QRCode.toDataURL(link, { ...opts, width: 1024 }).then(setPng);
    QRCode.toString(link, { ...opts, type: 'svg' }).then((s) =>
      setSvg(URL.createObjectURL(new Blob([s], { type: 'image/svg+xml' })))
    );
  }, [id]);

  const file = `qr-${(name || id).replace(/[^a-z0-9]+/gi, '-').toLowerCase()}`;

  return (
    <div className="qr-box">
      <div className="qr-img">{png ? <img src={png} alt="QR code" /> : <div className="qr-loading" />}</div>
      <p className="qr-url">{url}</p>
      <div className="row">
        <a className="btn primary" href={png} download={`${file}.png`}>Download PNG</a>
        <a className="btn" href={svg} download={`${file}.svg`}>Download SVG (print)</a>
      </div>
      <div className="row">
        <button
          type="button"
          className="btn ghost"
          onClick={() => {
            navigator.clipboard?.writeText(url);
            setCopied(true);
            setTimeout(() => setCopied(false), 1500);
          }}
        >
          {copied ? 'Copied!' : 'Copy link'}
        </button>
        <a className="btn ghost" href={url} target="_blank" rel="noreferrer">Open profile ↗</a>
      </div>
      <p className="hint">This QR is permanent. Editing the details later won't change it.</p>
    </div>
  );
}
