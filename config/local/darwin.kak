# Surcharges macOS
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# Chargé uniquement quand `uname` renvoie Darwin.
# Tout ce qui est réellement portable doit rester dans config/*.kak ;
# ce fichier ne sert qu'aux irréductibles différences du Mac.

# Homebrew installe les outils GNU en préfixe « g » (gsed, gawk…) et les
# versions BSD de sed/awk diffèrent. Si un plugin s'en plaint, préférer
# `brew install gnu-sed` puis surcharger ici.

# La détection dynamique du presse-papier et du préfixe Kakoune couvre déjà les
# anciens chemins /opt/homebrew codés en dur : rien à surcharger de ce côté.

# LaTeX — recherche avant (sauter du source au bon endroit du PDF)
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# kakoune-lsp câble texlab sur zathura, qui convient au ThinkPad mais n'existe
# pas sur macOS. Skim est le seul visualiseur Mac courant à gérer SyncTeX ; il
# expose displayline pour ça (brew install --cask skim).
#
# Le hook est reposé dans le groupe du plugin, lsp-filetype-latex : les deux
# s'exécutent, le nôtre en dernier, donc c'est lui qui fixe lsp_servers.
# Sans Skim on ne touche à rien — le défaut zathura reste inopérant sur Mac,
# mais il est inoffensif tant qu'on n'appelle pas texlab-forward-search.
define-command -hidden latex-forward-search-skim %{
    hook -group lsp-filetype-latex global BufSetOption filetype=latex %{
        set-option buffer lsp_servers %{
            [texlab]
            root_globs = [".git", ".hg"]
            [texlab.settings.texlab]
            forwardSearch.executable = "/Applications/Skim.app/Contents/SharedSupport/displayline"
            forwardSearch.args = ["-r", "%l", "%p", "%f"]
        }
    }
}

evaluate-commands %sh{
    [ -x /Applications/Skim.app/Contents/SharedSupport/displayline ] \
        && printf 'latex-forward-search-skim\n'
    exit 0
}
