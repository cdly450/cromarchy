#!/usr/bin/env bash
set -euo pipefail
STATE="/tmp/hypr-dpms-state"
CUR="on"; [[ -f "$STATE" ]] && CUR="$(cat "$STATE" || echo on)"
if [[ "$CUR" == "off" ]]; then
  hyprctl dispatch dpms on
  echo on >"$STATE"
else
  hyprctl dispatch dpms off
  echo off >"$STATE"
fi