# Détection de plateforme et des outils externes
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# Tout le reste de la config s'appuie sur ces options plutôt que sur des
# chemins ou des binaires codés en dur. C'est ce qui remplace les deux
# variantes divergentes des anciens dépôts.

declare-option -docstring "système hôte, en minuscules : darwin, linux, …" str os
declare-option -docstring "chemin d'installation de Kakoune (préfixe)"    str kak_prefix
declare-option -docstring "true si un binaire kakoune-lsp est disponible" bool has_lsp    false
declare-option -docstring "true si ctags est disponible"                  bool has_ctags  false

evaluate-commands %sh{
    printf 'set-option global os %%{%s}\n' "$(uname | tr '[:upper:]' '[:lower:]')"

    # Préfixe d'installation : /opt/homebrew/Cellar/... sur le Mac,
    # /home/linuxbrew/.linuxbrew/... sur le ThinkPad, /usr sur une distro classique.
    kak_bin=$(command -v kak 2>/dev/null)
    if [ -n "$kak_bin" ]; then
        # resolution des symlinks sans dépendre de realpath (absent de macOS < 12)
        while [ -L "$kak_bin" ]; do
            target=$(readlink "$kak_bin")
            case "$target" in
                /*) kak_bin=$target ;;
                 *) kak_bin=$(dirname "$kak_bin")/$target ;;
            esac
        done
        prefix=$(dirname "$(dirname "$kak_bin")")
        printf 'set-option global kak_prefix %%{%s}\n' "$prefix"
    fi

    if command -v kak-lsp >/dev/null 2>&1 || command -v kakoune-lsp >/dev/null 2>&1; then
        printf 'set-option global has_lsp true\n'
    fi

    if command -v ctags >/dev/null 2>&1; then
        printf 'set-option global has_ctags true\n'
    fi

    exit 0
}
