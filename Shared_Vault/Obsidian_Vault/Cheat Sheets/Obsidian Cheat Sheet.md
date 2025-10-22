Here’s a **comprehensive Obsidian Cheat Sheet** designed to help you master the essentials and advanced features of Obsidian for note-taking, knowledge management, and productivity.

---

# 🧠 Obsidian Cheat Sheet

## 📁 Basic Concepts

| Term | Description | |------|-------------| | **Vault** | A folder on your device that contains all your notes (Markdown files). | | **Note** | A single Markdown file (`.md`) inside your Vault. | | **Link** | Connects notes using `[[Note Name]]`. | | **Backlink** | A note that links _to_ the current note. | | **Graph View** | Visual representation of how your notes are connected. | | **Tag** | Metadata using `#tagname` for categorization. | | **YAML Frontmatter** | Metadata block at the top of a note using `---`. |

---

## ✍️ Markdown Syntax

| Feature | Syntax | Example | |--------|--------|---------| | Heading | `#`, `##`, `###` | `## Heading 2` | | Bold | `**text**` | **bold** | | Italic | `*text*` or `_text_` | _italic_ | | Strikethrough | `~~text~~` | ~~strikethrough~~ | | Code (inline) | `` `code` `` | `code` | | Code Block |

```
lang<br>code<br>
```

| `js<br>console.log("Hi")<br>` | | Bullet List | `-`, `*`, `+` | `- Item` | | Numbered List | `1.` | `1. First` | | Checkbox | `- [ ]` / `- [x]` | `- [x] Done` | | Link to Note | `[[Note Name]]` | `[[My Note]]` | | Embed Note | `![[Note Name]]` | Embeds full note | | External Link | `text` | Google | | Image | `!` | `!` | | Block Reference | `^block-id` | Refer to specific block |

---

## 🔗 Linking & Navigation

| Feature | Syntax | Description | |--------|--------|-------------| | Internal Link | `[[Note Name]]` | Links to another note | | Aliases | `[[Note Name|Alias]]` | Display different text | | Header Link | `[[Note#Header]]` | Link to a section | | Block Link | `[[Note^block-id]]` | Link to a block | | Tag | `#tag` | Add metadata | | Tag Pane | `Ctrl+Shift+T` | View all tags |

---

## ⚙️ Hotkeys (Windows/Linux)

| Action | Shortcut | |--------|----------| | Command Palette | `Ctrl+P` | | Quick Switcher | `Ctrl+O` | | Open Graph View | `Ctrl+G` | | Toggle Sidebar | `Ctrl+E` | | Create New Note | `Ctrl+N` | | Search | `Ctrl+Shift+F` | | Toggle Preview/Edit | `Ctrl+E` | | Open Daily Note | `Ctrl+Shift+D` | | Open Settings | `Ctrl+,` |

> 🔍 You can customize hotkeys in **Settings → Hotkeys**

---

## 🧩 Core Plugins

| Plugin | Purpose | |--------|---------| | **Daily Notes** | Create a note for each day | | **Templates** | Insert reusable content | | **Backlinks** | Show incoming links | | **Graph View** | Visualize connections | | **Tag Pane** | Browse tags | | **File Explorer** | Navigate files | | **Search** | Full-text search |

---

## 🧠 Advanced Features

### 📅 Daily Notes

- Enable in **Settings → Core Plugins**
- Customize location and format in **Settings → Daily Notes**

### 📄 Templates

- Create a folder for templates
- Use `{{date}}`, `{{time}}`, etc.
- Insert with `Ctrl+T` (if hotkey set)

### 📊 Graph View Tips

- Filter by tag or note
- Adjust repulsion, link distance, etc.
- Use local graph for focused view

### 🔍 Search Operators

| Operator | Example | Description | |----------|---------|-------------| | `tag:` | `tag:#project` | Search by tag | | `path:` | `path:"folder/"` | Search in folder | | `file:` | `file:NoteName` | Search in file | | `-"term"` | `-draft` | Exclude term | | `line:(text)` | `line:(meeting)` | Search in lines |

---

## 🧪 Community Plugins (Popular)

> Enable in **Settings → Community Plugins**

| Plugin | Use | |--------|-----| | **Dataview** | Query notes like a database | | **Calendar** | Visual calendar for daily notes | | **Templater** | Advanced templates with logic | | **Kanban** | Boards for task/project management | | **Tasks** | Manage and query tasks | | **Advanced Tables** | Better table editing | | **Periodic Notes** | Weekly/monthly notes |

---

## 📚 Dataview Basics

```dataview
table file.name, file.mtime
from "Projects"
where contains(tags, "#active")
sort file.mtime desc
```

- Use `table`, `list`, or `task`
- Query by tags, folders, dates, etc.

---

## 🛠 YAML Frontmatter Example

```yaml
---
title: "Project Plan"
tags: [project, planning]
created: 2025-09-03
aliases: ["Plan", "Strategy"]
---
```

---

## 🧼 Best Practices

- Use consistent naming conventions
- Organize with folders _or_ tags (not both)
- Use backlinks to build a knowledge graph
- Review Graph View weekly
- Use templates for recurring notes

---
