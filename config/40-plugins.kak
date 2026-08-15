# Plugins
# ‾‾‾‾‾‾‾
# Union des deux dépôts. Ce qui était commenté côté Mac (lsp, wiki, lean) est
# ici chargé mais activé conditionnellement, donc plus besoin de commenter
# et décommenter des lignes à chaque changement de machine.

evaluate-commands %sh{
    plugins="$kak_config/plugins"
    mkdir -p "$plugins"
    [ ! -e "$plugins/plug.kak" ] && \
        git clone -q https://github.com/andreyorst/plug.kak.git "$plugins/plug.kak"
    printf "source '%s/plug.kak/rc/plug.kak'\n" "$plugins"
}

plug "andreyorst/plug.kak" noload

# --- LSP ---------------------------------------------------------------------
# Le plugin est toujours installé ; l'activation dépend de la présence du binaire
# (brew install kakoune-lsp, ou cargo install kakoune-lsp).
plug "https://github.com/kakoune-lsp/kakoune-lsp.git" config %{
    hook global WinSetOption filetype=(rust|python|haskell|c|cpp|go|ocaml|javascript|typescript|latex) %{
        evaluate-commands %sh{
            [ "$kak_opt_has_lsp" = true ] && printf 'try %%{ lsp-enable-window }\n'
            exit 0
        }
    }
}

# --- Outils ------------------------------------------------------------------
plug "https://github.com/whereswaldon/shellcheck.kak.git"

# --- Déplacement -------------------------------------------------------------
plug "https://github.com/alexblanc1/kakoune-easymotion-alex.git" config %{
    face global EasyMotionBackground rgb:000001
    face global EasyMotionForeground rgb:ee3a8c,rgb:000000+fg
    face global EasyMotionSelected   yellow+b

    # variantes bidirectionnelles
    map global easymotion e ': easy-motion-word<ret>' -docstring 'word ↔'
    map global easymotion l ': easy-motion-line<ret>' -docstring 'line ↔'
    map global easymotion c ': easy-motion-char<ret>' -docstring 'char ↔'
}

# Attention macOS : dans Terminal.app il faut cocher « Use Option as Meta key »
# pour que <a-space> soit reçu. Sinon, décommenter la variante <c-space>
# ci-dessous (elle pré-sélectionne l'écran entier avant d'entrer dans le mode).
map global normal <a-space> ': enter-user-mode easymotion<ret>'
# map global normal <c-space> ': execute-keys gtGb<ret>: enter-user-mode easymotion<ret>'

# --- Édition -----------------------------------------------------------------
plug "https://github.com/Delapouite/kakoune-text-objects.git"
plug "https://github.com/Delapouite/kakoune-auto-percent.git"

plug "https://github.com/alexherbo2/auto-pairs.kak.git" config %{
    enable-auto-pairs
}

# --- Navigation --------------------------------------------------------------
plug "https://github.com/occivink/kakoune-filetree.git" config %{
    # Arbre dans un simple buffer de la fenêtre courante : ni tmux ni client externe.
    map global user f ': filetree-switch-or-start -dirs-first -no-empty-dirs -consider-gitignore<ret>' -docstring 'filetree'
    # Dans le buffer *filetree* : <ret> ouvre, <a-flèches> naviguent entre frères/parent/enfant
}

plug 'delapouite/kakoune-buffers' config %{
    # Rappel : dans Kakoune (à l'inverse de Vim) Q enregistre et q rejoue.
    # Donc ^ = rejouer, <a-^> = enregistrer.
    map global normal ^     q
    map global normal <a-^> Q
    map global normal q     b
    map global normal Q     B
    map global normal <a-q> <a-b>
    map global normal <a-Q> <a-B>

    # ^ est une touche morte en AZERTY : seule, elle n'envoie rien au terminal
    # (il faut ^ puis Espace), et <a-^> est en pratique inatteignable — donc
    # impossible d'enregistrer une macro. Doublons directement tapables.
    # Obligatoirement en mode normal : depuis le mode user, l'enregistrement
    # s'arrête dès que le mode se dépile, la macro reste vide.
    map global normal <c-q> Q -docstring 'enregistrer / arrêter une macro'
    map global normal <c-p> q -docstring 'rejouer la macro'
    map global normal b ': enter-buffers-mode<ret>'            -docstring 'buffers'
    map global normal B ': enter-user-mode -lock buffers<ret>' -docstring 'buffers (lock)'
    map global user   b ': enter-user-mode buffers<ret>'       -docstring 'choisir un buffer'
    map global user   v ': enter-user-mode -lock buffers<ret>' -docstring 'choisir un buffer (lock)'
}

# --- Wiki --------------------------------------------------------------------
# Activé seulement si ~/wiki existe sur la machine.
plug "https://github.com/TeddyDD/kakoune-wiki.git" config %{
    evaluate-commands %sh{
        [ -d "$HOME/wiki" ] && printf 'wiki-setup %%{%s/wiki}\n' "$HOME"
        exit 0
    }
}

# --- Langages ----------------------------------------------------------------
plug "https://github.com/enricozb/lean.kak.git"

# --- Thème -------------------------------------------------------------------
plug "catppuccin/kakoune" theme config %{
    colorscheme catppuccin_latte
}
