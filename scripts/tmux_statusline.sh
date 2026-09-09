#!/bin/bash -e
DATA="${XDG_RUNTIME_DIR:-/tmp}/tmux.${UID}.data"
test -f "${DATA}" || touch "${DATA}"

WIDTH="${1:-100}"
SESSION="${2:-0}"

STATUS_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LEFT_FILE="${STATUS_DIR}/tmux.${UID}.${SESSION}.left_len"
RIGHT_FILE="${STATUS_DIR}/tmux.${UID}.${SESSION}.right_len"

declare -i left_len=20
if [[ -f "${LEFT_FILE}" ]]; then
  read -r left_len < "${LEFT_FILE}" 2>/dev/null || left_len=20
fi

# Dynamic remaining width available for right statusline:
declare -i avail_w=$(( WIDTH - left_len - 1 ))

# Sizing tiers based on dynamically available width:
# >= 38: Network, 3 load values, full clock
# 34-37: Network, 3 load values, compact clock
# 28-33: Network, 1 load value,  compact clock
# 20-27: Network, 1 load value,  minimized clock (<)
# 12-19: Min network (<), 1 load value, minimized clock (<)
# < 12:  All widgets minimized (<)

if (( avail_w >= 38 )); then
  NET_MODE="full"; LOAD_MODE="full"; TIME_MODE="full"
elif (( avail_w >= 34 )); then
  NET_MODE="full"; LOAD_MODE="full"; TIME_MODE="short"
elif (( avail_w >= 28 )); then
  NET_MODE="full"; LOAD_MODE="short"; TIME_MODE="short"
elif (( avail_w >= 20 )); then
  NET_MODE="full"; LOAD_MODE="short"; TIME_MODE="min"
elif (( avail_w >= 12 )); then
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
    printf -v output '  0#[fg=colour249]b'
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
  printf -v output '%3d#[fg=colour249]%s' "${rate}" "${u}"
}

PREV_BG="colour0"
declare -i right_len=0

render_tab () {
  local bg="$1" fg="$2" content="$3" pad_right="${4- }"
  printf "#[fg=%s,bg=%s]#[fg=%s,bg=%s] %s%s" \
    "$bg" "$PREV_BG" "$fg" "$bg" "$content" "$pad_right"
  PREV_BG="$bg"
}

network_tab () {
  if [[ "${NET_MODE}" == "min" ]]; then
    render_tab "colour27" "colour255" "<"
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

  # Invalidate history if last sample is older than 10s or has invalid float
  if [[ "${#history[@]}" -gt 0 ]]; then
    local last_ts
    read -r last_ts _ _ <<< "${history[-1]}"
    if [[ "${last_ts}" =~ \. ]] ||
      (( last_ts > curr_ts || curr_ts - last_ts > 10000 )); then
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

  # Record sample if history is empty or at least 0.7s passed since last sample
  local -i should_record=1
  if [[ "${#history[@]}" -gt 0 ]]; then
    local -i last_ts
    read -r last_ts _ _ <<< "${history[-1]}"
    if (( curr_ts - last_ts < 700 )); then
      should_record=0
    fi
  fi

  if (( should_record == 1 )); then
    history+=( "${curr_ts} ${curr_rx} ${curr_tx}" )
    local -ir window_size=5
    if (( ${#history[@]} > window_size )); then
      history=( "${history[@]: -${window_size}}" )
    fi
    printf "%s\n" "${history[@]}" > "${DATA}"
  fi

  local -i diff_ts=$(( curr_ts - old_ts ))
  local rate_rx rate_tx
  fmt_rate rate_rx "${curr_rx}" "${old_rx}" "${diff_ts}"
  fmt_rate rate_tx "${curr_tx}" "${old_tx}" "${diff_ts}"

  local content
  printf -v content \
    '#[fg=colour249]↓#[fg=colour255]%s #[fg=colour249]↑#[fg=colour255]%s' \
    "${rate_rx}" "${rate_tx}"
  render_tab "colour27" "colour255" "${content}"
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

  local bg="colour34" fg="colour255"
  if (( l1_x100 >= cores * 200 )); then
    bg="colour160"; fg="colour255"
  elif (( l1_x100 >= cores * 100 )); then
    bg="colour208"; fg="colour0"
  fi

  if [[ "${LOAD_MODE}" == "min" ]]; then
    render_tab "${bg}" "${fg}" "<"
    right_len=$(( right_len + 4 ))
    return
  fi

  local content
  if [[ "${LOAD_MODE}" == "full" ]]; then
    printf -v content "%.0f %.0f %.0f" "${l1}" "${l2}" "${l3}"
  else
    printf -v content "%.0f" "${l1}"
  fi
  render_tab "${bg}" "${fg}" "${content}"
  right_len=$(( right_len + ${#content} + 3 ))
}

time_tab () {
  if [[ "${TIME_MODE}" == "min" ]]; then
    render_tab "colour220" "colour0" "<" ""
    right_len=$(( right_len + 3 ))
    return
  fi
  local content="${time_short}"
  [[ "${TIME_MODE}" == "full" ]] && content="${time_full}"
  render_tab "colour220" "colour0" "${content}" ""
  right_len=$(( right_len + ${#content} + 2 ))
}

network_tab
load_tab
time_tab
printf "#[default]"
printf "%d\n" "${right_len}" > "${RIGHT_FILE}" 2>/dev/null || true
