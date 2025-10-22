#!/usr/bin/env bash
set -euo pipefail
LOGFILE="/var/log/setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# ====== Variablen (bei Bedarf anpassen) ======
GAME_USER="mcbserver"
BEDROCK_PORT="4356"           # Bedrock-Port (UDP)
LGSM_SCRIPT="mcbserver"       # LinuxGSM-Shortname für Minecraft Bedrock
PLAYIT_LIST="/etc/apt/sources.list.d/playit-cloud.list"
PLAYIT_KEY="/etc/apt/trusted.gpg.d/playit.gpg"

# ====== Helpers ======
log() { echo -e "\n\033[1;32m[+] $*\033[0m"; }
warn(){ echo -e "\n\033[1;33m[!] $*\033[0m"; }
need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Bitte als root ausführen (z.B. 'sudo -i')."
    exit 1
  fi
}

ensure_repo_component() {
  local comp="$1"
  if ! grep -Rq "^[^#].* ${comp} " /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    add-apt-repository -y "${comp}" || true
  fi
}

ensure_i386_arch() {
  if ! dpkg --print-foreign-architectures | grep -q '^i386$'; then
    dpkg --add-architecture i386
  fi
}

ensure_user() {
  local u="$1"
  if ! id -u "$u" &>/dev/null; then
    log "Lege Benutzer '$u' an (ohne Login-Passwort)…"
    adduser --disabled-password --gecos "" "$u"
  fi
}

as_game_user() {
  sudo -u "$GAME_USER" bash -lc "$*"
}

ensure_line_kv() {
  # ensure key=value (ersetzen oder hinzufügen) in Datei
  local file="$1" key="$2" val="$3"
  if [[ -f "$file" ]]; then
    if grep -q "^${key}=" "$file"; then
      sed -i "s|^${key}=.*|${key}=${val}|" "$file"
    else
      echo "${key}=${val}" >> "$file"
    fi
  else
    warn "Datei $file existiert noch nicht (Install noch nicht durchgelaufen?)"
  fi
}

apt_update_safe() {
  # kleines Retry (2 Versuche), weil Mirrors manchmal zicken
  for i in 1 2; do
    if apt-get update -y; then return 0; fi
    sleep 3
  done
  return 1
}


need_root

# ====== 0) System vorbereiten ======
log "Aktualisiere Paketquellen…"
apt_update_safe

log "Aktiviere 'universe' und 'multiverse' (falls nötig)…"
ensure_repo_component universe
ensure_repo_component multiverse

log "Paketquellen nach Komponenten-Änderung neu laden…"
apt_update_safe

log "Aktiviere i386-Architektur (falls nötig)…"
ensure_i386_arch

log "Paketquellen nach Architektur-Änderung neu laden…"
apt_update_safe

log "System-Upgrade… (non-interaktiv)"
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Installiere benötigte Pakete…"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl ca-certificates gnupg lsb-release software-properties-common \
  unzip bsdmainutils bzip2 jq netcat pigz \
  lib32gcc-s1 lib32stdc++6 libsdl2-2.0-0:i386

# ====== 1) Spielbenutzer & LinuxGSM ======
ensure_user "$GAME_USER"

log "LinuxGSM Bootstrap für Benutzer '$GAME_USER'…"
as_game_user 'cd ~ &&
  if [[ ! -f linuxgsm.sh ]]; then
    curl -Lo linuxgsm.sh https://linuxgsm.sh
    chmod +x linuxgsm.sh
  fi'

log "Initialisiere LinuxGSM-Game-Script (mcbserver)…"
as_game_user "cd ~ && [[ -f ${LGSM_SCRIPT} ]] || bash linuxgsm.sh ${LGSM_SCRIPT}"

log "Installiere Bedrock-Server (falls noch nicht vorhanden)…"
as_game_user "cd ~ && [[ -d serverfiles ]] || yes | ./${LGSM_SCRIPT} install"

# ====== 2) Bedrock-Port auf 4356 setzen ======
BEDROCK_CFG="/home/${GAME_USER}/serverfiles/server.properties"
log "Setze Bedrock-Port (${BEDROCK_PORT}) in ${BEDROCK_CFG}…"
ensure_line_kv "$BEDROCK_CFG" "server-port" "${BEDROCK_PORT}"
# Rechte sicherstellen (falls root geschrieben)
chown "${GAME_USER}:${GAME_USER}" "$BEDROCK_CFG" 2>/dev/null || true

# ====== 3) Playit (Repo + Install) ======
log "Binde Playit APT-Repo ein (falls noch nicht)…"
if [[ ! -f "$PLAYIT_KEY" ]]; then
  curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor > "$PLAYIT_KEY"
fi

if [[ ! -f "$PLAYIT_LIST" ]]; then
  echo "deb [signed-by=${PLAYIT_KEY}] https://playit-cloud.github.io/ppa/data ./" > "$PLAYIT_LIST"
fi

log "Paketquellen nach Playit-Repo neu laden…"
apt_update_safe

DEBIAN_FRONTEND=noninteractive apt-get install -y playit

# ====== 4) Hinweise / Next Steps ======
cat <<'EOF'

============================================================
✅ Grund-Setup abgeschlossen.

Nächste Schritte (manuell):
1) Playit-Tunnel claimen/aktivieren:
   -> In einem Terminal:  playit
      (Dem Link im Terminal folgen, Tunneltyp "Minecraft Bedrock" wählen
       und Port auf 4356 setzen.)

2) Minecraft-Server starten/prüfen:
   -> su - mcbserver
   -> ./mcbserver details
   -> ./mcbserver start      # Server starten
   -> ./mcbserver stop       # Server stoppen
   -> ./mcbserver update     # Server/Files aktualisieren

Hinweis:
- Dieses Skript ist idempotent: Du kannst es jederzeit erneut ausführen.
- Der Bedrock-Server lauscht lokal auf UDP/TCP 4356 (in server.properties).
- Externe Spieler verbinden sich über die von playit angezeigte öffentliche Adresse.
============================================================
EOF
