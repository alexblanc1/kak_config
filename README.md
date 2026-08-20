# Config Kakoune — ThinkPad + Mac

> Une seule configuration, un seul dépôt, deux machines.
> Rien à commenter/décommenter en changeant d'OS : tout ce qui diffère est
> détecté à l'exécution.

---

## Sommaire

- [Principe](#principe)
- [Installation](#installation)
- [Arborescence](#arborescence)
- [Les modules en détail](#les-modules-en-détail)
- [Aide-mémoire des raccourcis](#aide-mémoire-des-raccourcis)
- [Plugins](#plugins)
- [Thèmes](#thèmes)
- [Dépendances optionnelles](#dépendances-optionnelles)
- [Note macOS](#note-macos)
- [Personnaliser sans casser le partage](#personnaliser-sans-casser-le-partage)
- [Historique : ce qui bloquait le partage](#historique--ce-qui-bloquait-le-partage)

---

## Principe

Trois règles tiennent toute la config :

1. **`kakrc` ne contient aucun réglage.** Il ne fait qu'ordonner les modules de
   `config/`, dans l'ordre alphabétique.
2. **Aucun chemin absolu, aucun binaire codé en dur.** Le préfixe Kakoune, le
   presse-papier, le LSP et ctags sont détectés au démarrage et exposés comme
   options (`%opt{os}`, `%opt{kak_prefix}`, `%opt{has_lsp}`, `%opt{has_ctags}`).
3. **Rien de spécifique à une machine n'est versionné.** Les symlinks, les
   plugins compilés et les surcharges perso vivent hors du dépôt (`.gitignore`).

Conséquence : `git pull && sh install.sh` suffit sur n'importe quelle machine.

---

## Installation

```sh
git clone git@github.com:alexblanc1/kak_config.git ~/dotfiles/kak
sh ~/dotfiles/kak/install.sh
kak            # puis, dans Kakoune :
:plug-install
```

`install.sh` est **idempotent** — on peut le relancer après chaque `git pull`.
Il enchaîne cinq étapes :

| # | Étape | Détail |
|---|---|---|
| 1 | Lien du dépôt | `~/.config/kak` → le dépôt cloné (sauvegarde en `.bak` si un vrai dossier existe déjà) |
| 2 | Détection de Kakoune | résout les symlinks de `command -v kak` pour en déduire le préfixe d'installation |
| 3 | Bibliothèque standard | recrée `autoload/standard-library` → `<prefix>/share/kak/rc` |
| 4 | Amorçage de plug.kak | clone `plug.kak` s'il manque, `chmod +x` sur `bin/change-theme.pl` |
| 5 | Diagnostic | avertit pour chaque dépendance optionnelle absente |

> **Pourquoi l'étape 3 ?** Dès qu'un dossier `autoload/` existe dans la config,
> Kakoune cesse d'autocharger sa bibliothèque standard. Il faut donc la lier
> explicitement — et ce lien, propre à chaque machine, n'est pas versionné.

---

## Arborescence

```
kakrc                       point d'entrée — ne fait que sourcer les modules
│
├── config/
│   ├── 00-platform.kak     détection OS, préfixe Kakoune, LSP, ctags
│   ├── 10-options.kak      options globales et affichage
│   ├── 20-clipboard.kak    presse-papier système, multiplateforme
│   ├── 30-mappings.kak     raccourcis et hooks hors plugins
│   ├── 40-plugins.kak      plug.kak + tous les plugins
│   └── local/
│       ├── darwin.kak      surcharges macOS      (versionnées)
│       └── linux.kak       surcharges Linux      (versionnées)
│
├── local.kak               surcharges de CETTE machine (NON versionné)
├── bin/change-theme.pl     sélecteur de thème, portable
├── install.sh              bootstrap
│
├── autoload/               standard-library → symlink, non versionné
├── colors/                 thèmes ; colors/kakoune → symlink, non versionné
└── plugins/                géré par plug.kak, non versionné
```

**Ordre de chargement**

```
config/*.kak (alphabétique)  →  config/local/<uname>.kak  →  local.kak
```

Chaque étage peut écraser la précédente. `local.kak` a donc toujours le dernier
mot, et comme il est gitignoré, il ne pollue jamais l'autre machine.

---

## Les modules en détail

### `00-platform.kak` — la couche de détection

Déclare quatre options globales sur lesquelles tout le reste s'appuie :

| Option | Type | Contenu |
|---|---|---|
| `os` | `str` | `darwin`, `linux`, … (`uname` en minuscules) |
| `kak_prefix` | `str` | préfixe d'installation de Kakoune, déduit de `command -v kak` |
| `has_lsp` | `bool` | `true` si `kak-lsp` **ou** `kakoune-lsp` est dans le `PATH` |
| `has_ctags` | `bool` | `true` si `ctags` est dans le `PATH` |

La résolution des symlinks est faite à la main (boucle `readlink`) plutôt qu'avec
`realpath`, absent des macOS antérieurs à 12.

### `10-options.kak` — affichage et édition

| Réglage | Valeur |
|---|---|
| Numéros de ligne | `number-lines -relative` |
| Espaces | `show-whitespaces` |
| Retour à la ligne | `wrap -word -indent` |
| Indentation | `indentwidth 4`, `tabstop 4` |
| Marge de défilement | `scrolloff 3,3` |
| Assistant | `ncurses_assistant=dilbert` |
| Modeline | `nom-du-buffer ligne:colonne {context} {mode}` |
| `toolsclient` / `jumpclient` | **vides, volontairement** |

> Laisser `toolsclient` et `jumpclient` vides garde les outils (filetree, grep,
> LSP…) dans la fenêtre courante, au lieu d'aller chercher un client tmux qui
> n'existe pas forcément.

### `20-clipboard.kak` — presse-papier système

L'outil est choisi **au démarrage**, dans cet ordre :

```
pbcopy / pbpaste          (macOS)
wl-copy / wl-paste        (Wayland, si $WAYLAND_DISPLAY est défini)
xsel                      (X11)
xclip                     (X11, repli)
```

- Un hook `RegisterModified '"'` pousse **tout yank** vers le presse-papier système.
- `<space>p` / `<space>P` collent depuis le presse-papier système ; `p` / `P`
  natifs de Kakoune restent intacts.
- Si aucun outil n'est trouvé, les commandes échouent proprement avec un message
  au lieu de casser la config.

### `30-mappings.kak` — raccourcis et hooks

- `jj` en mode insertion → `<esc>` (via un hook `InsertChar`).
- Commande `select-or-add-cursor`, mappée sur `<c-d>` : le premier appel sélectionne
  le mot sous le curseur et l'arme comme motif de recherche, les suivants ajoutent
  un curseur sur l'occurrence suivante. Elle est **définie ici** : ce n'est ni un
  builtin Kakoune ni une commande de plugin, et le mapping l'appelait sans qu'elle
  existe nulle part.
- Les mappings ctags ne sont créés **que si** `ctags` est installé.
- Objet texte `e` pour les environnements LaTeX (`\begin{…}` … `\end{…}`).
- Commande `latex-build` : écrit le buffer, lance `pdflatex -interaction=nonstopmode`
  et **remonte le résultat** (`{Information}` ou `{Error}`) au lieu de l'avaler.
  Mappée sur `<c-w>`, **uniquement dans les buffers `filetype=latex`**.

### `40-plugins.kak` — plug.kak et les plugins

Amorce `plug.kak` (clone automatique s'il manque), puis déclare tous les
plugins. Ce qui était autrefois commenté d'un côté ou de l'autre (LSP, wiki,
lean) est désormais **toujours installé, mais activé conditionnellement**.

---

## Aide-mémoire des raccourcis

### Général

| Touche | Mode | Action |
|---|---|---|
| `jj` | insertion | échap |
| `<c-d>` | normal | curseur sur l'occurrence suivante du mot (écrase le défilement d'une demi-page natif) |
| `<space>p` / `<space>P` | normal | coller depuis le presse-papier système (après / avant) |
| `<a-space>` | normal | entrer dans le mode **easymotion** |
| `<space>f` | normal | ouvrir **filetree** |
| `<space>l` | normal | entrer dans le mode **LSP** |

### Buffers (kakoune-buffers)

Le plugin déplace les mappings natifs pour libérer `b` et `B` :

| Touche | Action | Remplace |
|---|---|---|
| `b` | mode buffers | ~~mot précédent~~ |
| `B` | mode buffers verrouillé | ~~mot précédent (WORD)~~ |
| `z` / `Z` | mot précédent / WORD précédent | ~~restaurer / sauvegarder les sélections~~ |
| `<a-z>` / `<a-Z>` | variantes `<a-b>` / `<a-B>` | ~~combiner les sélections~~ |
| `q` / `Q` | restaurer / sauvegarder les sélections | ~~rejouer / enregistrer une macro~~ |
| `<a-q>` / `<a-Q>` | combiner les sélections | — |
| `^` / `<a-^>` | rejouer / enregistrer une macro | — |
| `<c-p>` / `<c-q>` | rejouer / enregistrer une macro (doublons AZERTY) | — |
| `<space>b` | choisir un buffer | — |
| `<space>v` | choisir un buffer (mode verrouillé) | — |

⚠️ Dans Kakoune, contrairement à Vim, **`Q` enregistre et `q` rejoue**. Le tableau
ci-dessus suit cette convention : `^` rejoue, `<a-^>` enregistre.

En AZERTY, `^` est une **touche morte** : seule, elle n'envoie rien au terminal
(il faut faire `^` puis Espace), et `<a-^>` est en pratique inatteignable — donc
impossible d'enregistrer quoi que ce soit, et `^` échoue alors sur
`register '@' is empty`. D'où les doublons `<c-q>` / `<c-p>`, directement tapables.
Ils sont mappés en **mode normal** et pas en mode user : depuis le mode user,
l'enregistrement s'interrompt dès que le mode se dépile et la macro reste vide.

### Easymotion (`<a-space>`, puis)

| Touche | Cible | Sens |
|---|---|---|
| `w` / `q` | mot | → / ← |
| `W` / `Q` | WORD | → / ← |
| `f` / `<a-f>` | caractère | → / ← |
| `j` / `k` | ligne | ↓ / ↑ |
| `e` | mot | **↔** |
| `l` | ligne | **↔** |
| `c` | caractère | **↔** |

Les trois dernières (`e`, `l`, `c`) sont les variantes bidirectionnelles
ajoutées dans `config/40-plugins.kak`. Le mode easymotion garde `q` / `Q` pour
le retour en arrière : c'est un mode à part, non concerné par la permutation
`z` / `q` du mode normal.

### LaTeX

| Touche | Action |
|---|---|
| `<a-i>e` / `<a-a>e` | sélectionner l'intérieur / l'ensemble d'un environnement |
| `<c-w>` | `latex-build` (dans un buffer LaTeX uniquement) |

### LSP (`<space>l`, puis) — *si `kak-lsp` est installé*

`lsp-enable` est appelé au démarrage de Kakoune, mais aucun serveur de langage
n'est lancé tant qu'un buffer ne le réclame pas : il faut à la fois un filetype
reconnu et la racine de projet correspondante.

| Langage | Serveur | Racine attendue |
|---|---|---|
| Rust | `rust-analyzer` | `Cargo.toml` |
| Python | `pylsp` | `pyproject.toml`, `setup.py`, `poetry.lock` ou `.git` |
| LaTeX | `texlab` | `.git` |

Les réglages viennent de `rc/servers.kak` du plugin, pas de ce dépôt : il n'y a
donc rien à maintenir ici tant que les défauts conviennent. Seul le visualiseur
PDF de texlab est surchargé, côté macOS (voir plus bas).

> **texlab ne remonte pas de diagnostics à la volée.** Il ne les produit qu'à
> partir d'une compilation, non activée ici pour ne pas doubler `<c-w>`
> (`latex-build`). Complétion, survol et navigation fonctionnent normalement.

| Touche | Action |
|---|---|
| `d` | aller à la définition |
| `y` | aller à la définition du type |
| `r` | lister les références |
| `h` | afficher la documentation au curseur |
| `e` | lister erreurs et avertissements du projet |
| `n` / `p` | erreur suivante / précédente |
| `a` | actions de code |
| `f` | formater le buffer |
| `R` | renommer le symbole |
| `s` | aller à un symbole du document |

Le mode en contient davantage : ils s'affichent dans l'infobox à l'entrée du mode.

### ctags — *si `ctags` est installé*

| Touche | Action |
|---|---|
| `<a-=>` | `ctags-search` — aller à la définition |
| `<space>t` | `ctags-generate` — regénérer les tags |

---

## Plugins

| Plugin | Rôle | Activation |
|---|---|---|
| [`plug.kak`](https://github.com/andreyorst/plug.kak) | gestionnaire de plugins | toujours (`noload`) |
| [`kakoune-lsp`](https://github.com/kakoune-lsp/kakoune-lsp) | LSP | **si `%opt{has_lsp}`**, globalement au démarrage (`lsp-enable`) ; les serveurs eux-mêmes ne démarrent qu'au besoin |
| [`shellcheck.kak`](https://github.com/whereswaldon/shellcheck.kak) | lint des scripts shell | toujours |
| [`kakoune-easymotion-alex`](https://github.com/alexblanc1/kakoune-easymotion-alex) | saut visuel *(fork perso)* | toujours, faces et mappings personnalisés |
| [`kakoune-text-objects`](https://github.com/Delapouite/kakoune-text-objects) | objets texte supplémentaires | toujours |
| [`kakoune-auto-percent`](https://github.com/Delapouite/kakoune-auto-percent) | `%` implicite sur les commandes | toujours |
| [`auto-pairs.kak`](https://github.com/alexherbo2/auto-pairs.kak) | paires automatiques | toujours (`enable-auto-pairs`) |
| [`kakoune-filetree`](https://github.com/occivink/kakoune-filetree) | explorateur de fichiers | toujours, `-dirs-first -no-empty-dirs -consider-gitignore` |
| [`kakoune-buffers`](https://github.com/Delapouite/kakoune-buffers) | mode de gestion des buffers | toujours |
| [`kakoune-wiki`](https://github.com/TeddyDD/kakoune-wiki) | wiki personnel | **si `~/wiki` existe** |
| [`lean.kak`](https://github.com/enricozb/lean.kak) | support du langage Lean | toujours |
| [`catppuccin/kakoune`](https://github.com/catppuccin/kakoune) | thèmes | toujours — `catppuccin_latte` |

Dans le buffer `*filetree*` : `<ret>` ouvre le fichier, les `<a-flèches>`
naviguent entre frères, parent et enfants.

**Ajouter un plugin** : une ligne `plug "…"` dans `config/40-plugins.kak`, puis
`:plug-install` dans Kakoune.

---

## Thèmes

```sh
bin/change-theme.pl              # sélection interactive via fzf
bin/change-theme.pl catppuccin   # filtre par nom
```

Le script cherche les thèmes dans `colors/` **et** dans
`<prefix>/share/kak/colors` (préfixe déduit de `command -v kak`, pas codé en
dur). Il réécrit ensuite la ligne `colorscheme` dans le premier fichier qui en
contient une :

```
local.kak  →  config/40-plugins.kak  →  kakrc
```

Si aucun n'en contient, il ajoute la ligne à `local.kak` — donc en dehors du
dépôt, sans toucher à la config partagée.

---

## Dépendances optionnelles

Aucune n'est requise : la config démarre sans, en désactivant simplement la
fonctionnalité correspondante.

| Outil | Sert à | macOS | Debian/Ubuntu |
|---|---|---|---|
| `kakoune-lsp` | LSP | `brew install kakoune-lsp` | `cargo install kakoune-lsp` |
| `rust-analyzer` | LSP Rust | release GitHub dans `~/.local/bin`, ou `rustup component add rust-analyzer` | idem |
| `texlab` | LSP LaTeX | `brew install texlab` | `apt install texlab`, ou `cargo install --locked texlab` |
| `pylsp` | LSP Python | `pipx install "python-lsp-server[pyflakes,rope]"` | idem |
| `Skim` | recherche avant LaTeX (macOS) | `brew install --cask skim` | — (zathura, déjà le défaut) |
| `ctags` | `<a-=>`, `<space>t` | `brew install universal-ctags` | `apt install universal-ctags` |
| `fzf` | `change-theme.pl` | `brew install fzf` | `apt install fzf` |
| `pdflatex` | `latex-build` | MacTeX | `apt install texlive` |
| presse-papier | yank/paste système | intégré (`pbcopy`) | `apt install xsel` ou `wl-clipboard` |

---

## Note macOS

`<a-space>` (easymotion) suppose que la touche **Option** est envoyée comme
**Meta** :

- **Terminal.app** — Réglages → Profils → Clavier → « Use Option as Meta key »
- **iTerm2** — Profiles → Keys → Left Option key → `Esc+`

À défaut, la variante `<c-space>` est déjà écrite dans
`config/40-plugins.kak` : il suffit de la décommenter.

**LaTeX.** kakoune-lsp câble la recherche avant de texlab (sauter du source au
bon endroit du PDF) sur **zathura**, qui convient au ThinkPad mais n'existe pas
sur macOS. `config/local/darwin.kak` la rebascule sur **Skim**, seul visualiseur
Mac courant à gérer SyncTeX — mais seulement s'il est installé
(`brew install --cask skim`). Sans lui, le défaut zathura reste en place : il ne
sert à rien sur Mac, sans pour autant gêner le reste de texlab.

---

## Personnaliser sans casser le partage

| Ce que tu veux faire | Où l'écrire |
|---|---|
| Un réglage valable partout | `config/<NN>-….kak` |
| Un réglage propre à macOS ou Linux | `config/local/darwin.kak` / `linux.kak` |
| Un réglage propre à **cette** machine | `local.kak` *(gitignoré)* |
| Ajouter un plugin | `config/40-plugins.kak`, puis `:plug-install` |
| Un nouveau module | `config/50-….kak` — sourcé automatiquement |

Ce qui est **volontairement gitignoré** :

```
plugins/                      reconstruit par :plug-install
autoload/standard-library     symlink recréé par install.sh
colors/kakoune                symlink créé par le hook de build catppuccin
local.kak                     surcharges par machine
*.swp  .DS_Store
```

---

## Historique : ce qui bloquait le partage

<details>
<summary>Les sept points corrigés lors de la fusion des deux dépôts</summary>

<br>

| Problème | Ancien état | Résolution |
|---|---|---|
| `autoload/standard-library` | symlink en dur vers `/opt/homebrew/Cellar/kakoune/2026.05.21/share/kak/rc` (Mac) — cassé sur le ThinkPad, et re-cassé à chaque mise à jour de Kakoune | gitignoré, recréé par `install.sh` à partir du binaire `kak` résolu |
| `change-theme.pl` | shebang `/home/linuxbrew/.linuxbrew/bin/env` d'un côté, chemin de thèmes `/opt/homebrew/share/kak/colors` de l'autre | shebang `/usr/bin/env perl`, préfixe déduit de `command -v kak` |
| Presse-papier | `xsel` en dur + kakboard (doublon) sur le ThinkPad ; **rien** sur le Mac | détection à l'exécution : `pbcopy` → `wl-copy` → `xsel` → `xclip` |
| `plugins/` versionné | des milliers de fichiers vendorisés, plus des `.build/*/hooks` contenant `/Users/blancalexandre/…` et `/home/alex/…` | gitignoré, reconstruit par `:plug-install` |
| `colors/kakoune` | symlink absolu créé par le hook de build catppuccin | gitignoré |
| LSP / wiki / lean | actifs sur le ThinkPad, **commentés** sur le Mac | toujours installés ; LSP activé si le binaire existe, wiki activé si `~/wiki` existe |
| `<c-w>` | un hook `RawKey` **global** lançait `pdflatex` sur n'importe quel buffer ouvert | commande `latex-build`, mappée seulement sur `filetype=latex`, et qui remonte les erreurs |

### Fusion des réglages

**Repris du ThinkPad** — `wrap -word -indent`, `<c-d>` multi-curseur, mappings
ctags (`<a-=>`, `<space>t`), objet texte `e` pour LaTeX, kakoune-buffers avec la
permutation `^`/`q`, kakoune-lsp, kakoune-wiki, lean.kak.

**Repris du Mac** — la config de kakoune-filetree (`<space>f`, arbre dans la
fenêtre courante, `toolsclient`/`jumpclient` volontairement vides),
auto-pairs.kak.

**Commun aux deux, conservé tel quel** — `number-lines -relative`,
`show-whitespaces`, `indentwidth 4`, `ncurses_assistant=dilbert`, `modelinefmt`,
`jj` → échap, easymotion (faces et mappings bidirectionnels), text-objects,
auto-percent, shellcheck, `catppuccin_latte`.

### Changements de comportement assumés

1. **`<c-w>`** ne compile plus que dans les buffers LaTeX.
2. **kakboard n'est plus chargé** — doublon avec le hook `RegisterModified`, et
   limité à X11. La ligne pour le remettre est dans `config/local/linux.kak`.
3. **`<space>p` / `<space>P`** collent depuis le presse-papier système. Rien
   n'existait pour ça auparavant ; `p` / `P` natifs restent intacts.

</details>
