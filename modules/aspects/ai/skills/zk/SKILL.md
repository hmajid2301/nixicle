---
name: zk
description: Use the zk CLI to search, read, edit, create, and navigate notes in the current notebook.
---

# zk

Use this skill whenever working with notes in a zk notebook.

## Rules

- Prefer `zk` over generic file tools when working with notes.
- Discover paths before reading.
- Use notebook-relative paths.
- Prefer surgical edits over rewriting whole notes.

## Notebook resolution

Usually resolve the notebook in this order:

1. explicit user-provided notebook path
2. `ZK_NOTEBOOK_DIR`
3. `ZK_DIR`
4. current directory or parent containing `.zk`

## Common commands

### Find notes

```bash
zk list --quiet --format '{{path}}\t{{title}}\t{{join tags ","}}'
```

Search by text:

```bash
zk list --quiet --match 'query' --format '{{path}}\t{{title}}\t{{join tags ","}}'
```

Filter by tag:

```bash
zk list --quiet --tag tag-name --format '{{path}}\t{{title}}'
```

### Read a note

```bash
zk edit --print path/to/note.md
```

### Create a note

```bash
zk new --no-input 'Title'
```

In a subdirectory:

```bash
zk new dir/ --no-input 'Title'
```

With a template:

```bash
zk new --template daily --no-input 'Title'
```

### List tags

```bash
zk tag list --format '{{name}}\t{{note-count}}'
```

### Link graph

Backlinks to a note:

```bash
zk list --link-to path/to/note.md --format '{{path}}\t{{title}}'
```

Outbound links from a note:

```bash
zk list --linked-by path/to/note.md --format '{{path}}\t{{title}}'
```

Related notes:

```bash
zk list --related path/to/note.md --format '{{path}}\t{{title}}'
```

## Editing guidance

- Read the note first.
- Prefer exact text replacement.
- Preserve frontmatter, links, tags, and formatting.
- For append-style changes, add a blank line separator.

## Suggested workflow

1. Resolve notebook.
2. Search notes to find candidate paths.
3. Read the target note.
4. Edit or append carefully.
5. Summarize changed note paths clearly.
