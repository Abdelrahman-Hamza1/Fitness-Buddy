#!/usr/bin/env bash
# B03: official signed Ubuntu repository; explicit version, never curl | sh.
set -euo pipefail
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 && $(dpkg --print-architecture) == amd64 ]] || {
  echo 'setup-tailscale: expected Ubuntu 24.04 amd64' >&2; exit 1;
}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
curl --fail --silent --show-error --location --proto '=https' \
  https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg -o "$work/keyring"
curl --fail --silent --show-error --location --proto '=https' \
  https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list -o "$work/source"
sudo install -m 0644 "$work/keyring" /usr/share/keyrings/tailscale-archive-keyring.gpg
sudo install -m 0644 "$work/source" /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install -y tailscale=1.104.1
sudo systemctl enable --now tailscaled
tailscale version
printf '%s\n' 'Next: sudo tailscale up --accept-routes=false --accept-dns=false' \
  'Then: sudo tailscale set --operator="$USER" (local Serve management; never enables SSH or Funnel).'
