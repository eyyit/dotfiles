#!/bin/bash
host="$(hostname -s)"
printf "#[fg=colour0,bg=colour220]%s " "${host}"
prev_bg="colour220"

win_fmt="#{window_index}|#{window_name}|#{window_active}|"
win_fmt+="#{window_last_flag}|#{window_zoomed_flag}"

while IFS="|" read -r idx name active last zoomed; do
  display_name="${name}"
  if (( ${#name} > 15 )); then
    display_name="${name:0:14}…"
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
done < <(tmux list-windows -F "${win_fmt}")

printf "#[fg=%s,bg=colour0]#[default]" "${prev_bg}"
