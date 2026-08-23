# Plugins
# ‾‾‾‾‾‾‾
# Union des deux dépôts. Ce qui était commenté côté Mac (lsp, wiki, lean) est
# ici chargé mais activé conditionnellement, donc plus besoin de commenter
# et décommenter des lignes à chaque changement de machine.
#
# Le chargement passe par config/05-plugin.kak, et non plus par plug.kak : voir
# l'en-tête de ce fichier-là pour le pourquoi, et pour la raison très concrète
# qui impose des `source` en clair ici plutôt qu'une jolie commande maison.
#
# Chaque plugin est déclaré par `plugin` (métadonnée pour :plugin-install), puis
# ses fichiers sont sourcés dans un `try`. Un dépôt pas encore cloné laisse donc
# un message dans *debug* au lieu d'interrompre le reste de la config — ce qui
# arrive à chaque fois qu'on installe la config sur une nouvelle machine.
#
# Installer ce qui manque : :plugin-install — mettre à jour : :plugin-update

# --- LSP ---------------------------------------------------------------------
# Le plugin est toujours installé ; l'activation dépend de la présence du binaire
# (brew install kakoune-lsp, ou cargo install kakoune-lsp). Les serveurs de
# langage s'installent séparément — rust-analyzer vit dans ~/.local/bin.
plugin kakoune-lsp https://github.com/kakoune-lsp/kakoune-lsp.git
try %{
    source "%opt{plugin_dir}/kakoune-lsp/rc/lsp.kak"
    source "%opt{plugin_dir}/kakoune-lsp/rc/servers.kak"

    # Le binaire est fourni par Homebrew sous son ancien nom, kak-lsp, qui est
    # justement la valeur par défaut de l'option lsp_cmd : rien à câbler.
    #
    # lsp-enable est global et tourne au démarrage, là où l'ancien
    # lsp-enable-window attendait l'ouverture d'un buffer d'un filetype listé.
    # Il ne lance aucun serveur par lui-même : il se contente de poser les
    # hooks. Un serveur ne démarre que si le filetype du buffer en déclare un
    # (rc/servers.kak du plugin) et que ses root_globs sont présents —
    # rust-analyzer réclame un Cargo.toml. Rien ne tourne donc en dehors des
    # projets concernés, et la liste de filetypes à tenir à jour disparaît.
    #
    # rust-analyzer : rc/servers.kak fournit déjà root_globs, la vérification
    # via clippy et les libellés de symboles. Le binaire est simplement cherché
    # dans le PATH — ici ~/.local/bin/rust-analyzer, installé à la main.
    evaluate-commands "do-if-%opt{has_lsp} lsp-enable"

    # marksman : complétion et navigation entre notes Markdown, table des
    # matières, diagnostics sur les liens cassés (brew install marksman).
    #
    # rc/servers.kak le déclare déjà, mais avec .marksman.toml pour seule racine
    # de projet. Sans ce fichier, kakoune-lsp retombe sur le répertoire du
    # fichier ouvert, que marksman rejette — « Workspace folder is bogus » dans
    # *debug*. Le serveur continue de répondre sur le buffer courant (symboles,
    # table des matières), mais ne charge aucun autre fichier : ni complétion de
    # liens, ni saut vers une autre note, ni détection des liens morts.
    #
    # On lui donne donc les racines usuelles, celles que marksman reconnaît
    # lui-même. Pour un dossier de notes hors dépôt git — un wiki, par exemple —
    # un .marksman.toml vide à sa racine suffit à le faire adopter.
    #
    # Le hook du plugin est retiré, pas seulement doublé : chaque `set-option
    # buffer lsp_servers` déclenche lsp-did-change-config, donc laisser les deux
    # s'exécuter fait démarrer deux marksman — celui de la config d'origine, sur
    # une racine que le serveur refuse, puis le nôtre.
    #
    # command pointe sur un shim et non sur marksman directement : le serveur
    # renvoie des URI non encodées dès qu'un nom de note porte un accent, ce qui
    # fait paniquer kakoune-lsp au lieu de suivre le lien. Voir l'en-tête de
    # bin/marksman-uri-fix ; retirer cette ligne suffit à revenir au serveur nu.
    #
    # Le bloc est en guillemets et non en %{} : seules les chaînes en guillemets
    # développent %val{config}, %{} est littéral. D'où aussi les apostrophes
    # côté TOML — des guillemets imbriqués demanderaient à être doublés.
    remove-hooks global lsp-filetype-markdown
    hook -group lsp-filetype-markdown global BufSetOption filetype=markdown %{
        set-option buffer lsp_servers "
            [marksman]
            root_globs = ['.marksman.toml', '.git', '.hg']
            command = '%val{config}/bin/marksman-uri-fix'
            args = ['server']
        "
    }
} catch %{ echo -debug "plugin kakoune-lsp : %val{error}" }

# Le plugin remplit tout le mode lsp (d définition, r références, h survol,
# e diagnostics, R renommer…), mais ne lui donne aucun point d'entrée.
map global user l ': enter-user-mode lsp<ret>' -docstring 'lsp'

# --- Outils ------------------------------------------------------------------
plugin shellcheck.kak https://github.com/whereswaldon/shellcheck.kak.git
try %{
    source "%opt{plugin_dir}/shellcheck.kak/shellcheck.kak"
} catch %{ echo -debug "plugin shellcheck.kak : %val{error}" }

# --- Déplacement -------------------------------------------------------------
plugin kakoune-easymotion-alex https://github.com/alexblanc1/kakoune-easymotion-alex.git
try %{
    source "%opt{plugin_dir}/kakoune-easymotion-alex/easymotion.kak"

    face global EasyMotionBackground rgb:000001
    face global EasyMotionForeground rgb:ee3a8c,rgb:000000+fg
    face global EasyMotionSelected   yellow+b

    # variantes bidirectionnelles
    map global easymotion e ': easy-motion-word<ret>' -docstring 'word ↔'
    map global easymotion l ': easy-motion-line<ret>' -docstring 'line ↔'
    map global easymotion c ': easy-motion-char<ret>' -docstring 'char ↔'
} catch %{ echo -debug "plugin kakoune-easymotion-alex : %val{error}" }

# Attention macOS : dans Terminal.app il faut cocher « Use Option as Meta key »
# pour que <a-space> soit reçu. Sinon, décommenter la variante <c-space>
# ci-dessous (elle pré-sélectionne l'écran entier avant d'entrer dans le mode).
map global normal <a-space> ': enter-user-mode easymotion<ret>'
# map global normal <c-space> ': execute-keys gtGb<ret>: enter-user-mode easymotion<ret>'

# --- Édition -----------------------------------------------------------------
plugin kakoune-text-objects https://github.com/Delapouite/kakoune-text-objects.git
try %{
    source "%opt{plugin_dir}/kakoune-text-objects/text-objects.kak"
} catch %{ echo -debug "plugin kakoune-text-objects : %val{error}" }

plugin kakoune-auto-percent https://github.com/Delapouite/kakoune-auto-percent.git
try %{
    source "%opt{plugin_dir}/kakoune-auto-percent/auto-percent.kak"
} catch %{ echo -debug "plugin kakoune-auto-percent : %val{error}" }

plugin auto-pairs.kak https://github.com/alexherbo2/auto-pairs.kak.git
try %{
    source "%opt{plugin_dir}/auto-pairs.kak/rc/auto-pairs.kak"
    enable-auto-pairs
} catch %{ echo -debug "plugin auto-pairs.kak : %val{error}" }

# --- Navigation --------------------------------------------------------------
plugin kakoune-filetree https://github.com/occivink/kakoune-filetree.git
try %{
    source "%opt{plugin_dir}/kakoune-filetree/filetree.kak"

    # Arbre dans un simple buffer de la fenêtre courante : ni tmux ni client externe.
    map global user f ': filetree-switch-or-start -dirs-first -no-empty-dirs -consider-gitignore<ret>' -docstring 'filetree'
    # Dans le buffer *filetree* : <ret> ouvre, <a-flèches> naviguent entre frères/parent/enfant
} catch %{ echo -debug "plugin kakoune-filetree : %val{error}" }

plugin kakoune-buffers https://github.com/Delapouite/kakoune-buffers.git
try %{
    source "%opt{plugin_dir}/kakoune-buffers/buffers.kak"
} catch %{ echo -debug "plugin kakoune-buffers : %val{error}" }

# Rappel : dans Kakoune (à l'inverse de Vim) Q enregistre et q rejoue.
# Donc ^ = rejouer, <a-^> = enregistrer.
map global normal ^     q
map global normal <a-^> Q
map global normal z     b
map global normal Z     B
map global normal <a-z> <a-b>
map global normal <a-Z> <a-B>

# z et q permutés : q récupère la sauvegarde/restauration de sélections.
# Les mappings de Kakoune ne sont pas récursifs, donc q exécute bien le z
# natif et non le z remappé ci-dessus.
map global normal q     z
map global normal Q     Z
map global normal <a-q> <a-z>
map global normal <a-Q> <a-Z>

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

# --- Wiki --------------------------------------------------------------------
# Activé seulement si ~/wiki existe sur la machine (has_wiki, cf. 00-platform).
plugin kakoune-wiki https://github.com/TeddyDD/kakoune-wiki.git
try %{
    source "%opt{plugin_dir}/kakoune-wiki/rc/wiki.kak"
    evaluate-commands "do-if-%opt{has_wiki} wiki-setup %opt{wiki_dir}"
} catch %{ echo -debug "plugin kakoune-wiki : %val{error}" }

# --- Rust : ownership et durées de vie ---------------------------------------
# RustOwl souligne, sous le curseur, la durée de vie de la variable, ses
# emprunts et ses déplacements — vert la durée de vie, bleu l'emprunt immuable,
# violet l'emprunt mutable, orange un déplacement ou un appel, rouge une erreur
# de durée de vie.
#
# Son analyse passe par une méthode LSP non standard (rustowl/cursor) que le
# binaire kakoune-lsp ne sait pas router : d'où un plugin autonome, avec son
# propre démon, plutôt qu'un second serveur déclaré dans lsp_config.
#
# Le binaire s'installe à part (script officiel du dépôt, il atterrit dans
# ~/.rustowl) ; sans lui, has_rustowl reste false et rien n'est câblé.
define-command -hidden rustowl-map-toggle %{
    map global user r ': rustowl-toggle<ret>' -docstring 'rustowl (ownership)'
}

plugin kak-rustowl https://github.com/alexblanc1/kak-rustowl.git
try %{
    source "%opt{plugin_dir}/kak-rustowl/rc/rustowl.kak"

    set-option global rustowl_cmd %opt{rustowl_bin}

    # Pas d'activation automatique : la toute première analyse d'un projet
    # passe par cargo et prend plusieurs secondes. On l'active à la demande,
    # fenêtre par fenêtre ; ensuite les requêtes reviennent en ~0,2 s.
    evaluate-commands "do-if-%opt{has_rustowl} rustowl-map-toggle"
} catch %{ echo -debug "plugin kak-rustowl : %val{error}" }

# --- Langages ----------------------------------------------------------------
plugin lean.kak https://github.com/enricozb/lean.kak.git
try %{
    source "%opt{plugin_dir}/lean.kak/rc/syntax.kak"
    source "%opt{plugin_dir}/lean.kak/rc/lsp.kak"
    source "%opt{plugin_dir}/lean.kak/kakoune/src/kakscripts/init-kakoune-rs-logging.kak"
} catch %{ echo -debug "plugin lean.kak : %val{error}" }

# --- Thème -------------------------------------------------------------------
# Aucun source : rien à charger au démarrage. :plugin-install repère le colors/
# du dépôt et le relie dans config/colors, où colorscheme va le chercher.
plugin kakoune https://github.com/catppuccin/kakoune.git
try %{
    colorscheme catppuccin_latte

    # Deux surcharges, après le colorscheme puisqu'il écrase tout ce qui précède.
    # catppuccin rend title en couleur de texte simplement graissée, et header —
    # celui que markdown.kak applique à tous les titres « # … » — dans un gris
    # plus clair que la prose : les titres reculent au lieu de ressortir. Les
    # deux teintes viennent de la palette du thème, rien d'autre ne bouge.
    face global header rgb:fe640b+b    # peach
    face global title  rgb:e64553+b    # maroon
} catch %{ echo -debug "thème catppuccin : %val{error}" }
