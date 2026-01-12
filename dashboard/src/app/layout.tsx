import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { ApolloProvider } from '../providers/ApolloProvider';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'KYA Protocol Dashboard',
  description: 'Analytics dashboard for KYA Protocol',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <ApolloProvider>{children}</ApolloProvider>
      </body>
    </html>
  );
}
