# GL.iNet Mudi V2 minimal tailscaled profile

This profile targets a small router-client setup where you only need:

- access to the GL.iNet web admin panel over tailnet
- regular SSH to the router over tailnet

It intentionally omits Tailscale SSH and other optional features by default.

## Build

Use the helper script:

```sh
cd /home/runner/work/tailscale/tailscale
scripts/build_gli_mudi_v2_minimal.sh --goos linux --goarch arm64 --out /tmp/tailscaled-mudi
```

The base output is equivalent to `build_dist.sh --extra-small ./cmd/tailscaled`, with explicit feature selection so optional features can be added back when needed.

Optional toggles:

- `--with-cli`: include embedded `tailscale` CLI in the `tailscaled` binary
- `--with-dns`: include DNS/MagicDNS support
- `--with-subnet-routes`: include subnet-route advertisement support

Examples:

```sh
# Smallest profile for direct tailnet-IP access
scripts/build_gli_mudi_v2_minimal.sh --goos linux --goarch arm64 --out /tmp/tailscaled-mudi

# Add MagicDNS if hostname-based access is required
scripts/build_gli_mudi_v2_minimal.sh --with-dns --goos linux --goarch arm64 --out /tmp/tailscaled-mudi

# Add subnet route advertisement if web panel is only reachable on LAN IP
scripts/build_gli_mudi_v2_minimal.sh --with-subnet-routes --goos linux --goarch arm64 --out /tmp/tailscaled-mudi
```

## Runtime checks

After deployment and login, verify only the required paths:

1. Reach web panel over tailnet:
   - via tailnet IP: `http://100.x.y.z/`
   - or via MagicDNS name (if `--with-dns` was included)
2. SSH to router over tailnet:
   - `ssh root@100.x.y.z`
   - or `ssh root@<machine-name>.tailnet-name.ts.net` (if `--with-dns`)

If panel access works only by LAN IP, advertise the LAN subnet from this node and approve the route in the admin console.

## OpenWrt / GL.iNet firewall reminder

Allow inbound from `tailscale0` to the web UI and SSH ports used on the router (typically 80/443 and 22).
