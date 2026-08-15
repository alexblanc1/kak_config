# Raccourcis et hooks (hors plugins)
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# jj en insertion → échap
hook global InsertChar j %{ try %{
    execute-keys -draft hH <a-k>jj<ret> d
    execute-keys -with-hooks <esc>
}}

# Multi-curseur sur le mot courant (venait du ThinkPad, commenté côté Mac)
map global normal <c-d> ': select-or-add-cursor<ret>' -docstring 'curseur sur le mot suivant'

# ctags — mappés seulement si ctags est installé
evaluate-commands %sh{
    [ "$kak_opt_has_ctags" = true ] || exit 0
    cat <<'EOF'
map global normal <a-=> ': ctags-search<ret>'
map global user   t     ': ctags-generate<ret>' -docstring 'regénérer les tags'
EOF
}

# LaTeX
# ‾‾‾‾‾
map global object e -docstring 'environnement LaTeX' 'c\\\\begin\{[a-zA-Z]*\},\\\\end\{[a-zA-Z]*\}<ret>'

define-command latex-build -docstring "écrire le buffer et le compiler avec pdflatex" %{
    write
    evaluate-commands %sh{
        if ! command -v pdflatex >/dev/null 2>&1; then
            printf 'fail %%{pdflatex introuvable}\n'
            exit 0
        fi
        cd "$(dirname "$kak_buffile")" 2>/dev/null || exit 0
        if pdflatex -interaction=nonstopmode "$kak_buffile" >/dev/null 2>&1; then
            printf 'echo -markup %%{{Information}pdflatex : ok}\n'
        else
            printf 'echo -markup %%{{Error}pdflatex : échec — voir le .log}\n'
        fi
    }
}

# <c-w> ne compile plus que dans les buffers LaTeX (l'ancien hook RawKey global
# lançait pdflatex sur n'importe quel fichier).
hook global WinSetOption filetype=latex %{
    map window normal <c-w> ': latex-build<ret>' -docstring 'compiler (pdflatex)'
}
