# Chargement des plugins
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# Remplace plug.kak *au démarrage*. Le gestionnaire reste utile pour installer
# et mettre à jour, mais il coûtait cher à chaque lancement : un fork de shell
# par plugin déclaré, un `find` sur chaque dépôt pour redécouvrir les .kak à
# sourcer, et la réécriture des fichiers .build/ — le tout refait intégralement
# à chaque `kak`. Mesuré sur le Mac : 0,50 s des 0,70 s de démarrage, pour douze
# plugins dont la liste ne bouge jamais.
#
# Ici les fichiers à sourcer sont écrits en clair dans 40-plugins.kak. Plus de
# découverte, plus de fork : le démarrage retombe à ~0,35 s, et ajouter un
# plugin ne coûte plus que le temps de lire son .kak.
#
# Deux commandes seulement, et volontairement bêtes :
#
#   plugin <répertoire> <dépôt>          déclare le plugin (métadonnée pure)
#   plugin-source <répertoire> <fichier> charge un de ses fichiers
#
# La configuration du plugin suit, en clair, dans 40-plugins.kak. Rien n'est
# passé sous forme de bloc %{…} à évaluer : Kakoune 2026.05.21 corrompt son
# analyseur dès qu'un `try` est imbriqué dans un bloc évalué dynamiquement
# (`try %{ evaluate-commands %arg{3} }`). On voit alors des noms de commandes
# amputés de leurs premiers caractères — « ove-highlighter » pour
# remove-highlighter — et le chargement s'arrête. Un fichier plat les évite.

declare-option -docstring "répertoire des plugins installés" \
    str plugin_dir "%val{config}/plugins"

# Renseigné par chaque appel à `plugin`, consommé par :plugin-install et
# :plugin-update. Un élément par plugin, de la forme « répertoire URL ».
declare-option -hidden str-list plugin_repos

# Kakoune n'a pas de `if`. L'idiome consiste à construire le nom de la commande
# à partir de la valeur de l'option booléenne : `do-if-true` exécute,
# `do-if-false` ne fait rien. Zéro fork, là où un %sh{} en coûterait un.
define-command -hidden do-if-true  -params 1.. %{ evaluate-commands %arg{@} }
define-command -hidden do-if-false -params 1.. %{ nop }

define-command plugin -params 2 -docstring %{
    plugin <répertoire> <dépôt>: déclare un plugin.

    <répertoire> nom du dossier sous plugins/ — c'est le nom du dépôt cloné,
                 pas une valeur libre : :plugin-install s'en sert comme cible.
    <dépôt>      URL passée à git clone.

    Ne charge rien par lui-même : c'est plugin-source qui s'en occupe. Un
    plugin déclaré sans aucun plugin-source est donc installé mais pas chargé,
    ce qu'attendent les thèmes.
} %{
    set-option -add global plugin_repos "%arg{1} %arg{2}"
}

define-command plugin-source -params 2 -docstring %{
    plugin-source <répertoire> <fichier>: source un fichier d'un plugin.
    <fichier> est relatif à la racine du dépôt cloné.

    Un dépôt pas encore cloné laisse une trace dans *debug* et n'interrompt
    pas le chargement de la config.
} %{
    try %{
        source "%opt{plugin_dir}/%arg{1}/%arg{2}"
    } catch %{
        echo -debug "plugin: %arg{1} absent ou incomplet (%arg{2})"
        echo -debug "plugin: lance :plugin-install"
    }
}

define-command plugin-install -docstring \
"plugin-install: clone les plugins déclarés qui manquent" %{
    plugin-run-git clone
}

define-command plugin-update -docstring \
"plugin-update: met à jour tous les plugins déjà clonés" %{
    plugin-run-git pull
}

# Le travail git tourne en arrière-plan et rend la main tout de suite : c'est du
# réseau, il n'a pas à bloquer l'éditeur. Le compte rendu arrive dans *debug*.
define-command -hidden plugin-run-git -params 1 %{
    echo "plugin-%arg{1} lancé en arrière-plan — suivi par :buffer *debug*"
    nop %sh{
        # $1 porte l'action ; il faut le mettre de côté avant que `eval set --`
        # ne réinstalle la liste des dépôts sur les paramètres positionnels.
        action=$1
        (
            eval set -- "$kak_quoted_opt_plugin_repos"
            for entry; do
                dir=${entry%% *}
                url=${entry#* }
                target="$kak_opt_plugin_dir/$dir"

                if [ "$action" = clone ]; then
                    if [ -e "$target" ]; then
                        continue
                    fi
                    git clone -q "$url" "$target" 2>&1 \
                        && msg="cloné" || msg="ÉCHEC du clone"
                else
                    if [ ! -d "$target/.git" ]; then
                        continue
                    fi
                    git -C "$target" pull -q --ff-only 2>&1 \
                        && msg="à jour" || msg="ÉCHEC de la mise à jour"
                fi

                # Un dépôt qui expose un colors/ est un thème : Kakoune ne
                # cherche ses colorschemes que sous config/colors, d'où le lien.
                if [ -d "$target/colors" ]; then
                    ln -sfn "$target" "$kak_config/colors/$dir"
                fi

                printf 'echo -debug %%{plugin: %s — %s}\n' "$dir" "$msg" \
                    | kak -p "$kak_session"
            done
            printf 'echo -debug %%{plugin: %s terminé}\n' "$action" \
                | kak -p "$kak_session"
        ) > /dev/null 2>&1 < /dev/null &
    }
}
