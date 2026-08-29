import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { journalData } from '../../generated-journal';
import { SiteHeader } from '../../site-header';

export function generateStaticParams() {
  return journalData.historicalPosts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const post = journalData.historicalPosts.find((item) => item.slug === slug);
  if (!post) return { title: 'Post not found — Project Journal' };
  return { title: `${post.title} — Project Journal`, description: post.paragraphs[0] };
}

export default async function PostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = journalData.historicalPosts.find((item) => item.slug === slug);
  if (!post) notFound();

  return (
    <main>
      <SiteHeader active="posts" />
      <article className="page-shell prose-shell">
        <header>
          <p className="eyebrow">Historical snapshot · {post.snapshotDate}</p>
          <h1>{post.title}</h1>
          <p className="historical-note">This post records what the repository said at that time. It owns no current truth. Use the World generation page for the current repository-backed picture.</p>
        </header>
        <div className="article-body">
          {post.paragraphs.map((paragraph, index) => <p key={index}>{paragraph}</p>)}
        </div>
      </article>
    </main>
  );
}
