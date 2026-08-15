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
