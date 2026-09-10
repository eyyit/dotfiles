#!/bin/bash -e
DATA="${XDG_RUNTIME_DIR:-/tmp}/tmux.${UID}.data"
test -f "${DATA}" || touch "${DATA}"

# =============================================================================
# Configuration & Styling Constants
# =============================================================================

# Fallback dimensions:
readonly DEFAULT_CLIENT_WIDTH=100      # Fallback terminal client width
readonly DEFAULT_LEFT_LEN=20           # Fallback left statusline width

# Dynamic sizing tiers (available width = client_width - left_len - 1):
readonly TIER_FULL_DEC=45  # Network, 3 load values (with decimals), full clock
readonly TIER_FULL=38      # Network, 3 load values (integers), full clock
readonly TIER_FULL_COMP=34 # Network, 3 load values (integers), compact clock
readonly TIER_SHORT_DEC=28 # Network, 1 load value (decimals), compact clock
readonly TIER_SHORT=24     # Network, 1 load value (integer), compact clock
readonly TIER_SHORT_MIN=20 # Network, 1 load value (integer), min clock (<)
readonly TIER_MIN_NET=12   # Min network (<), 1 load value, min clock (<)

# CPU load saturation thresholds (% of total core capacity across cores):
readonly LOAD_CRIT_PCT=200 # >= 200% core capacity: critical flashing red alarm
readonly LOAD_WARN_PCT=100 # >= 100% core capacity: warning orange

# Tab background and foreground colors (256-color palette):
readonly COLOR_BASE_BG="colour0"       # Statusbar base background (black)

# Network tab colors:
readonly COLOR_NET_BG="colour27"       # Network tab background (blue)
readonly COLOR_NET_FG="colour255"      # Network tab text (white)
readonly COLOR_NET_ARROW="colour249"   # Network transfer rate arrows (gray)

# Load tab colors:
readonly COLOR_LOAD_NORMAL="colour34"  # Normal load background (green)
readonly COLOR_LOAD_WARN="colour208"   # Warning load background (orange)
readonly COLOR_LOAD_CRIT_A="colour196" # Critical flash phase A (bright red)
readonly COLOR_LOAD_CRIT_B="colour88"  # Critical flash phase B (crimson)
readonly COLOR_LOAD_FG_NORM="colour255" # Normal/crit load text (white)
readonly COLOR_LOAD_FG_WARN="colour0"  # Warning load text (black)

# Clock / time tab colors:
readonly COLOR_TIME_BG="colour220"     # Clock tab background (yellow)
readonly COLOR_TIME_FG="colour0"       # Clock tab text (black)

# Network sampling and rolling average history parameters:
readonly NET_HISTORY_WINDOW=5          # Rolling average history sample count
readonly NET_HISTORY_MAX_GAP_MS=10000  # Invalidate history if gap > 10s
readonly NET_SAMPLE_MIN_INTERVAL_MS=700 # Min interval between samples (ms)

# =============================================================================

WIDTH="${1:-${DEFAULT_CLIENT_WIDTH}}"
SESSION="${2:-0}"

STATUS_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LEFT_FILE="${STATUS_DIR}/tmux.${UID}.${SESSION}.left_len"
RIGHT_FILE="${STATUS_DIR}/tmux.${UID}.${SESSION}.right_len"

declare -i left_len=${DEFAULT_LEFT_LEN}
if [[ -f "${LEFT_FILE}" ]]; then
  read -r left_len < "${LEFT_FILE}" 2>/dev/null || left_len=${DEFAULT_LEFT_LEN}
fi

# Dynamic remaining width available for right statusline:
declare -i avail_w=$(( WIDTH - left_len - 1 ))

if (( avail_w >= TIER_FULL_DEC )); then
  NET_MODE="full"; LOAD_MODE="full_dec"; TIME_MODE="full"
elif (( avail_w >= TIER_FULL )); then
  NET_MODE="full"; LOAD_MODE="full"; TIME_MODE="full"
elif (( avail_w >= TIER_FULL_COMP )); then
  NET_MODE="full"; LOAD_MODE="full"; TIME_MODE="short"
elif (( avail_w >= TIER_SHORT_DEC )); then
  NET_MODE="full"; LOAD_MODE="short_dec"; TIME_MODE="short"
elif (( avail_w >= TIER_SHORT )); then
  NET_MODE="full"; LOAD_MODE="short"; TIME_MODE="short"
elif (( avail_w >= TIER_SHORT_MIN )); then
  NET_MODE="full"; LOAD_MODE="short"; TIME_MODE="min"
elif (( avail_w >= TIER_MIN_NET )); then
  NET_MODE="min"; LOAD_MODE="short"; TIME_MODE="min"
else
  NET_MODE="min"; LOAD_MODE="min"; TIME_MODE="min"
fi

# Use Bash's clock and formatter to avoid forking date.
curr_time="${EPOCHREALTIME}"
curr_s="${curr_time%.*}"
curr_us="${curr_time#*.}"
curr_ts=$(( 10#${curr_s} * 1000 + 10#${curr_us:0:3} ))
printf -v time_full '%(%-l:%M:%S %p)T' "${curr_s}"
printf -v time_short '%(%-l:%M %p)T' "${curr_s}"

fmt_rate() {
  local -n output="$1"
  local -i curr="$2" prev="$3" diff="$4"
  if (( diff <= 0 || curr < prev )); then
    printf -v output '  0#[fg=%s]b' "${COLOR_NET_ARROW}"
    return
  fi
  local -i rate=$(( (curr - prev) * 1000 / diff ))
  local u="b"
  if (( rate >= 1048051712 )); then
    rate=$(( (rate + 536870912) / 1073741824 ))
    u="G"
  elif (( rate >= 1023488 )); then
    rate=$(( (rate + 524288) / 1048576 ))
    u="M"
  elif (( rate >= 1000 )); then
    rate=$(( (rate + 512) / 1024 ))
    u="K"
  fi
  printf -v output '%3d#[fg=%s]%s' "${rate}" "${COLOR_NET_ARROW}" "${u}"
}

PREV_BG="${COLOR_BASE_BG}"
declare -i right_len=0

render_tab () {
  local bg="$1" fg="$2" content="$3" pad_right="${4- }"
  printf "#[fg=%s,bg=%s]#[fg=%s,bg=%s] %s%s" \
    "$bg" "$PREV_BG" "$fg" "$bg" "$content" "$pad_right"
  PREV_BG="$bg"
}

network_tab () {
  if [[ "${NET_MODE}" == "min" ]]; then
    render_tab "${COLOR_NET_BG}" "${COLOR_NET_FG}" "<"
    right_len=$(( right_len + 4 ))
    return
  fi

  local nic="" iface dest
  while read -r iface dest _; do
    if [[ "${dest}" == "00000000" ]]; then
      nic="${iface}"
      break
    fi
  done < /proc/net/route

  local -i curr_rx=0 curr_tx=0
  local rx_b tx_b
  while IFS=": " read -r iface rx_b _ _ _ _ _ _ _ tx_b _; do
    if [[ "${iface}" == "${nic}" ]]; then
      curr_rx="${rx_b}"
      curr_tx="${tx_b}"
      break
    fi
  done < /proc/net/dev

  declare -a history=()
  if [[ -f "${DATA}" ]]; then
    readarray -t history < "${DATA}" 2>/dev/null
  fi

  # Invalidate history if older than max gap or contains invalid float
  if [[ "${#history[@]}" -gt 0 ]]; then
    local last_ts
    read -r last_ts _ _ <<< "${history[-1]}"
    if [[ "${last_ts}" =~ \. ]] ||
      (( last_ts > curr_ts )) ||
      (( curr_ts - last_ts > NET_HISTORY_MAX_GAP_MS )); then
      history=()
    fi
  fi

  local -i old_ts old_rx old_tx
  if [[ "${#history[@]}" -eq 0 ]]; then
    old_ts="${curr_ts}"; old_rx="${curr_rx}"; old_tx="${curr_tx}"
  else
    read -r old_ts old_rx old_tx <<< "${history[0]}"
    if (( curr_rx < old_rx || curr_tx < old_tx )); then
      history=()
      old_ts="${curr_ts}"; old_rx="${curr_rx}"; old_tx="${curr_tx}"
    fi
  fi

  # Record sample if history is empty or min interval passed since last sample
  local -i should_record=1
  if [[ "${#history[@]}" -gt 0 ]]; then
    local -i last_ts
    read -r last_ts _ _ <<< "${history[-1]}"
    if (( curr_ts - last_ts < NET_SAMPLE_MIN_INTERVAL_MS )); then
      should_record=0
    fi
  fi

  if (( should_record == 1 )); then
    history+=( "${curr_ts} ${curr_rx} ${curr_tx}" )
    if (( ${#history[@]} > NET_HISTORY_WINDOW )); then
      history=( "${history[@]: -${NET_HISTORY_WINDOW}}" )
    fi
    printf "%s\n" "${history[@]}" > "${DATA}.tmp" 2>/dev/null && \
      mv -f "${DATA}.tmp" "${DATA}" 2>/dev/null || true
  fi

  local -i diff_ts=$(( curr_ts - old_ts ))
  local rate_rx rate_tx
  fmt_rate rate_rx "${curr_rx}" "${old_rx}" "${diff_ts}"
  fmt_rate rate_tx "${curr_tx}" "${old_tx}" "${diff_ts}"

  local content
  printf -v content \
    '#[fg=%s]↓#[fg=%s]%s #[fg=%s]↑#[fg=%s]%s' \
    "${COLOR_NET_ARROW}" "${COLOR_NET_FG}" "${rate_rx}" \
    "${COLOR_NET_ARROW}" "${COLOR_NET_FG}" "${rate_tx}"
  render_tab "${COLOR_NET_BG}" "${COLOR_NET_FG}" "${content}"
  right_len=$(( right_len + 14 ))
}

load_tab () {
  read -r l1 l2 l3 _ < /proc/loadavg
  local -i cores=1
  local cpu_range
  if read -r cpu_range < /sys/devices/system/cpu/online 2>/dev/null; then
    cores=$(( ${cpu_range##*-} + 1 ))
  fi
  (( cores < 1 )) && cores=1

  local int_part="${l1%%.*}"
  local dec_part="${l1#*.}"
  dec_part="${dec_part:0:2}"
  (( ${#dec_part} == 1 )) && dec_part="${dec_part}0"
  (( ${#dec_part} == 0 )) && dec_part="00"
  local -i l1_x100=$(( 10#$int_part * 100 + 10#$dec_part ))

  local bg="${COLOR_LOAD_NORMAL}" fg="${COLOR_LOAD_FG_NORM}"
  if (( l1_x100 >= cores * LOAD_CRIT_PCT )); then
    if (( curr_s % 2 == 0 )); then
      bg="${COLOR_LOAD_CRIT_A}"; fg="${COLOR_LOAD_FG_NORM}"
    else
      bg="${COLOR_LOAD_CRIT_B}"; fg="${COLOR_LOAD_FG_NORM}"
    fi
  elif (( l1_x100 >= cores * LOAD_WARN_PCT )); then
    bg="${COLOR_LOAD_WARN}"; fg="${COLOR_LOAD_FG_WARN}"
  fi

  if [[ "${LOAD_MODE}" == "min" ]]; then
    render_tab "${bg}" "${fg}" "<"
    right_len=$(( right_len + 4 ))
    return
  fi

  local content
  if [[ "${LOAD_MODE}" == "full_dec" ]]; then
    content="${l1} ${l2} ${l3}"
  elif [[ "${LOAD_MODE}" == "full" ]]; then
    printf -v content "%.0f %.0f %.0f" "${l1}" "${l2}" "${l3}"
  elif [[ "${LOAD_MODE}" == "short_dec" ]]; then
    content="${l1}"
  else
    printf -v content "%.0f" "${l1}"
  fi
  render_tab "${bg}" "${fg}" "${content}"
  right_len=$(( right_len + ${#content} + 3 ))
}

time_tab () {
  if [[ "${TIME_MODE}" == "min" ]]; then
    render_tab "${COLOR_TIME_BG}" "${COLOR_TIME_FG}" "<" ""
    right_len=$(( right_len + 3 ))
    return
  fi
  local content="${time_short}"
  [[ "${TIME_MODE}" == "full" ]] && content="${time_full}"
  render_tab "${COLOR_TIME_BG}" "${COLOR_TIME_FG}" "${content}" ""
  right_len=$(( right_len + ${#content} + 2 ))
}

network_tab
load_tab
time_tab
printf "#[default]"
printf "%d\n" "${right_len}" > "${RIGHT_FILE}.tmp" 2>/dev/null && \
  mv -f "${RIGHT_FILE}.tmp" "${RIGHT_FILE}" 2>/dev/null || true
