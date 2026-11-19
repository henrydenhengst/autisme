
#!/usr/bin/env bash
#
# FreeBoot Rustig Signaal v3
#
# Rustige, consistente kleuren voor Omarchy / Arch Linux.
#
# Gebruik:
#   bash freeboot-rustig-signaal.sh --check
#   bash freeboot-rustig-signaal.sh
#   bash freeboot-rustig-signaal.sh --yes
#   bash freeboot-rustig-signaal.sh --restore
#   bash freeboot-rustig-signaal.sh --restore /pad/naar/backup
#
# Eigenschappen:
#   - Maakt een back-up voordat bestanden worden gewijzigd.
#   - Hersteloptie.
#   - Geen systeemupgrade.
#   - Geen automatische pakketinstallatie.
#   - Geen reboot.
#   - Bestaande shellconfiguraties blijven behouden.
#   - Geen dubbele Starship-initialisatie.
#
# Vereist:
#   Omarchy, Bash, Python 3.11+, tar
#
# ============================================================

set -Eeuo pipefail
umask 077

# ============================================================
# INSTELLINGEN
# ============================================================

readonly SCRIPT_NAME="FreeBoot Rustig Signaal"
readonly THEME_NAME="freeboot-rustig-signaal"

readonly THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
readonly EZA_DIR="$HOME/.config/eza"
readonly EZA_THEME="$EZA_DIR/theme.yml"
readonly KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"

readonly BACKUP_ROOT="$HOME/.local/share/freeboot/backups"

readonly CURRENT_THEME_NAME="$HOME/.local/state/omarchy/current/theme.name"

readonly MARKER_BEGIN="# >>> FREEBOOT RUSTIG SIGNAAL >>>"
readonly MARKER_END="# <<< FREEBOOT RUSTIG SIGNAAL <<<"

MODE="install"
YES=0
RESTORE_DIR=""

# ============================================================
# KLEURENPALET
# ============================================================

readonly BG="#24262b"
readonly FG="#cfd2d6"

readonly RED="#e8707c"
readonly ORANGE="#e0a050"
readonly GREEN="#76c9a0"
readonly BLUE="#7aa2d4"
readonly MUTED="#8a909a"

readonly SELECTION="#3a3f4b"
readonly BRIGHT_FG="#e6e8eb"

readonly DARKER_BG="#1a1c20"
readonly DARK_BG="#1e2025"

readonly PURPLE="#c9a0dc"
readonly YELLOW="#e0c080"

# ============================================================
# PAKKETLIJST
# ============================================================

PACKAGES=(
  bash zsh fish starship tmux screen less man-db man-pages parallel
  eza bat ripgrep fd fzf zoxide tree ncdu dust duf
  git git-delta lazygit tig github-cli
  neovim helix
  jq yq
  curl wget httpie rsync openssh aria2 rclone
  btop htop procs bottom fastfetch sysstat lsof strace
  ranger nnn yazi mc
  entr watchexec hyperfine tokei
  bind whois nmap tcpdump ethtool iperf3 mtr traceroute
  smartmontools nvme-cli parted gptfdisk dosfstools
  e2fsprogs xfsprogs btrfs-progs lvm2 cryptsetup
  shellcheck shfmt ansible python python-pip go rustup
  nodejs npm cmake make gcc pkgconf
  ffmpeg imagemagick pandoc dos2unix unzip zip
  7zip zstd lz4 pigz sqlite
  inetutils iproute2 iputils openbsd-netcat socat
  tealdeer
)

# ============================================================
# BEHEERDE BESTANDEN
# ============================================================

MANAGED_PATHS=(
  ".config/omarchy/themes/$THEME_NAME"
  ".config/eza/theme.yml"
  ".config/kitty/kitty.conf"
  ".config/fish/conf.d/freeboot-rustig-signaal.fish"
  ".bashrc"
  ".zshrc"
)

# ============================================================
# HULPFUNCTIES
# ============================================================

info() {
  printf '\n[INFO] %s\n' "$*"
}

ok() {
  printf '[ OK ] %s\n' "$*"
}

warn() {
  printf '[WAARSCHUWING] %s\n' "$*" >&2
}

error() {
  printf '[FOUT] %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

confirm() {
  (( YES == 1 )) && return 0

  printf '\n%s\n' "$1"
  read -r -p "Doorgaan? [j/N] " answer

  [[ "$answer" =~ ^[jJyY]$ ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================
# HELP
# ============================================================

show_help() {
  cat <<EOF

$SCRIPT_NAME

Gebruik:
  bash freeboot-rustig-signaal.sh [optie]

Opties:
  --check             Alleen controleren.
  --yes               Geen bevestigingsvraag stellen.
  --restore           Laatste back-up herstellen.
  --restore PAD       Specifieke back-up herstellen.
  --help              Deze uitleg tonen.

Het script:
  - Maakt een back-up.
  - Maakt het Omarchy-thema.
  - Configureert eza.
  - Configureert Kitty.
  - Voegt instellingen toe aan Bash en Zsh.
  - Maakt een Fish-configuratiebestand.
  - Controleert ontbrekende pakketten.

Het script:
  - Voert geen systeemupgrade uit.
  - Installeert geen pakketten.
  - Verwijdert geen pakketten.
  - Herstart de computer niet.

EOF
}

# ============================================================
# ARGUMENTEN
# ============================================================

while (($#)); do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --yes)
      YES=1
      shift
      ;;
    --restore)
      MODE="restore"
      shift

      if (($#)) && [[ "$1" != --* ]]; then
        RESTORE_DIR="$1"
        shift
      fi
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      die "Onbekende optie: $1"
      ;;
  esac
done

# ============================================================
# BASISCONTROLES
# ============================================================

check_requirements() {
  info "Systeemcontroles"

  [[ "$EUID" -ne 0 ]] ||
    die "Voer dit script niet uit als root."

  [[ -n "${HOME:-}" && -d "$HOME" ]] ||
    die "HOME is niet beschikbaar."

  [[ "$(uname -s)" == "Linux" ]] ||
    die "Dit script is uitsluitend bedoeld voor Linux."

  command_exists pacman ||
    die "Dit systeem lijkt geen Arch Linux te gebruiken."

  command_exists python3 ||
    die "Python 3 ontbreekt."

  command_exists tar ||
    die "tar ontbreekt."

  command_exists find ||
    die "find ontbreekt."

  command_exists realpath ||
    die "realpath ontbreekt."

  python3 - <<'PY'
import sys

if sys.version_info < (3, 11):
    raise SystemExit("Python 3.11 of hoger is vereist.")

import tomllib
PY

  ok "Linux gecontroleerd"
  ok "Pacman beschikbaar"
  ok "Python 3.11+ beschikbaar"
  ok "TOML-validatie beschikbaar"

  if command_exists omarchy-theme-set; then
    ok "Omarchy-themafunctie beschikbaar"
  elif command_exists omarchy; then
    ok "Omarchy CLI beschikbaar"
  else
    die "Omarchy-themafunctie niet gevonden."
  fi

  if [[ -f "$CURRENT_THEME_NAME" ]]; then
    printf 'Actief thema: %s\n' \
      "$(cat "$CURRENT_THEME_NAME")"
  else
    warn "Actieve themanaam niet gevonden."
  fi
}

# ============================================================
# PADCONTROLES
# ============================================================

check_managed_paths() {
  info "Controle bestaande configuratiebestanden"

  local rel
  local path

  for rel in "${MANAGED_PATHS[@]}"; do
    path="$HOME/$rel"

    if [[ -L "$path" ]]; then
      die "Symlink aangetroffen: $path. Handmatige controle vereist."
    fi

    if [[ -e "$path" && ! -f "$path" && ! -d "$path" ]]; then
      die "Onverwacht bestandstype: $path"
    fi
  done

  ok "Geen conflicterende symlinks gevonden"
}

# ============================================================
# PACMAN-CONTROLE
# ============================================================

check_packages() {
  info "Pakketcontrole"

  local installed=0
  local missing=0
  local package

  for package in "${PACKAGES[@]}"; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      ((installed += 1))
    else
      ((missing += 1))
    fi
  done

  printf '\n'
  printf 'Pakketten in lijst : %s\n' "${#PACKAGES[@]}"
  printf 'Geïnstalleerd     : %s\n' "$installed"
  printf 'Ontbrekend        : %s\n' "$missing"

  if (( missing > 0 )); then
    printf '\nOntbrekende pakketten:\n'

    for package in "${PACKAGES[@]}"; do
      if ! pacman -Q "$package" >/dev/null 2>&1; then
        printf '  - %s\n' "$package"
      fi
    done
  fi

  warn "Er worden geen pakketten geïnstalleerd."
  warn "Arch Linux vereist een volledige systeemupgrade voor veilige pakketupdates."
}

# ============================================================
# THEMA-INHOUD CONTROLEREN
# ============================================================

check_theme_directory() {
  if [[ -d "$THEME_DIR" ]]; then
    local extra

    extra="$(
      find "$THEME_DIR" \
        -mindepth 1 \
        ! -name colors.toml \
        -print \
        -quit
    )"

    if [[ -n "$extra" ]]; then
      die "Bestaande themamap bevat extra bestanden: $extra
Maak eerst handmatig een back-up en controleer deze bestanden."
    fi
  fi
}

# ============================================================
# CHECK-MODUS
# ============================================================

if [[ "$MODE" == "check" ]]; then
  check_requirements
  check_managed_paths
  check_theme_directory
  check_packages

  info "Controle afgerond."
  exit 0
fi

# ============================================================
# THEMA ACTIVEREN
# ============================================================

activate_theme() {
  local name="$1"

  info "Thema activeren: $name"

  if command_exists omarchy-theme-set; then
    OMARCHY_THEME_WAIT=1 omarchy-theme-set "$name"
  elif command_exists omarchy; then
    OMARCHY_THEME_WAIT=1 omarchy theme set "$name"
  else
    die "Geen ondersteunde Omarchy-themafunctie gevonden."
  fi
}

# ============================================================
# BACK-UP MAKEN
# ============================================================

create_backup() {
  info "Back-up maken"

  mkdir -p "$BACKUP_ROOT"

  local timestamp
  timestamp="$(date '+%Y%m%d-%H%M%S')"

  BACKUP_DIR="$BACKUP_ROOT/$timestamp"

  [[ ! -e "$BACKUP_DIR" ]] ||
    die "Back-upmap bestaat al: $BACKUP_DIR"

  mkdir -p "$BACKUP_DIR"

  local existing=()
  local rel

  for rel in "${MANAGED_PATHS[@]}"; do
    if [[ -e "$HOME/$rel" ]]; then
      existing+=("$rel")
    fi
  done

  if ((${#existing[@]})); then
    tar -cpf "$BACKUP_DIR/files.tar" \
      -C "$HOME" \
      -- "${existing[@]}"
  else
    tar -cpf "$BACKUP_DIR/files.tar" \
      --files-from /dev/null
  fi

  if [[ -f "$CURRENT_THEME_NAME" ]]; then
    cat "$CURRENT_THEME_NAME" > "$BACKUP_DIR/previous-theme.txt"
  else
    : > "$BACKUP_DIR/previous-theme.txt"
  fi

  printf '%s\n' "${MANAGED_PATHS[@]}" \
    > "$BACKUP_DIR/managed-paths.txt"

  printf '%s\n' "${existing[@]}" \
    > "$BACKUP_DIR/existing-paths.txt"

  ok "Back-up gemaakt:"
  printf '%s\n' "$BACKUP_DIR"
}

# ============================================================
# ATOMISCH BESTAND SCHRIJVEN
# ============================================================

write_atomic() {
  local target="$1"
  local mode="${2:-0644}"

  local parent
  parent="$(dirname "$target")"

  mkdir -p "$parent"

  local temp
  temp="$(mktemp "$parent/.freeboot.XXXXXX")"

  cat > "$temp"

  chmod "$mode" "$temp"

  mv -f -- "$temp" "$target"
}

# ============================================================
# CENTRALE OMARCHY-KLEUREN
# ============================================================

write_colors() {
  info "Omarchy-kleurenbestand maken"

  mkdir -p "$THEME_DIR"

  write_atomic "$THEME_DIR/colors.toml" 0644 <<EOF
mode = "dark"

# FreeBoot Rustig Signaal

accent = "$BLUE"
selection = "$SELECTION"
muted = "$MUTED"

background = "$BG"
dark_background = "$DARK_BG"
darker_background = "$DARKER_BG"
lighter_background = "$SELECTION"

foreground = "$FG"
dark_foreground = "$MUTED"
light_foreground = "$BRIGHT_FG"
bright_foreground = "$BRIGHT_FG"

red = "$RED"
orange = "$ORANGE"
yellow = "$YELLOW"
green = "$GREEN"
blue = "$BLUE"
purple = "$PURPLE"

# ANSI-kleuren

color0 = "$DARKER_BG"
color1 = "$RED"
color2 = "$GREEN"
color3 = "$ORANGE"
color4 = "$BLUE"
color5 = "$PURPLE"
color6 = "$BLUE"
color7 = "$FG"

color8 = "$MUTED"
color9 = "$RED"
color10 = "$GREEN"
color11 = "$YELLOW"
color12 = "$BLUE"
color13 = "$PURPLE"
color14 = "$BLUE"
color15 = "$BRIGHT_FG"
EOF

  python3 - "$THEME_DIR/colors.toml" <<'PY'
import re
import sys
import tomllib

path = sys.argv[1]

with open(path, "rb") as f:
    data = tomllib.load(f)

required = [
    "mode",
    "accent",
    "selection",
    "muted",
    "background",
    "dark_background",
    "darker_background",
    "lighter_background",
    "foreground",
    "dark_foreground",
    "light_foreground",
    "bright_foreground",
    "red",
    "blue",
]

for key in required:
    if key not in data:
        raise SystemExit(f"Ontbrekende TOML-sleutel: {key}")

for key, value in data.items():
    if key == "mode":
        continue

    if not isinstance(value, str):
        raise SystemExit(f"Ongeldige kleurwaarde: {key}")

    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise SystemExit(f"Ongeldige hexkleur: {key} = {value}")

print("TOML en kleurwaarden zijn geldig.")
PY

  ok "colors.toml aangemaakt en gevalideerd"
}

# ============================================================
# EZA THEMA
# ============================================================

write_eza_theme() {
  info "eza-thema maken"

  mkdir -p "$EZA_DIR"

  write_atomic "$EZA_THEME" 0644 <<EOF
colourful: true

filekinds:
  directory:
    foreground: "$BLUE"
    is_bold: true

  symlink:
    foreground: "$BLUE"

git:
  new:
    foreground: "$GREEN"

  modified:
    foreground: "$ORANGE"

  deleted:
    foreground: "$RED"

  renamed:
    foreground: "$PURPLE"

  conflicted:
    foreground: "$RED"
    is_bold: true
EOF

  ok "eza theme.yml aangemaakt"
}

# ============================================================
# KITTY
# ============================================================

write_kitty_settings() {
  info "Kitty-instellingen voorbereiden"

  local snippet
  snippet="$(mktemp)"

  cat > "$snippet" <<'EOF'
# Rustige cursor en geen geluid
cursor_blink_interval 0
cursor_trail 0
enable_audio_bell no
visual_bell_duration 0.0

# Rustige vensterweergave
window_padding_width 8
background_opacity 1.0
dim_opacity 0.7
inactive_text_alpha 1.0
EOF

  update_managed_block "$KITTY_CONFIG" "$snippet"

  rm -f "$snippet"

  ok "Kitty-instellingen toegevoegd"
}

# ============================================================
# SHELLCONFIGURATIE
# ============================================================

update_managed_block() {
  local target="$1"
  local snippet="$2"

  python3 - "$target" "$snippet" "$MARKER_BEGIN" "$MARKER_END" <<'PY'
import os
import pathlib
import re
import sys
import tempfile

target = pathlib.Path(sys.argv[1])
snippet = pathlib.Path(sys.argv[2])
begin = sys.argv[3]
end = sys.argv[4]

old = target.read_text() if target.exists() else ""

lines = old.splitlines()

start_positions = [
    i for i, line in enumerate(lines)
    if line == begin
]

end_positions = [
    i for i, line in enumerate(lines)
    if line == end
]

if len(start_positions) != len(end_positions):
    raise SystemExit(f"Ongeldige FreeBoot-markeringen in {target}")

if len(start_positions) > 1:
    raise SystemExit(f"Dubbele FreeBoot-blokken in {target}")

if start_positions:
    start = start_positions[0]
    finish = end_positions[0]

    if finish < start:
        raise SystemExit(f"Ongeldige blokvolgorde in {target}")

    lines = lines[:start] + lines[finish + 1:]

content = "\n".join(lines).rstrip()

block = snippet.read_text().rstrip()

if content:
    content += "\n\n"

content += begin + "\n"
content += block + "\n"
content += end + "\n"

target.parent.mkdir(parents=True, exist_ok=True)

mode = target.stat().st_mode & 0o777 if target.exists() else 0o644

fd, temp_name = tempfile.mkstemp(
    prefix=".freeboot-",
    dir=target.parent
)

try:
    with os.fdopen(fd, "w") as f:
        f.write(content)

    os.chmod(temp_name, mode)
    os.replace(temp_name, target)

except Exception:
    try:
        os.unlink(temp_name)
    except FileNotFoundError:
        pass
    raise
PY
}

write_shell_settings() {
  info "Bash- en Zsh-instellingen toevoegen"

  local snippet
  snippet="$(mktemp)"

  cat > "$snippet" <<'EOF'
# Rustige FreeBoot-instellingen

export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"

# eza gebruikt theme.yml; omgevingskleuren hebben voorrang.
unset EZA_COLORS
unset LS_COLORS

# Minder visuele ruis in fzf.
export FZF_DEFAULT_OPTS='--color=bg:#24262b,fg:#cfd2d6,hl:#e0a050,fg+:#e6e8eb,bg+:#3a3f4b,hl+:#e0a050,info:#8a909a,prompt:#7aa2d4,pointer:#76c9a0,marker:#76c9a0,header:#7aa2d4'

# Kleurondersteuning voor less.
export LESS="${LESS:--R}"
EOF

  update_managed_block "$HOME/.bashrc" "$snippet"
  update_managed_block "$HOME/.zshrc" "$snippet"

  rm -f "$snippet"

  ok "Bash- en Zsh-instellingen toegevoegd"
}

# ============================================================
# FISH
# ============================================================

write_fish_settings() {
  info "Fish-instellingen maken"

  local target="$HOME/.config/fish/conf.d/freeboot-rustig-signaal.fish"

  write_atomic "$target" 0644 <<'EOF'
# FreeBoot Rustig Signaal

set -gx EZA_CONFIG_DIR "$HOME/.config/eza"

set -e EZA_COLORS
set -e LS_COLORS

set -gx FZF_DEFAULT_OPTS '--color=bg:#24262b,fg:#cfd2d6,hl:#e0a050,fg+:#e6e8eb,bg+:#3a3f4b,hl+:#e0a050,info:#8a909a,prompt:#7aa2d4,pointer:#76c9a0,marker:#76c9a0,header:#7aa2d4'

set -gx LESS '-R'
EOF

  ok "Fish-configuratie aangemaakt"
}

# ============================================================
# THEMA ACTIVEREN EN CONTROLEREN
# ============================================================

verify_theme() {
  info "Omarchy-thema activeren"

  activate_theme "$THEME_NAME"

  if [[ ! -f "$CURRENT_THEME_NAME" ]]; then
    die "Omarchy heeft geen actieve themanaam geschreven.
Back-up staat in: $BACKUP_DIR"
  fi

  local active
  active="$(cat "$CURRENT_THEME_NAME")"

  if [[ "$active" != "$THEME_NAME" ]]; then
    die "Actief thema wijkt af: $active
Back-up staat in: $BACKUP_DIR"
  fi

  ok "Omarchy-thema is actief"
}

# ============================================================
# HERSTELFUNCTIE
# ============================================================

restore_backup() {
  info "Herstelmodus"

  if [[ -z "$RESTORE_DIR" ]]; then
    [[ -d "$BACKUP_ROOT" ]] ||
      die "Geen back-upmap gevonden."

    RESTORE_DIR="$(
      find "$BACKUP_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name '20*' |
      sort |
      tail -n 1
    )"
  fi

  [[ -n "$RESTORE_DIR" && -d "$RESTORE_DIR" ]] ||
    die "Back-upmap niet gevonden."

  [[ -f "$RESTORE_DIR/files.tar" ]] ||
    die "Back-uparchief ontbreekt."

  [[ -f "$RESTORE_DIR/managed-paths.txt" ]] ||
    die "Back-upmanifest ontbreekt."

  [[ -f "$RESTORE_DIR/existing-paths.txt" ]] ||
    die "Bestandsmanifest ontbreekt."

  local archive="$RESTORE_DIR/files.tar"

  # Controleer dat het archief uitsluitend beheerde paden bevat.
  python3 - "$archive" "$RESTORE_DIR/managed-paths.txt" <<'PY'
import pathlib
import subprocess
import sys

archive = sys.argv[1]
manifest = pathlib.Path(sys.argv[2])

allowed = set(manifest.read_text().splitlines())

entries = subprocess.check_output(
    ["tar", "-tf", archive],
    text=True
).splitlines()

for entry in entries:
    path = pathlib.PurePosixPath(entry)

    if path.is_absolute() or ".." in path.parts:
        raise SystemExit(f"Onveilig archiefpad: {entry}")

    if not any(
        entry == item or entry.startswith(item.rstrip("/") + "/")
        for item in allowed
    ):
        raise SystemExit(f"Onverwacht archiefpad: {entry}")

print("Back-uparchief gecontroleerd.")
PY

  confirm "De huidige beheerde configuratie wordt vervangen door de back-up." ||
    die "Herstel geannuleerd."

  check_managed_paths

  local rel

  for rel in "${MANAGED_PATHS[@]}"; do
    rm -rf -- "$HOME/$rel"
  done

  tar -xpf "$archive" -C "$HOME"

  ok "Bestanden uit back-up hersteld"

  local previous_theme=""

  if [[ -f "$RESTORE_DIR/previous-theme.txt" ]]; then
    previous_theme="$(cat "$RESTORE_DIR/previous-theme.txt")"
  fi

  if [[ -n "$previous_theme" ]]; then
    info "Vorige Omarchy-thema opnieuw activeren"
    activate_theme "$previous_theme"
    ok "Vorige themakeuze hersteld"
  else
    warn "Er was geen vorige themanaam opgeslagen."
  fi

  printf '\nHerstel afgerond.\n'
  exit 0
}

# ============================================================
# UITVOERING
# ============================================================

check_requirements
check_managed_paths

if [[ "$MODE" == "restore" ]]; then
  restore_backup
fi

check_theme_directory

check_packages

printf '\n'
printf '%s\n' "Installatieoverzicht"
printf '%s\n' "--------------------"
printf 'Thema             : %s\n' "$THEME_NAME"
printf 'Themamap          : %s\n' "$THEME_DIR"
printf 'eza-configuratie  : %s\n' "$EZA_THEME"
printf 'Kitty-configuratie: %s\n' "$KITTY_CONFIG"
printf 'Back-upmap        : %s\n' "$BACKUP_ROOT"

confirm "De configuratiebestanden worden aangepast en het thema wordt geactiveerd." ||
  die "Installatie geannuleerd."

# ============================================================
# BACK-UP
# ============================================================

create_backup

# ============================================================
# CONFIGURATIE
# ============================================================

write_colors
write_eza_theme
write_kitty_settings
write_shell_settings
write_fish_settings

# ============================================================
# THEMA ACTIVEREN
# ============================================================

verify_theme

# ============================================================
# EINDRAPPORT
# ============================================================

printf '\n'
printf '%s\n' "========================================"
printf '%s\n' " FREEBOOT RUSTIG SIGNAAL"
printf '%s\n' "========================================"

ok "Omarchy-thema aangemaakt"
ok "Kleurenbestand gevalideerd"
ok "eza-thema aangemaakt"
ok "Kitty-instellingen toegevoegd"
ok "Bash-instellingen toegevoegd"
ok "Zsh-instellingen toegevoegd"
ok "Fish-instellingen aangemaakt"
ok "Back-up beschikbaar"

printf '\n'
printf 'Thema       : %s\n' "$THEME_NAME"
printf 'Back-up     : %s\n' "$BACKUP_DIR"
printf 'Pakketlijst : %s pakketten gecontroleerd\n' "${#PACKAGES[@]}"

printf '\n'
printf '%s\n' "Er is geen systeemupgrade uitgevoerd."
printf '%s\n' "Er zijn geen pakketten geïnstalleerd."
printf '%s\n' "Er is geen reboot uitgevoerd."

printf '\n'
printf '%s\n' "Open een nieuwe terminal om de shellinstellingen te laden."

printf '\n'
printf '%s\n' "Herstellen kan met:"
printf 'bash %q --restore %q\n' "$0" "$BACKUP_DIR"

printf '\n'
printf '%s\n' "Installatie afgerond."
