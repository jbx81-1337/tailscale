#!/usr/bin/env sh
#
# Build a small tailscaled binary for GL.iNet Mudi V2 style router use cases:
# web panel and regular SSH access over tailnet.
#
# Base profile is equivalent to build_dist.sh --extra-small, then optionally
# re-add only selected features.

set -eu

usage() {
	cat <<'EOF'
Usage: scripts/build_gli_mudi_v2_minimal.sh [options]

Options:
  --with-cli            Include embedded tailscale CLI (ts_include_cli)
  --with-dns            Keep DNS/MagicDNS support
  --with-subnet-routes  Keep subnet-route advertisement support
  --goos <value>        Target GOOS (default: current environment)
  --goarch <value>      Target GOARCH (default: current environment)
  --out <path>          Output binary path
  -h, --help            Show this help

Examples:
  scripts/build_gli_mudi_v2_minimal.sh --goos linux --goarch arm64 --out /tmp/tailscaled-mudi
  scripts/build_gli_mudi_v2_minimal.sh --with-cli --with-dns --goos linux --goarch arm64
EOF
}

with_cli=false
with_dns=false
with_subnet_routes=false
target_goos=
target_goarch=
out=

while [ "$#" -gt 0 ]; do
	case "$1" in
	--with-cli)
		with_cli=true
		;;
	--with-dns)
		with_dns=true
		;;
	--with-subnet-routes)
		with_subnet_routes=true
		;;
	--goos)
		shift
		target_goos="${1:-}"
		;;
	--goarch)
		shift
		target_goarch="${1:-}"
		;;
	--out)
		shift
		out="${1:-}"
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

adds="osrouter"
if [ "$with_dns" = true ]; then
	adds="$adds,dns"
fi
if [ "$with_subnet_routes" = true ]; then
	adds="$adds,advertiseroutes"
fi

go_cmd="go"
if [ -n "${TS_USE_TOOLCHAIN:-}" ]; then
	go_cmd="./tool/go"
fi

tags=$(GOOS= GOARCH= "$go_cmd" run ./cmd/featuretags --min --add="$adds")
if [ "$with_cli" = true ]; then
	tags="${tags:+$tags,}ts_include_cli"
fi

if [ -n "$target_goos" ]; then
	export GOOS="$target_goos"
fi
if [ -n "$target_goarch" ]; then
	export GOARCH="$target_goarch"
fi

if [ -n "$out" ]; then
	TAGS="$tags" ./build_dist.sh --strip -o "$out" ./cmd/tailscaled
else
	TAGS="$tags" ./build_dist.sh --strip ./cmd/tailscaled
fi
