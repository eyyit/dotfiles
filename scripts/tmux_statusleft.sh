#!/bin/bash

render_statusleft() {
  local session="${1:-0}"
  local -i width="${2:-100}"

  local status_dir="${XDG_RUNTIME_DIR:-/tmp}"
  local right_file="${status_dir}/tmux.${UID}.${session}.right_len"
  local left_file="${status_dir}/tmux.${UID}.${session}.left_len"

  local -i right_len=36
  if [[ -f "${right_file}" ]]; then
    read -r right_len < "${right_file}" 2>/dev/null || right_len=36
  fi

  local host
  host="$(hostname -s)"
  printf "#[fg=colour0,bg=colour220]%s " "${host}"
  local prev_bg="colour220"
  local -i total_left_len=$(( ${#host} + 1 ))

  local win_fmt="#{window_index}|#{window_name}|#{window_active}|"
  win_fmt+="#{window_last_flag}|#{window_zoomed_flag}"

  local -a windows=()
  local line
  while IFS= read -r line; do
    [[ -n "${line}" ]] && windows+=( "${line}" )
  done < <(tmux list-windows ${session:+-t "${session}"} -F "${win_fmt}")

  local -i num_windows="${#windows[@]}"
  local -i max_left=$(( width - right_len - 1 ))
  (( max_left < 20 )) && max_left=20

  local -i fixed_chrome=$(( ${#host} + 2 ))
  local win idx active zoomed
  for win in "${windows[@]}"; do
    IFS="|" read -r idx _ active _ zoomed <<< "${win}"
    local -i z_len=0
    if [[ "${zoomed}" == "1" ]]; then
      if [[ "${active}" == "1" ]]; then
        z_len=7
      else
        z_len=4
      fi
    fi
    fixed_chrome=$(( fixed_chrome + ${#idx} + 5 + z_len ))
  done

  local -i avail_for_titles=$(( max_left - fixed_chrome ))
  local -i max_title_len=25
  if (( num_windows > 0 )); then
    max_title_len=$(( avail_for_titles / num_windows ))
    (( max_title_len > 25 )) && max_title_len=25
    (( max_title_len < 3 )) && max_title_len=3
  fi

  local name last display_name title bg fg
  for win in "${windows[@]}"; do
    IFS="|" read -r idx name active last zoomed <<< "${win}"
    display_name="${name}"
    if (( ${#name} > max_title_len )); then
      if (( max_title_len > 1 )); then
        display_name="${name:0:$(( max_title_len - 1 ))}…"
      else
        display_name="${name:0:1}"
      fi
    fi
    title="${display_name}"
    if [[ "${active}" == "1" && "${zoomed}" == "1" ]]; then
      bg="colour160"; fg="colour255"; title="${display_name} [ZOOM]"
    elif [[ "${active}" == "1" ]]; then
      bg="colour27"; fg="colour255"
    elif [[ "${last}" == "1" ]]; then
      bg="colour245"; fg="colour0"
      [[ "${zoomed}" == "1" ]] && title="${display_name} [Z]"
    else
      bg="colour238"; fg="colour250"
      [[ "${zoomed}" == "1" ]] && title="${display_name} [Z]"
    fi

    if [[ "${prev_bg}" == "${bg}" ]]; then
      printf "#[fg=colour244,bg=%s]#[fg=%s,bg=%s] %s: %s " \
        "${bg}" "${fg}" "${bg}" "${idx}" "${title}"
    else
      printf "#[fg=%s,bg=%s]#[fg=%s,bg=%s] %s: %s " \
        "${prev_bg}" "${bg}" "${fg}" "${bg}" "${idx}" "${title}"
    fi
    prev_bg="${bg}"
    total_left_len=$(( total_left_len + ${#idx} + ${#title} + 5 ))
  done

  printf "#[fg=%s,bg=colour0]#[default]" "${prev_bg}"
  total_left_len=$(( total_left_len + 1 ))
  printf "%d\n" "${total_left_len}" > "${left_file}.tmp" 2>/dev/null && \
    mv -f "${left_file}.tmp" "${left_file}" 2>/dev/null || true
}

render_statusleft "$@"
