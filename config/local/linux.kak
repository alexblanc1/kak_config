# Surcharges Linux
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# Chargé uniquement quand `uname` renvoie Linux (le ThinkPad).

# Le presse-papier X11/Wayland est déjà géré dans config/20-clipboard.kak.
# kakboard n'est plus chargé : il faisait doublon avec le hook RegisterModified
# et ne fonctionnait que sous X11. Pour le réactiver malgré tout :
#
# plug "https://github.com/lePerdu/kakboard.git" config %{
#     hook global WinCreate .* %{ kakboard-enable }
# }
