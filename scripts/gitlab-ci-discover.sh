#!/bin/sh

DYNAMIC_CI_FILE="dynamic-gitlab-ci.yml"
DYNAMIC_STAGE="build"
ENABLED_LIST=".ci-enabled"
DISABLED_LIST=".ci-disabled"


die () {
	echo "$1" >/dev/stderr
	exit 1
}


# read packages
pkgs="$(nix flake show --json 2> /dev/null | jq '.packages."x86_64-linux" | to_entries[] | .key' | sed 's/"\(.*\)"/\1/')" \
	|| die "Unable to read flake outputs"


# write header
cat <<EOF > "$DYNAMIC_CI_FILE"
image: nixos/nix

stages:
- build

variables:
     GIT_SUBMODULE_STRATEGY: recursive

before_script:
- mkdir -vp ~/.config/nix
- echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
EOF


for package in $pkgs; do
	if [ -f "$ENABLED_LIST" ] && ! grep -x "$package" "$ENABLED_LIST" >/dev/null; then
		echo "Ignoring '$package' (not enabled in $ENABLED_LIST)"
		continue;
	fi
	if [ -f "$DISABLED_LIST" ] && grep -x "$package" "$DISABLED_LIST" >/dev/null; then
		echo "Ignoring '$package' (disabled in $DISABLED_LIST)"
		continue;
	fi

	echo "Adding job for package '$package'"

	cat << EOF >> "$DYNAMIC_CI_FILE"

$DYNAMIC_STAGE:$package:
  stage: $DYNAMIC_STAGE
  script:
    - nix build .?submodules=1#$package
    - cp -rL result result-$package
  artifacts:
    paths:
      - result-$package
EOF
done
