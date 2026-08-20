# ██╗  ██╗ █████╗ ██╗  ██╗ ██████╗ ██╗   ██╗███╗   ██╗███████╗
# ██║ ██╔╝██╔══██╗██║ ██╔╝██╔═══██╗██║   ██║████╗  ██║██╔════╝
# █████╔╝ ███████║█████╔╝ ██║   ██║██║   ██║██╔██╗ ██║█████╗
# ██╔═██╗ ██╔══██║██╔═██╗ ██║   ██║██║   ██║██║╚██╗██║██╔══╝
# ██║  ██╗██║  ██║██║  ██╗╚██████╔╝╚██████╔╝██║ ╚████║███████╗
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
#
# Config unique, partagée entre le ThinkPad (Linux) et le Mac (macOS).
# Ce fichier ne contient AUCUN réglage : il ne fait qu'ordonner les modules.
#
#   config/00-platform.kak   détection OS / outils disponibles
#   config/05-plugin.kak     chargeur de plugins (remplace plug.kak au démarrage)
#   config/10-options.kak    options globales, affichage
#   config/20-clipboard.kak  presse-papier système (pbcopy / wl-copy / xsel / xclip)
#   config/30-mappings.kak   raccourcis et hooks indépendants des plugins
#   config/40-plugins.kak    tous les plugins et leurs raccourcis
#   config/local/<os>.kak    surcharges spécifiques à un OS (versionnées)
#   local.kak                surcharges spécifiques à CETTE machine (non versionné)

evaluate-commands %sh{
    os=$(uname | tr '[:upper:]' '[:lower:]')

    for module in "$kak_config"/config/*.kak; do
        [ -e "$module" ] || continue
        printf 'source %%{%s}\n' "$module"
    done

    if [ -e "$kak_config/config/local/$os.kak" ]; then
        printf 'source %%{%s}\n' "$kak_config/config/local/$os.kak"
    fi

    if [ -e "$kak_config/local.kak" ]; then
        printf 'source %%{%s}\n' "$kak_config/local.kak"
    fi

    exit 0
}
