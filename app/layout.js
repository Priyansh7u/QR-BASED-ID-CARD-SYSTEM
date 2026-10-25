import './globals.css';

export const metadata = { title: 'Official Legend ID™' };
export const viewport = { width: 'device-width', initialScale: 1, themeColor: '#ffd23f' };

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Bangers&family=Comic+Neue:wght@400;700&display=swap"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}