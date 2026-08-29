import { journalData } from '../generated-journal';
import { SiteHeader } from '../site-header';

const label = (value: string) => value.replaceAll('-', ' ');

export default function WorldGenerationPage() {
  return (
    <main>
      <SiteHeader active="world-generation" />
      <div className="page-shell article-shell">
        <section className="intro">
          <p className="eyebrow">Current system status</p>
          <h1>World generation</h1>
          <p className="lede">{journalData.currentStatements.worldGeneration.lead}</p>
          <p className="updated">Verified against project authority on {journalData.reviewedOn}</p>
        </section>

        <section>
          <h2>The plain-language picture</h2>
          <p>{journalData.currentStatements.worldGeneration.plainLanguage}</p>
          <p>{journalData.currentStatements.worldGeneration.runtime}</p>
        </section>

        <section>
          <h2>Four separate readings</h2>
          <div className="reading-grid">
            <article><h3>Knowledge</h3><p>{journalData.currentStatements.worldGeneration.knowledge}</p></article>
            <article><h3>Coverage</h3><p>{journalData.currentStatements.worldGeneration.coverage}</p></article>
            <article><h3>Implementation</h3><p>{journalData.currentStatements.worldGeneration.implementation}</p></article>
            <article><h3>Attention</h3><p>{journalData.currentStatements.worldGeneration.attention}</p></article>
          </div>
        </section>

        <section>
          <p className="eyebrow">Accepted foundation</p>
          <h2>{journalData.acceptedConcepts.length} accepted concepts</h2>
          <div className="table-wrap">
            <table>
              <thead><tr><th>ID</th><th>Accepted truth</th><th>Owner</th><th>Implementation</th></tr></thead>
              <tbody>
                {journalData.acceptedConcepts.map((concept) => (
                  <tr key={concept.id}>
                    <td className="id-cell">{concept.id}</td>
                    <td>{concept.truth}</td>
                    <td>{concept.owner}</td>
                    <td>{label(concept.implementation)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section>
          <p className="eyebrow">Not yet designed</p>
          <h2>{journalData.explorationTopics.length} active exploration topics</h2>
          <p className="section-intro">
            Lifecycle count: {Object.entries(journalData.counts.conceptLifecycle)
              .map(([state, count]) => `${count} ${label(state)}`)
              .join(' · ')}
          </p>
          <div className="topic-list">
            {journalData.explorationTopics.map((topic) => (
              <article key={topic.id}>
                <div><span className="id-cell">{topic.id}</span><span className="state-label">{label(topic.state)}</span></div>
                <h3>{topic.question}</h3>
                <p>Detailed owner: {topic.owner}</p>
              </article>
            ))}
          </div>
        </section>

        <section>
          <p className="eyebrow">Choices still open</p>
          <h2>{journalData.decisions.length} open decision groups</h2>
          <p className="section-intro">These are questions, not accepted architecture. Their presence here does not choose an option.</p>
          <ol className="decision-list">
            {journalData.decisions.map((decision) => (
              <li key={decision.id}><span>{decision.id}</span><strong>{decision.name}</strong></li>
            ))}
          </ol>
        </section>

        <p className="source-note">Current-view fingerprint: {journalData.fingerprint}</p>
      </div>
    </main>
  );
}
