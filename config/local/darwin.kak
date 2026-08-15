# Surcharges macOS
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
# Chargé uniquement quand `uname` renvoie Darwin.
# Tout ce qui est réellement portable doit rester dans config/*.kak ;
# ce fichier ne sert qu'aux irréductibles différences du Mac.

# Homebrew installe les outils GNU en préfixe « g » (gsed, gawk…) et les
# versions BSD de sed/awk diffèrent. Si un plugin s'en plaint, préférer
# `brew install gnu-sed` puis surcharger ici.

# Rien de spécifique pour l'instant : la détection dynamique du presse-papier
# et du préfixe Kakoune couvre déjà les anciens chemins /opt/homebrew codés en dur.
