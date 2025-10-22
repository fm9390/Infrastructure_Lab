#!/usr/bin/env bash
set -euo pipefail

# ====== einfache konfiguration ======
HOSTNAME="testvpn2"                       # wie die VM heißen soll
ROUTE_CIDR="${1:-192.168.178.0/24}"          # LAN-CIDR; 1. Argument überschreibt den Default
TS_AUTHKEY="tskey-auth-k1wzLAeTDv11CNTRL-GAxzVxHaMrS9CVFQ3ecxqSFogh33gaqS"                   # (als Umgebungsvariable übergeben, sonst interaktives Login)

# ====== 0) muss als root laufen ======
if [[ $EUID -ne 0 ]]; then
  echo "Bitte als root ausführen (z.B. 'sudo -i' oder 'sudo ./setup_vpn_vm_basic.sh')."
  exit 1
fi

# ====== 1) hostname setzen ======
hostnamectl set-hostname "$HOSTNAME"

# ====== 2) tailscale installieren (nur wenn fehlt) ======
apt-get update -y
apt-get install -y curl
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable --now tailscaled

# ====== 3) ip-forwarding aktivieren (für exit-node & subnet-routing) ======
cat >/etc/sysctl.d/99-tailscale.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-tailscale.conf

# ====== 4) tailscale verbinden (exit-node + route) ======
AUTH_OPT=""
if [[ -n "${TS_AUTHKEY:-}" ]]; then
  AUTH_OPT="--authkey=${TS_AUTHKEY}"
fi

tailscale up ${AUTH_OPT} \
  --ssh \
  --hostname="${HOSTNAME}" \
  --advertise-exit-node \
  --advertise-routes="${ROUTE_CIDR}" \
  --advertise-tags=tag:homelab \
  --reset

# ====== 5) kurzer status ======
echo "---------- Tailscale Status ----------"
tailscale status || true
echo "TS IPv4:"
tailscale ip -4 || true
echo
echo "➡️  Öffne die Tailscale Admin Console (Machines),"
echo "    Route ${ROUTE_CIDR} 'Approve' und 'Use as exit node' aktivieren."
