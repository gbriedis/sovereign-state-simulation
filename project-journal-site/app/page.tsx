import Link from 'next/link';
import { journalData } from './generated-journal';
import { SiteHeader } from './site-header';

const label = (value: string) => value.replaceAll('-', ' ');

export default function Home() {
  const currentSystems = journalData.systems.filter((system) => system.attention === 'now');
  const productSystems = journalData.systems.filter((system) => system.kind === 'product');
  const supportSystems = journalData.systems.filter((system) => system.kind === 'support');

  return (
    <main>
      <SiteHeader active="overview" />

      <div className="page-shell">
        <section className="intro">
          <p className="eyebrow">State of Consequence</p>
          <h1>A clear view of the project</h1>
          <p className="lede">{journalData.focus}</p>
          <p className="updated">Verified against project authority on {journalData.reviewedOn}</p>
        </section>

        <section aria-labelledby="summary-heading">
          <h2 id="summary-heading">At a glance</h2>
          <div className="summary-grid">
            <div><strong>{journalData.counts.systems}</strong><span>mapped systems</span></div>
            <div><strong>{journalData.counts.acceptedConcepts}</strong><span>accepted world concepts</span></div>
            <div><strong>{journalData.counts.explorationTopics}</strong><span>recognized topics</span></div>
            <div><strong>{journalData.counts.openDecisions}</strong><span>open decisions</span></div>
          </div>
        </section>

        <section aria-labelledby="now-heading">
          <div className="section-heading">
            <div>
              <p className="eyebrow">Current work</p>
              <h2 id="now-heading">What needs attention now</h2>
            </div>
            <Link className="text-link" href="/world-generation">Read the full status →</Link>
          </div>
          <div className="focus-list">
            {currentSystems.map((system) => (
              <article key={system.id}>
                <h3>{system.name}</h3>
                <p>{system.purpose}</p>
                <dl>
                  <div><dt>Knowledge</dt><dd>{label(system.knowledgeState)}</dd></div>
                  <div><dt>Implementation</dt><dd>{label(system.implementationState)}</dd></div>
                </dl>
              </article>
            ))}
          </div>
        </section>

        <section aria-labelledby="map-heading">
          <p className="eyebrow">Complete overview</p>
          <h2 id="map-heading">Project System Map</h2>
          <p className="section-intro">Knowledge, coverage, implementation, and attention are separate. The connection list then shows where every system sits and what it depends on, uses, feeds, constrains, or supports.</p>
          <SystemTable title="Product systems" systems={productSystems} />
          <SystemTable title="Project support" systems={supportSystems} />
          <SystemConnections />
        </section>

        <section aria-labelledby="posts-heading">
          <p className="eyebrow">Project history</p>
          <h2 id="posts-heading">Latest post</h2>
          {journalData.historicalPosts.map((post) => (
            <article className="post-preview" key={post.slug}>
              <p className="updated">Historical snapshot · {post.snapshotDate}</p>
              <h3>{post.title}</h3>
              <p>{post.paragraphs[0]}</p>
              <Link className="text-link" href={`/posts/${post.slug}`}>Read the post →</Link>
            </article>
          ))}
        </section>
      </div>
    </main>
  );
}

function SystemTable({ title, systems }: { title: string; systems: typeof journalData.systems }) {
  return (
    <div className="system-group">
      <h3>{title}</h3>
      <div className="table-wrap">
        <table>
          <thead>
            <tr><th>System</th><th>Knowledge</th><th>Coverage</th><th>Implementation</th><th>Attention</th></tr>
          </thead>
          <tbody>
            {systems.map((system) => (
              <tr key={system.id}>
                <td><strong>{system.name}</strong><span>{system.purpose}</span></td>
                <td>{label(system.knowledgeState)}</td>
                <td>{label(system.coverage)}</td>
                <td>{label(system.implementationState)}</td>
                <td>{label(system.attention)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function SystemConnections() {
  return (
    <div className="connections" aria-labelledby="connections-heading">
      <h3 id="connections-heading">How the systems connect</h3>
      <p className="section-intro">Every registered system appears below. “Part of” shows hierarchy; the remaining lines show directed relationships.</p>
      <div className="connection-list">
        {journalData.systems.map((system) => {
          const links = journalData.systemLinks.filter((link) => link.source === system.id);
          return (
            <article key={system.id}>
              <h4>{system.name}</h4>
              {links.length > 0 ? (
                <ul>
                  {links.map((link) => (
                    <li key={`${link.type}-${link.target}`}>
                      <span>{label(link.type)}</span> {link.targetName}
                    </li>
                  ))}
                </ul>
              ) : <p>No registered parent or outgoing relationship.</p>}
            </article>
          );
        })}
      </div>
    </div>
  );
}
