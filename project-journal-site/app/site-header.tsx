import Link from 'next/link';
import { journalData } from './generated-journal';

export function SiteHeader({ active }: { active: 'overview' | 'world-generation' | 'posts' }) {
  const latestPost = journalData.historicalPosts.at(-1);
  return (
    <header className="site-header">
      <Link className="site-title" href="/">Project Journal</Link>
      <nav aria-label="Journal navigation">
        <Link aria-current={active === 'overview' ? 'page' : undefined} href="/">Overview</Link>
        <Link aria-current={active === 'world-generation' ? 'page' : undefined} href="/world-generation">World generation</Link>
        {latestPost && (
          <Link aria-current={active === 'posts' ? 'page' : undefined} href={`/posts/${latestPost.slug}`}>Posts</Link>
        )}
      </nav>
    </header>
  );
}
