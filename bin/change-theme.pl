#!/usr/bin/env perl
# Sélecteur de thème Kakoune, portable macOS / Linux.
#
# L'ancienne version codait en dur /opt/homebrew/share/kak/colors (Mac) ou
# /home/linuxbrew/.linuxbrew/share/kak/colors (ThinkPad), et le shebang lui-même
# pointait vers un chemin Homebrew. Ici, le préfixe est déduit du binaire `kak`.

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $config_dir = ($ENV{XDG_CONFIG_HOME} || "$ENV{HOME}/.config") . "/kak";
my $config     = "$config_dir/kakrc";

# --- Répertoire de thèmes livré avec Kakoune ---------------------------------
sub system_colors_dir {
    my $bin = `command -v kak 2>/dev/null`;
    chomp $bin;
    return unless $bin;
    my $real   = abs_path($bin) or return;
    my $prefix = dirname(dirname($real));      # <prefix>/bin/kak → <prefix>
    my $dir    = "$prefix/share/kak/colors";
    return -d $dir ? $dir : undef;
}

my @all_themes;
push @all_themes, split "\n", `ls "$config_dir/colors" 2>/dev/null`;
if (my $sys = system_colors_dir()) {
    push @all_themes, split "\n", `ls "$sys" 2>/dev/null`;
}

unless (@all_themes) {
    die "Aucun thème trouvé (ni dans $config_dir/colors, ni dans l'installation Kakoune)\n";
}

# --- Choix du thème ----------------------------------------------------------
my $theme;

if (@ARGV) {
    ($theme) = grep { /\Q$ARGV[0]\E/ } @all_themes;
    if ($theme) {
        print "thème « $theme » sélectionné\n";
    } else {
        print "aucun thème ne correspond à « $ARGV[0] »\n";
    }
}

unless ($theme) {
    my $joined = join "\n", @all_themes;
    $theme = `printf '%s' "$joined" | fzf`;
    chomp $theme;
}

unless ($theme) {
    print "aucun thème sélectionné\n";
    exit 0;
}

$theme =~ s/\.kak$//;

# --- Réécriture de la ligne colorscheme --------------------------------------
# Le colorscheme vit désormais dans config/40-plugins.kak (bloc catppuccin),
# mais on accepte aussi une ligne dans kakrc ou dans local.kak.
my @candidates = (
    "$config_dir/local.kak",
    "$config_dir/config/40-plugins.kak",
    $config,
);

my ($target) = grep { -f $_ && `grep -c '^\\s*colorscheme' "$_"` > 0 } @candidates;

unless ($target) {
    # rien à réécrire : on écrit une surcharge locale, non versionnée
    $target = "$config_dir/local.kak";
    open my $fh, '>>', $target or die "impossible d'écrire $target : $!\n";
    print $fh "colorscheme $theme\n";
    close $fh;
    print "colorscheme $theme ajouté à $target\n";
    exit 0;
}

open my $in, '<', $target or die "impossible d'ouvrir $target : $!\n";
my $content = '';
while (<$in>) {
    if (/^(\s*)colorscheme\s/) {
        $content .= "$1colorscheme $theme\n";
        next;
    }
    $content .= $_;
}
close $in;

open my $out, '>', $target or die "impossible d'écrire $target : $!\n";
print $out $content;
close $out;

print "colorscheme $theme écrit dans $target\n";
