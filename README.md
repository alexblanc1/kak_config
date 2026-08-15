# Config Kakoune — ThinkPad + Mac

Une seule configuration, un seul dépôt, pour Linux et macOS. Aucune ligne à
commenter/décommenter en changeant de machine : tout ce qui diffère est détecté
à l'exécution.

## Installation

```sh
git clone <ce-dépôt> ~/dotfiles/kak
sh ~/dotfiles/kak/install.sh
kak   # puis :plug-install
```

`install.sh` lie le dépôt sur `~/.config/kak`, recrée le symlink
`autoload/standard-library` vers l'installation Kakoune locale, clone `plug.kak`
et signale les dépendances manquantes.

## Arborescence

```
kakrc                      point d'entrée, ne fait que sourcer les modules
config/00-platform.kak     détection OS, préfixe Kakoune, LSP, ctags
config/10-options.kak      options globales et affichage
config/20-clipboard.kak    presse-papier système, multiplateforme
config/30-mappings.kak     raccourcis et hooks hors plugins
config/40-plugins.kak      plug.kak + tous les plugins
config/local/darwin.kak    surcharges macOS (versionnées)
config/local/linux.kak     surcharges Linux (versionnées)
local.kak                  surcharges de CETTE machine (non versionné)
bin/change-theme.pl        sélecteur de thème, portable
install.sh                 bootstrap
```

Ordre de chargement : `config/*.kak` par ordre alphabétique, puis
`config/local/<uname>.kak`, puis `local.kak` s'il existe.

---

## Ce qui bloquait le partage entre les deux machines

| Problème | Ancien état | Résolution |
|---|---|---|
| `autoload/standard-library` | symlink en dur vers `/opt/homebrew/Cellar/kakoune/2026.05.21/share/kak/rc` (Mac) — cassé sur le ThinkPad, et re-cassé à chaque mise à jour de Kakoune | gitignoré, recréé par `install.sh` à partir du binaire `kak` résolu |
| `change-theme.pl` | shebang `/home/linuxbrew/.linuxbrew/bin/env` d'un côté, chemin de thèmes `/opt/homebrew/share/kak/colors` de l'autre | shebang `/usr/bin/env perl`, préfixe déduit de `command -v kak` |
| Presse-papier | `xsel` en dur + kakboard (doublon) sur le ThinkPad ; **rien** sur le Mac | détection à l'exécution : `pbcopy` → `wl-copy` → `xsel` → `xclip` |
| `plugins/` versionné | des milliers de fichiers vendorisés, plus des `.build/*/hooks` contenant `/Users/blancalexandre/…` et `/home/alex/…` | gitignoré, reconstruit par `:plug-install` |
| `colors/kakoune` | symlink absolu créé par le hook de build catppuccin | gitignoré |
| LSP / wiki / lean | actifs sur le ThinkPad, **commentés** sur le Mac | plugins installés dans les deux cas ; LSP activé si le binaire existe, wiki activé si `~/wiki` existe |

## Fusion des réglages

**Repris du ThinkPad :** `wrap -word -indent`, `<c-d>` multi-curseur, mappings
ctags (`<a-=>`, `<space>t`), objet texte `e` pour les environnements LaTeX,
kakoune-buffers avec la permutation `^`/`q`, kakoune-lsp, kakoune-wiki, lean.kak.

**Repris du Mac :** la config de kakoune-filetree (`<space>f`, arbre dans la
fenêtre courante, `toolsclient`/`jumpclient` volontairement vides),
auto-pairs.kak.

**Commun aux deux, conservé tel quel :** `number-lines -relative`,
`show-whitespaces`, `indentwidth 4`, `ncurses_assistant=dilbert`, `modelinefmt`,
`jj` → échap, easymotion avec tes faces et tes mappings bidirectionnels,
text-objects, auto-percent, shellcheck, catppuccin_latte.

## Trois changements de comportement assumés

1. **`<c-w>`** ne lance plus `pdflatex` sur tous les buffers. L'ancien hook
   `RawKey` global compilait n'importe quel fichier ouvert ; le raccourci n'est
   désormais mappé que dans les buffers `filetype=latex`, via une commande
   `latex-build` qui remonte les erreurs au lieu de les avaler.
2. **kakboard n'est plus chargé.** Il faisait doublon avec le hook
   `RegisterModified` et ne marchait qu'en X11. La ligne pour le remettre est
   dans `config/local/linux.kak`.
3. **`<space>p` / `<space>P`** collent depuis le presse-papier système. Rien
   n'existait pour ça auparavant, et `p`/`P` natifs restent intacts.

## Dépendances optionnelles

| Outil | Sert à | macOS | Debian/Ubuntu |
|---|---|---|---|
| `kakoune-lsp` | LSP | `brew install kakoune-lsp` | `cargo install kakoune-lsp` |
| `ctags` | `<a-=>`, `<space>t` | `brew install universal-ctags` | `apt install universal-ctags` |
| `fzf` | `change-theme.pl` | `brew install fzf` | `apt install fzf` |
| `pdflatex` | `latex-build` | MacTeX | `apt install texlive` |
| presse-papier | yank/paste système | intégré (`pbcopy`) | `apt install xsel` ou `wl-clipboard` |

## Note macOS

`<a-space>` (easymotion) suppose que la touche Option est envoyée comme Meta.
Dans Terminal.app : Réglages → Profils → Clavier → « Use Option as Meta key ».
Dans iTerm2 : Profiles → Keys → Left Option key → Esc+. À défaut, la variante
`<c-space>` est prête dans `config/40-plugins.kak`, il suffit de la décommenter.
