#!/bin/sh
# Copyright © 2026 Gornskew Enterprises
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.  Distributed WITHOUT
# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

# An IPv6-only hull borrows an IPv4 door.  Cheap rented hulls come with
# no public IPv4; this gives one an IPv4 default route through a
# WireGuard hub (a dual-stack ship in the fleet, sally for Gornskew) so
# that the IPv4-only corners of the world -- quicklisp.org, github.com
# -- stay reachable.  Everything that speaks IPv6 keeps going direct.
#
# Run ONCE, as root, on the hull:
#
#     basilisk/hull/wg-spoke.sh <n> <hub-endpoint> <hub-public-key>
#
#   n               this hull's host number on the tunnel (the hub's
#                   add-spoke tells you; 2..254)
#   hub-endpoint    [<hub IPv6>]:51820
#   hub-public-key  the hub's WireGuard public key
#
# The first run prints this hull's public key: hand it to the hub's
# keeper (sally-stack/wg/add-spoke.sh <name> <that key>).  Order does
# not matter -- the tunnel handshakes once both sides know each other.
# Idempotent: keeps an existing private key (/etc/wireguard/privatekey),
# rewrites the interface, restarts it.  Nothing here touches DNS: a v6
# hull keeps its provider's IPv6 resolvers.

set -eu
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }
[ $# -eq 3 ] || { echo "usage: $0 <n> <hub-endpoint> <hub-public-key>" >&2; exit 1; }

n="$1"; endpoint="$2"; hubpub="$3"
WG=/etc/wireguard
NET4=10.64.64
NET6=fd00:64:64:64
[ "$n" -ge 2 ] && [ "$n" -le 254 ] || { echo "n out of range: $n" >&2; exit 1; }

command -v wg >/dev/null 2>&1 || {
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wireguard-tools
}

umask 077
mkdir -p "$WG"
[ -f "$WG/privatekey" ] || wg genkey > "$WG/privatekey"
wg pubkey < "$WG/privatekey" > "$WG/publickey"
[ -f "$WG/wg0.conf" ] && cp "$WG/wg0.conf" "$WG/wg0.conf.before-$(date -u +%Y%m%d%H%M%S)"

cat > "$WG/wg0.conf" <<EOF
# This hull's IPv4 door: a WireGuard spoke to the fleet's hub.
# Written by basilisk/hull/wg-spoke.sh $(date -u +%Y-%m-%d).
[Interface]
Address = $NET4.$n/24, $NET6::$n/64
PrivateKey = $(cat "$WG/privatekey")
# AllowedIPs 0.0.0.0/0 below makes wg-quick route all IPv4 through the
# tunnel (policy routing by fwmark); IPv6 stays direct.

[Peer]
PublicKey = $hubpub
Endpoint = $endpoint
AllowedIPs = 0.0.0.0/0, $NET6::/64
PersistentKeepalive = 25
EOF

systemctl enable -q wg-quick@wg0
systemctl restart wg-quick@wg0
sleep 2
echo "this hull's public key (give it to the hub's keeper):"
cat "$WG/publickey"
echo
wg show wg0 | grep -E "endpoint|handshake|transfer" || true
# wg-quick keeps the tunnel's default route in its own policy table
echo "IPv4 route: $(ip -4 route show table all | grep '^default' | head -1)"
if curl -4 -s -m 8 -o /dev/null -w '%{http_code}' https://beta.quicklisp.org/ 2>/dev/null | grep -q '^[23]'; then
    echo "IPv4 reaches the world through the hub."
else
    echo "no IPv4 yet -- the hub must add this key (sally-stack/wg/add-spoke.sh), then wait a keepalive."
fi
