import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Lift Log',
  description: 'A private, shared gym tracker.',
  manifest: '/manifest.webmanifest',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}

