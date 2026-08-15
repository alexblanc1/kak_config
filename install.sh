#!/bin/sh
# Installation de la config Kakoune sur une nouvelle machine (macOS ou Linux).
#
#   git clone <ce-dépôt> ~/dotfiles/kak
#   sh ~/dotfiles/kak/install.sh
#
# Le script est idempotent : on peut le relancer après un `git pull`.

set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
TARGET="$CONFIG_HOME/kak"

info() { printf '\033[1;34m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

# --- 1. Lier le dépôt sur ~/.config/kak --------------------------------------
if [ "$REPO" = "$TARGET" ]; then
    info "le dépôt est déjà en place dans $TARGET"
elif [ -L "$TARGET" ]; then
    ln -sfn "$REPO" "$TARGET"
    info "symlink $TARGET → $REPO mis à jour"
elif [ -e "$TARGET" ]; then
    warn "$TARGET existe et n'est pas un lien : sauvegarde en $TARGET.bak"
    mv "$TARGET" "$TARGET.bak"
    ln -s "$REPO" "$TARGET"
else
    mkdir -p "$CONFIG_HOME"
    ln -s "$REPO" "$TARGET"
    info "symlink $TARGET → $REPO créé"
fi

# --- 2. Retrouver le préfixe d'installation de Kakoune -----------------------
KAK_BIN=$(command -v kak 2>/dev/null || true)
if [ -z "$KAK_BIN" ]; then
    warn "kak introuvable dans le PATH — installe-le (brew install kakoune) puis relance"
    exit 1
fi

while [ -L "$KAK_BIN" ]; do
    LINK=$(readlink "$KAK_BIN")
    case "$LINK" in
        /*) KAK_BIN=$LINK ;;
         *) KAK_BIN=$(dirname "$KAK_BIN")/$LINK ;;
    esac
done
PREFIX=$(dirname "$(dirname "$KAK_BIN")")
RUNTIME="$PREFIX/share/kak"
info "Kakoune détecté : $PREFIX"

# --- 3. Recréer le symlink autoload/standard-library -------------------------
# Dès qu'un répertoire autoload existe dans la config, Kakoune n'autocharge plus
# la bibliothèque standard : il faut la lier explicitement. Ce lien est propre à
# chaque machine, il n'est donc PAS versionné.
mkdir -p "$REPO/autoload"
if [ -d "$RUNTIME/rc" ]; then
    ln -sfn "$RUNTIME/rc" "$REPO/autoload/standard-library"
    info "autoload/standard-library → $RUNTIME/rc"
else
    warn "$RUNTIME/rc introuvable — la bibliothèque standard ne sera pas chargée"
fi

# --- 4. Amorcer plug.kak -----------------------------------------------------
mkdir -p "$REPO/plugins" "$REPO/colors"
if [ ! -e "$REPO/plugins/plug.kak" ]; then
    git clone -q https://github.com/andreyorst/plug.kak.git "$REPO/plugins/plug.kak"
    info "plug.kak cloné"
else
    info "plug.kak déjà présent"
fi

chmod +x "$REPO/bin/change-theme.pl" 2>/dev/null || true

# --- 5. Dépendances optionnelles ---------------------------------------------
for dep in ctags pdflatex fzf; do
    command -v "$dep" >/dev/null 2>&1 || warn "optionnel absent : $dep"
done

case "$(uname)" in
    Darwin)
        command -v pbcopy >/dev/null 2>&1 || warn "pbcopy absent (?)"
        ;;
    Linux)
        if ! command -v xsel >/dev/null 2>&1 \
           && ! command -v xclip >/dev/null 2>&1 \
           && ! command -v wl-copy >/dev/null 2>&1; then
            warn "aucun outil de presse-papier (xsel / xclip / wl-clipboard)"
        fi
        ;;
esac

if ! command -v kak-lsp >/dev/null 2>&1 && ! command -v kakoune-lsp >/dev/null 2>&1; then
    warn "kakoune-lsp absent : le LSP restera désactivé (brew install kakoune-lsp)"
fi

info "terminé — lance kak puis : :plug-install"
