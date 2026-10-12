#!/usr/bin/env bash
#
# Waybar visibility toggle, bound to SUPER+A in hypr/hyprland.conf.
#
# Ported from ~/coding/dotfiles/hypr/conf/statusbar.lua: that config drives
# Hyprland's Lua API (hl.get_layers(), hl.config()) directly; this one is
# plain hyprlang, so the same two effects are driven through `hyprctl`
# instead. Keep the two in sync if the behaviour changes on one side.
#
# Waybar sits on the left screen edge as an exclusive layer surface (see
# home.nix's programs.waybar.settings: position "left"), so tiled windows
# normally start `width` px in from the left border. Toggling hands that
# space back:
#
#   * SIGUSR1 is waybar's own show/hide toggle. It drops every bar into
#     waybar's "invisible" mode, which releases the exclusive zone (so
#     windows reflow onto the space the bar held) and makes the surface
#     input-transparent (so no leftover strip swallows clicks) — all
#     without restarting waybar, so its modules and their state survive.
#   * general:gaps_out's left gap is pinned to 0 while hidden, and restored
#     to the configured value while visible, so "bar hidden" still means
#     0px to the left border once those gaps are non-zero (they are 0 in
#     home.nix today, same as conf/look.lua on the Arch side).
#
# State is read from the compositor on every run rather than remembered in a
# file, so this does the right thing after a `hyprctl reload` (which leaves
# a running waybar untouched) or a SIGUSR1 sent from somewhere else.

set -euo pipefail

WAYBAR_CMD=waybar

# "top right bottom left", e.g. "0 0 0 0". general:gaps_out is a CSS-like
# shorthand; hyprctl echoes it back already normalized to all four sides.
read -r top right bottom left < <(hyprctl -j getoption general:gaps_out | jq -r '.css')

if ! pgrep -x "$WAYBAR_CMD" >/dev/null; then
    # Not running at all: start it fresh with the configured gaps.
    hyprctl keyword general:gaps_out "$top $right $bottom $left"
    exec hyprctl dispatch exec "$WAYBAR_CMD"
fi

# A monitor's reserved area is [left, top, right, bottom] (hyprctl monitors
# -j); waybar reserves space on the left on every output it's on, so any
# monitor reporting a left reserve above zero means the bar is showing.
visible=false
while read -r reserved_left; do
    if [ "$reserved_left" -gt 0 ]; then
        visible=true
        break
    fi
done < <(hyprctl -j monitors | jq -r '.[].reserved[0]')

if [ "$visible" = true ]; then
    hyprctl keyword general:gaps_out "$top $right $bottom 0"
else
    hyprctl keyword general:gaps_out "$top $right $bottom $left"
fi

# One signal either way: waybar's own handler flips each of its bars between
# the visible and the invisible mode.
pkill -SIGUSR1 -x "$WAYBAR_CMD"
