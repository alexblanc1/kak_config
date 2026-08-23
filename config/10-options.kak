# Options globales
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter global/ number-lines -relative
add-highlighter global/ show-whitespaces
add-highlighter global/ wrap -word -indent     # venait du ThinkPad uniquement

set-option global indentwidth 4
set-option global tabstop     4
set-option global scrolloff   3,3

set-option global ui_options ncurses_assistant=dilbert

set-option global modelinefmt '%val{bufname} %val{cursor_line}:%val{cursor_char_column} {{context_info}} {{mode_info}}'

# Les deux configs laissaient toolsclient / jumpclient vides : kakoune-filetree
# et consorts restent alors dans la fenêtre courante au lieu d'aller chercher
# un client tmux inexistant. On garde ce comportement, explicitement.
set-option global toolsclient ''
set-option global jumpclient  ''

# --- Markdown : wikilinks et tags --------------------------------------------
# Ni [[lien]] ni #tag n'appartiennent au Markdown standard : le markdown.kak
# livré avec Kakoune n'a donc aucune règle pour eux, et ils s'affichent en
# couleur de texte ordinaire. Dans un Zettelkasten c'est fâcheux, puisque ce
# sont précisément eux qui portent la structure de la note.
#
# Les deux highlighters sont ajoutés après celui du filetype, donc ils
# repeignent par-dessus. C'est ce qui sort le #tag de la règle ^#\N* de
# markdown.kak, qui prend pour un titre toute ligne commençant par un dièse —
# une ligne de tags se retrouvait colorée comme un en-tête.
#
# La parenthèse arrière écarte ## et les dièses collés à un mot (C#) ; un titre
# « # Texte » n'est pas touché non plus, l'espace ne pouvant pas ouvrir un tag.
hook -group markdown-zettel global WinSetOption filetype=markdown %{
    add-highlighter window/wikilink regex \[\[[^\]\n]+\]\] 0:link
    add-highlighter window/mdtag    regex (?<![\w#])#[\w-]+ 0:keyword
    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/wikilink
        remove-highlighter window/mdtag
    }
}
