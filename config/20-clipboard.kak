# Presse-papier système
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# Le ThinkPad appelait xsel en dur ET chargeait kakboard (doublon) ; le Mac
# n'avait rien du tout. Ici on choisit l'outil disponible à l'exécution :
#   macOS   → pbcopy / pbpaste
#   Wayland → wl-copy / wl-paste
#   X11     → xsel, sinon xclip
# Si rien n'est trouvé, les commandes échouent proprement au lieu de casser.

declare-option -hidden str clipboard_copy
declare-option -hidden str clipboard_paste

evaluate-commands %sh{
    if command -v pbcopy >/dev/null 2>&1; then
        copy='pbcopy'
        paste='pbpaste'
    elif [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
        copy='wl-copy'
        paste='wl-paste --no-newline'
    elif command -v xsel >/dev/null 2>&1; then
        copy='xsel --input --clipboard'
        paste='xsel --output --clipboard'
    elif command -v xclip >/dev/null 2>&1; then
        copy='xclip -selection clipboard -in'
        paste='xclip -selection clipboard -out'
    else
        copy=''
        paste=''
    fi

    printf 'set-option global clipboard_copy %%{%s}\n'  "$copy"
    printf 'set-option global clipboard_paste %%{%s}\n' "$paste"
    exit 0
}

# Tout yank part vers le presse-papier système, comme sur le ThinkPad.
hook global RegisterModified '"' %{ nop %sh{
    [ -n "$kak_opt_clipboard_copy" ] || exit 0
    printf %s "$kak_main_reg_dquote" | eval "$kak_opt_clipboard_copy"
}}

define-command clipboard-paste-after -docstring "coller le presse-papier système après la sélection" %{
    evaluate-commands %sh{
        [ -n "$kak_opt_clipboard_paste" ] || { printf 'fail %%{aucun outil de presse-papier détecté}\n'; exit 0; }
        printf 'execute-keys "<a-!>%%opt{clipboard_paste}<ret>"\n'
    }
}

define-command clipboard-paste-before -docstring "coller le presse-papier système avant la sélection" %{
    evaluate-commands %sh{
        [ -n "$kak_opt_clipboard_paste" ] || { printf 'fail %%{aucun outil de presse-papier détecté}\n'; exit 0; }
        printf 'execute-keys "!%%opt{clipboard_paste}<ret>"\n'
    }
}

map global user p ': clipboard-paste-after<ret>'  -docstring 'coller (presse-papier système)'
map global user P ': clipboard-paste-before<ret>' -docstring 'coller avant (presse-papier système)'
