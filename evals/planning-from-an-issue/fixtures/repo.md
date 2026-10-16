# Fixture repository — `jot`, a notes CLI

A stand-in for the repository at the base SHA. Every eval in this directory plans against it;
treat the tree below as the whole repository, and the snippets as the files' relevant content.

```
jot/
├── package.json          # "bin": { "jot": "dist/cli.js" }; no runtime dependencies
├── src/
│   ├── cli.ts            # argument parsing; commands: add, list, rm
│   ├── store.ts          # load()/save() of ~/.jot/notes.json, a Note[] array
│   ├── format.ts         # formatNote(note): string — one line per note, for the terminal
│   └── types.ts          # type Note = { id: string; text: string; createdAt: string }
└── test/
    ├── store.test.ts     # round-trips load/save on a temp directory
    └── format.test.ts    # formatNote on three notes
```

```ts
// src/cli.ts (excerpt)
switch (cmd) {
  case 'add':
    store.save([...store.load(), newNote(args.join(' '))]);
    break;
  case 'list':
    for (const n of store.load()) console.log(formatNote(n));
    break;
  case 'rm':
    store.save(store.load().filter((n) => n.id !== args[0]));
    break;
  default:
    usage();
    process.exit(2);
}
```

**Declared gate** (the project's own, which the core resolves into commands): `typecheck`,
`lint`, `test`.
