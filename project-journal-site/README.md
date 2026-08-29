# Project Journal website

This folder contains the human-readable browser view of the repository's
Project Journal. It is a derived view, not a second source of truth.

The website reads its facts from the authoritative repository documents and
`docs/project-journal/SYSTEMS.json`. Run these commands from this folder:

```powershell
npm run sync
npm run dev
```

Open `http://localhost:3000` to read the Journal locally.

Before accepting any related documentation change, verify that the generated
website data is current:

```powershell
npm run check:journal
npm run check:render
npm run build
```

Do not manually edit `app/generated-journal.ts`; `npm run sync` owns it.
