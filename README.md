# Kakoune config — ThinkPad + Mac

> One configuration, one repository, two machines.
> Nothing to comment out when switching OS: whatever differs is detected at
> runtime.

---

## Contents

- [How it works](#how-it-works)
- [Installing](#installing)
- [Layout](#layout)
- [The modules, one by one](#the-modules-one-by-one)
- [Key reference](#key-reference)
- [Plugins](#plugins)
- [RustOwl — ownership and lifetimes](#rustowl--ownership-and-lifetimes)
- [Themes](#themes)
- [Optional dependencies](#optional-dependencies)
- [macOS notes](#macos-notes)
- [Customising without breaking the share](#customising-without-breaking-the-share)
- [History: what used to stand in the way](#history-what-used-to-stand-in-the-way)

---

## How it works

Three rules hold the whole thing together:

1. **`kakrc` contains no settings.** All it does is order the modules under
   `config/`, alphabetically.
2. **No absolute paths, no hardcoded binaries.** The Kakoune prefix, the
   clipboard tool, the LSP client and ctags are all detected at startup and
   exposed as options (`%opt{os}`, `%opt{kak_prefix}`, `%opt{has_lsp}`,
   `%opt{has_ctags}`, `%opt{has_wiki}`).
3. **Nothing machine-specific is versioned.** Symlinks, cloned plugins and
   personal overrides live outside the repository (`.gitignore`).

Which means `git pull && sh install.sh` is enough on any machine.

---

## Installing

```sh
git clone git@github.com:alexblanc1/kak_config.git ~/dotfiles/kak
sh ~/dotfiles/kak/install.sh
kak            # then, inside Kakoune:
:plugin-install
```

`install.sh` is **idempotent** — rerun it after every `git pull`. It goes
through five steps:

| # | Step | Detail |
|---|---|---|
| 1 | Link the repository | `~/.config/kak` → the clone (backs up to `.bak` if a real directory is already there) |
| 2 | Locate Kakoune | resolves the symlinks behind `command -v kak` to work out the install prefix |
| 3 | Standard library | recreates `autoload/standard-library` → `<prefix>/share/kak/rc` |
| 4 | Plugin directories | creates `plugins/` and `colors/`, `chmod +x` on `bin/change-theme.pl` |
| 5 | Diagnostics | warns about every optional dependency that's missing |

> **Why step 3?** As soon as an `autoload/` directory exists in the config,
> Kakoune stops autoloading its standard library. So it has to be linked
> explicitly — and that link, being machine-specific, isn't versioned.

---

## Layout

```
kakrc                       entry point — only sources the modules
│
├── config/
│   ├── 00-platform.kak     detects OS, Kakoune prefix, LSP, ctags, wiki
│   ├── 05-plugin.kak       plugin loader (:plugin-install / :plugin-update)
│   ├── 10-options.kak      global options and display
│   ├── 20-clipboard.kak    system clipboard, cross-platform
│   ├── 30-mappings.kak     bindings and hooks that don't involve plugins
│   ├── 40-plugins.kak      every plugin and its configuration
│   └── local/
│       ├── darwin.kak      macOS overrides    (versioned)
│       └── linux.kak       Linux overrides    (versioned)
│
├── local.kak               overrides for THIS machine (NOT versioned)
├── bin/change-theme.pl     portable theme picker
├── install.sh              bootstrap
│
├── autoload/               standard-library → symlink, not versioned
├── colors/                 themes; colors/kakoune → symlink, not versioned
└── plugins/                cloned by :plugin-install, not versioned
```

**Load order**

```
config/*.kak (alphabetical)  →  config/local/<uname>.kak  →  local.kak
```

Each stage can override the previous one. `local.kak` always gets the last word,
and since it's gitignored it never leaks onto the other machine.

---

## The modules, one by one

### `00-platform.kak` — the detection layer

Declares the global options everything else leans on:

| Option | Type | Holds |
|---|---|---|
| `os` | `str` | `darwin`, `linux`, … (`uname`, lowercased) |
| `kak_prefix` | `str` | Kakoune's install prefix, derived from `command -v kak` |
| `has_lsp` | `bool` | `true` if `kak-lsp` **or** `kakoune-lsp` is on the `PATH` |
| `has_ctags` | `bool` | `true` if `ctags` is on the `PATH` |
| `has_wiki` | `bool` | `true` if `~/wiki` exists |
| `has_rustowl` | `bool` | `true` if the `rustowl` binary is around |

Symlinks are resolved by hand, with a `readlink` loop, rather than with
`realpath`, which macOS didn't ship before version 12.

### `10-options.kak` — display and editing

| Setting | Value |
|---|---|
| Line numbers | `number-lines -relative` |
| Whitespace | `show-whitespaces` |
| Wrapping | `wrap -word -indent` |
| Indentation | `indentwidth 4`, `tabstop 4` |
| Scroll margin | `scrolloff 3,3` |
| Assistant | `ncurses_assistant=dilbert` |
| Modeline | `buffer-name line:column {context} {mode}` |
| `toolsclient` / `jumpclient` | **empty, deliberately** |

> Leaving `toolsclient` and `jumpclient` empty keeps the tools (filetree, grep,
> LSP…) in the current window instead of hunting for a tmux client that may well
> not exist.

### `20-clipboard.kak` — system clipboard

The tool is picked **at startup**, in this order:

```
pbcopy / pbpaste          (macOS)
wl-copy / wl-paste        (Wayland, when $WAYLAND_DISPLAY is set)
xsel                      (X11)
xclip                     (X11, fallback)
```

- A `RegisterModified '"'` hook pushes **every yank** to the system clipboard.
- `<space>p` / `<space>P` paste from the system clipboard; Kakoune's own `p` /
  `P` are untouched.
- If nothing is found, the commands fail cleanly with a message instead of
  breaking the config.

### `30-mappings.kak` — bindings and hooks

- `jj` in insert mode → `<esc>`, through an `InsertChar` hook.
- A `select-or-add-cursor` command bound to `<c-d>`: the first press selects the
  word under the cursor and arms it as the search pattern, later presses add a
  cursor on the next occurrence. It's **defined here** — it's neither a Kakoune
  builtin nor a plugin command, and the binding used to call something that
  existed nowhere.
- The ctags bindings are only created **if** ctags is installed.
- Text object `e` for LaTeX environments (`\begin{…}` … `\end{…}`).
- A `latex-build` command: writes the buffer, runs `pdflatex
  -interaction=nonstopmode`, and **surfaces the result** (`{Information}` or
  `{Error}`) instead of swallowing it. Bound to `<c-w>`, **only in
  `filetype=latex` buffers**.

### `05-plugin.kak` — the plugin loader

This replaces **plug.kak** at startup. The manager forked a shell per declared
plugin, plus a `find` across each repository to rediscover its `.kak` files, plus
a rewrite of its own `.build/` files — all of it redone from scratch on every
`kak`. On the Mac that came to **0.50s out of a 0.70s startup**, for twelve
plugins whose list never changes.

Here the files to source are written out plainly in `40-plugins.kak`. No
discovery, no forking: **startup drops to about 0.38s**, and adding a plugin now
costs no more than the time to read its `.kak`.

Two commands, deliberately dumb:

| Command | Does |
|---|---|
| `plugin <directory> <repository>` | declares the plugin — pure metadata, loads nothing |
| `:plugin-install` | clones any declared repository that's missing, in the background |
| `:plugin-update` | `git pull --ff-only` on the ones already cloned |

The last two return immediately and report progress in `*debug*`. A repository
that ships a `colors/` directory is treated as a theme and linked into
`config/colors`, where `colorscheme` goes looking.

> **Why plain `source` lines instead of a tidy little command of our own?**
> Kakoune 2026.05.21 corrupts its parser as soon as a `try` sits inside a
> dynamically evaluated block (`try %{ evaluate-commands %arg{3} }`), or as soon
> as a plugin is sourced from the body of a defined command: loading a plugin
> defines new commands, which invalidates the view onto the body currently
> running. You then get command names with their first characters chopped off —
> `ove-highlighter` for `remove-highlighter` — and loading stops. A flat file,
> with top-level `source` lines, avoids all of it.

### `40-plugins.kak` — the plugins

Declares every plugin, loads its files, then configures it. What used to be
commented out on one machine or the other (LSP, wiki, lean) is now **always
installed, but conditionally enabled**.

Each plugin loads inside a `try`: a repository that hasn't been cloned yet leaves
a message in `*debug*` instead of cutting the rest of the config short — which is
exactly what happens on a fresh machine.

---

## Key reference

### General

| Key | Mode | Action |
|---|---|---|
| `jj` | insert | escape |
| `<c-d>` | normal | cursor on the next occurrence of the word (replaces the native half-page scroll) |
| `<space>p` / `<space>P` | normal | paste from the system clipboard (after / before) |
| `<a-space>` | normal | enter **easymotion** mode |
| `<space>f` | normal | open **filetree** |
| `<space>l` | normal | enter **LSP** mode |
| `<space>r` | normal | **RustOwl** — underline ownership under the cursor |

### Buffers (kakoune-buffers)

The plugin shifts the native bindings around to free up `b` and `B`:

| Key | Action | Replaces |
|---|---|---|
| `b` | buffers mode | ~~previous word~~ |
| `B` | locked buffers mode | ~~previous WORD~~ |
| `z` / `Z` | previous word / previous WORD | ~~restore / save selections~~ |
| `<a-z>` / `<a-Z>` | the `<a-b>` / `<a-B>` variants | ~~combine selections~~ |
| `q` / `Q` | restore / save selections | ~~replay / record a macro~~ |
| `<a-q>` / `<a-Q>` | combine selections | — |
| `^` / `<a-^>` | replay / record a macro | — |
| `<c-p>` / `<c-q>` | replay / record a macro (AZERTY stand-ins) | — |
| `<space>b` | pick a buffer | — |
| `<space>v` | pick a buffer (locked mode) | — |

⚠️ In Kakoune, unlike Vim, **`Q` records and `q` replays**. The table above
follows that: `^` replays, `<a-^>` records.

On an AZERTY keyboard `^` is a **dead key**: on its own it sends nothing to the
terminal (you have to press `^` then space), and `<a-^>` is effectively
unreachable — so there's no way to record anything, and `^` then fails with
`register '@' is empty`. Hence the directly typeable `<c-q>` / `<c-p>`
stand-ins. They're bound in **normal mode** rather than user mode: from user
mode, recording stops the moment the mode pops and the macro comes out empty.

### Easymotion (`<a-space>`, then)

| Key | Target | Direction |
|---|---|---|
| `w` / `q` | word | → / ← |
| `W` / `Q` | WORD | → / ← |
| `f` / `<a-f>` | character | → / ← |
| `j` / `k` | line | ↓ / ↑ |
| `e` | word | **↔** |
| `l` | line | **↔** |
| `c` | character | **↔** |

The last three (`e`, `l`, `c`) are bidirectional variants added in
`config/40-plugins.kak`. Easymotion mode keeps `q` / `Q` for going backwards:
it's a mode of its own, untouched by the `z` / `q` swap in normal mode.

### LaTeX

| Key | Action |
|---|---|
| `<a-i>e` / `<a-a>e` | select the inside / the whole of an environment |
| `<c-w>` | `latex-build` (LaTeX buffers only) |

### LSP (`<space>l`, then) — *if `kak-lsp` is installed*

`lsp-enable` runs when Kakoune starts, but no language server launches until a
buffer asks for one: it takes both a recognised filetype and the matching project
root.

| Language | Server | Root it expects |
|---|---|---|
| Rust | `rust-analyzer` | `Cargo.toml` |
| Python | `pylsp` | `pyproject.toml`, `setup.py`, `poetry.lock` or `.git` |
| LaTeX | `texlab` | `.git` |
| Markdown | `marksman` | `.marksman.toml`, `.git` or `.hg` |

The settings come from the plugin's own `rc/servers.kak`, not from this
repository, so there's nothing to maintain here as long as the defaults suit.
Two exceptions: texlab's PDF viewer, overridden on macOS (see below), and
marksman's project root.

> **Why marksman's root is widened.** `rc/servers.kak` accepts `.marksman.toml`
> and nothing else. Without that file kakoune-lsp falls back to the directory of
> the open file, which marksman then refuses — `Workspace folder is bogus` in
> `*debug*`. The server still answers about the current buffer (symbols, table of
> contents) but loads no other file, so link completion, jumping to another note
> and dead-link diagnostics are all silently gone. `config/40-plugins.kak` puts
> the usual roots back. For a notes folder outside a git repository — a wiki, say
> — an empty `.marksman.toml` at its root is enough to have it adopted.

> **texlab doesn't report diagnostics as you type.** It only produces them from a
> build, which isn't enabled here so as not to duplicate `<c-w>`
> (`latex-build`). Completion, hover and navigation work normally.

| Key | Action |
|---|---|
| `d` | go to definition |
| `y` | go to type definition |
| `r` | list references |
| `h` | show documentation at the cursor |
| `e` | list the project's errors and warnings |
| `n` / `p` | next / previous error |
| `a` | code actions |
| `f` | format the buffer |
| `R` | rename the symbol |
| `s` | go to a document symbol |

The mode holds more than that; they show up in the infobox when you enter it.

### ctags — *if `ctags` is installed*

| Key | Action |
|---|---|
| `<a-=>` | `ctags-search` — go to definition |
| `<space>t` | `ctags-generate` — regenerate the tags |

---

## Plugins

| Plugin | Role | Enabled |
|---|---|---|
| [`kakoune-lsp`](https://github.com/kakoune-lsp/kakoune-lsp) | LSP | **if `%opt{has_lsp}`**, globally at startup (`lsp-enable`); the servers themselves only start when needed |
| [`shellcheck.kak`](https://github.com/whereswaldon/shellcheck.kak) | shell script linting | always |
| [`kakoune-easymotion-alex`](https://github.com/alexblanc1/kakoune-easymotion-alex) | visual jumps *(personal fork)* | always, with custom faces and bindings |
| [`kakoune-text-objects`](https://github.com/Delapouite/kakoune-text-objects) | extra text objects | always |
| [`kakoune-auto-percent`](https://github.com/Delapouite/kakoune-auto-percent) | implicit `%` on commands | always |
| [`auto-pairs.kak`](https://github.com/alexherbo2/auto-pairs.kak) | automatic pairs | always (`enable-auto-pairs`) |
| [`kakoune-filetree`](https://github.com/occivink/kakoune-filetree) | file explorer | always, `-dirs-first -no-empty-dirs -consider-gitignore` |
| [`kakoune-buffers`](https://github.com/Delapouite/kakoune-buffers) | buffer management mode | always |
| [`kakoune-wiki`](https://github.com/TeddyDD/kakoune-wiki) | personal wiki | **if `~/wiki` exists** |
| [`kak-rustowl`](https://github.com/alexblanc1/kak-rustowl) | Rust ownership and lifetimes | **if `%opt{has_rustowl}`** — on demand, via `<space>r` |
| [`lean.kak`](https://github.com/enricozb/lean.kak) | Lean language support | always |
| [`catppuccin/kakoune`](https://github.com/catppuccin/kakoune) | themes | always — `catppuccin_latte` |

Inside the `*filetree*` buffer, `<ret>` opens the file and the `<a-arrows>`
move between siblings, parent and children.

**Adding a plugin**: in `config/40-plugins.kak`, one `plugin <directory>
<repository>` line and a `try %{ source "%opt{plugin_dir}/…" }`, then
`:plugin-install` inside Kakoune.

---

## RustOwl — ownership and lifetimes

`<space>r` turns [RustOwl](https://github.com/cordx56/rustowl) on in the current
window. Put the cursor on a variable and the buffer underlines itself: green for
its lifetime, blue for an immutable borrow, purple for a mutable one, orange for
a move or a call that consumes it, red for a lifetime error.

Enabling it is **manual and per window**, deliberately: the very first analysis
of a project compiles that project. After that, every pause of the cursor fires a
query that comes back in about 0.2s.

The plugin lives in [its own repository](https://github.com/alexblanc1/kak-rustowl)
because it couldn't go through kakoune-lsp. RustOwl exposes its analysis via a
non-standard LSP method, `rustowl/cursor`, while the `kakoune-lsp` binary only
routes a closed set of methods compiled into it. Adding it there would have meant
patching kak-lsp in Rust and keeping a fork alive. So the plugin speaks the
protocol directly, through a Python daemon that holds one RustOwl server per
project for the length of the session.

The `rustowl` binary installs separately; without it `has_rustowl` stays `false`
and nothing gets wired up — not even the binding.

---

## Themes

```sh
bin/change-theme.pl              # interactive picker through fzf
bin/change-theme.pl catppuccin   # filter by name
```

The script looks for themes in `colors/` **and** in `<prefix>/share/kak/colors`
(the prefix being derived from `command -v kak`, not hardcoded). It then rewrites
the `colorscheme` line in the first file that has one:

```
local.kak  →  config/40-plugins.kak  →  kakrc
```

If none of them does, it appends the line to `local.kak` — outside the
repository, leaving the shared config alone.

---

## Optional dependencies

None of these are required: the config starts without them and simply turns the
matching feature off.

| Tool | Used for | macOS | Debian/Ubuntu |
|---|---|---|---|
| `kakoune-lsp` | LSP | `brew install kakoune-lsp` | `cargo install kakoune-lsp` |
| `rust-analyzer` | Rust LSP | GitHub release into `~/.local/bin`, or `rustup component add rust-analyzer` | same |
| `rustowl` | Rust ownership (`<space>r`) | `curl -fsSL .../rustowl/main/install.sh \| sh` → `~/.rustowl` | same |
| `texlab` | LaTeX LSP | `brew install texlab` | `apt install texlab`, or `cargo install --locked texlab` |
| `pylsp` | Python LSP | `pipx install "python-lsp-server[pyflakes,rope]"` | same |
| `marksman` | Markdown LSP | `brew install marksman` | GitHub release binary (`artempyanykh/marksman`) |
| `Skim` | LaTeX forward search (macOS) | `brew install --cask skim` | — (zathura, already the default) |
| `ctags` | `<a-=>`, `<space>t` | `brew install universal-ctags` | `apt install universal-ctags` |
| `fzf` | `change-theme.pl` | `brew install fzf` | `apt install fzf` |
| `pdflatex` | `latex-build` | MacTeX | `apt install texlive` |
| a clipboard tool | system yank/paste | built in (`pbcopy`) | `apt install xsel` or `wl-clipboard` |

---

## macOS notes

`<a-space>` (easymotion) assumes the **Option** key is sent as **Meta**:

- **Terminal.app** — Settings → Profiles → Keyboard → "Use Option as Meta key"
- **iTerm2** — Profiles → Keys → Left Option key → `Esc+`

Failing that, the `<c-space>` variant is already written out in
`config/40-plugins.kak`; just uncomment it.

**LaTeX.** kakoune-lsp wires texlab's forward search — jumping from the source to
the right spot in the PDF — to **zathura**, which is fine on the ThinkPad but
doesn't exist on macOS. `config/local/darwin.kak` switches it to **Skim**, the
only common Mac viewer that handles SyncTeX — but only when it's actually
installed (`brew install --cask skim`). Without it the zathura default stays put:
useless on a Mac, but harmless to the rest of texlab.

---

## Customising without breaking the share

| What you want | Where it goes |
|---|---|
| A setting that holds everywhere | `config/<NN>-….kak` |
| A setting specific to macOS or Linux | `config/local/darwin.kak` / `linux.kak` |
| A setting specific to **this** machine | `local.kak` *(gitignored)* |
| Adding a plugin | `config/40-plugins.kak`, then `:plugin-install` |
| A new module | `config/50-….kak` — sourced automatically |

What's **deliberately gitignored**:

```
plugins/                      rebuilt by :plugin-install
autoload/standard-library     symlink recreated by install.sh
colors/kakoune                symlink created by the catppuccin build hook
local.kak                     per-machine overrides
*.swp  .DS_Store
```

---

## History: what used to stand in the way

<details>
<summary>The seven things fixed when the two repositories were merged</summary>

<br>

| Problem | How it was | Fix |
|---|---|---|
| `autoload/standard-library` | hardcoded symlink to `/opt/homebrew/Cellar/kakoune/2026.05.21/share/kak/rc` (Mac) — broken on the ThinkPad, and broken again on every Kakoune update | gitignored, recreated by `install.sh` from the resolved `kak` binary |
| `change-theme.pl` | `/home/linuxbrew/.linuxbrew/bin/env` shebang on one side, `/opt/homebrew/share/kak/colors` theme path on the other | `/usr/bin/env perl` shebang, prefix derived from `command -v kak` |
| Clipboard | hardcoded `xsel` plus kakboard (doing the same thing) on the ThinkPad; **nothing** on the Mac | runtime detection: `pbcopy` → `wl-copy` → `xsel` → `xclip` |
| `plugins/` versioned | thousands of vendored files, plus `.build/*/hooks` holding `/Users/blancalexandre/…` and `/home/alex/…` | gitignored, rebuilt by `:plugin-install` |
| `colors/kakoune` | absolute symlink created by the catppuccin build hook | gitignored |
| LSP / wiki / lean | live on the ThinkPad, **commented out** on the Mac | always installed; LSP enabled if the binary exists, wiki enabled if `~/wiki` exists |
| `<c-w>` | a **global** `RawKey` hook fired `pdflatex` on any open buffer | a `latex-build` command, bound only for `filetype=latex`, that surfaces errors |

### Merging the settings

**Kept from the ThinkPad** — `wrap -word -indent`, the `<c-d>` multi-cursor,
ctags bindings (`<a-=>`, `<space>t`), the `e` text object for LaTeX,
kakoune-buffers with the `^`/`q` swap, kakoune-lsp, kakoune-wiki, lean.kak.

**Kept from the Mac** — the kakoune-filetree setup (`<space>f`, tree in the
current window, `toolsclient`/`jumpclient` left empty on purpose),
auto-pairs.kak.

**Common to both, kept as is** — `number-lines -relative`, `show-whitespaces`,
`indentwidth 4`, `ncurses_assistant=dilbert`, `modelinefmt`, `jj` → escape,
easymotion (faces and bidirectional bindings), text-objects, auto-percent,
shellcheck, `catppuccin_latte`.

### Behaviour changes, accepted

1. **`<c-w>`** only builds in LaTeX buffers now.
2. **kakboard is no longer loaded** — it duplicated the `RegisterModified` hook
   and only worked on X11. The line to bring it back sits in
   `config/local/linux.kak`.
3. **`<space>p` / `<space>P`** paste from the system clipboard. Nothing did that
   before; the native `p` / `P` are untouched.

</details>
