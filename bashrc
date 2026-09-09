# If not running interactively, don't do anything
[ -z "$PS1" ] && return

PS1user="\\u\\[\\e[0m\\]"
PS1error='$( ret=$? ; test ${ret} -gt 0 && '
PS1error+='echo "\[\e[41;93m\][${ret}]\[\e[0m\]" )'
PS1="${PS1error}\t \\[\\e[01;32m\\]${PS1user}\\[\\e[01;32m\\]@\\h"
PS1+="\\[\\e[01;34m\\] \\w\\$\\[\\e[00m\\] "
export PS1

DOTFILES_DIR="${HOME}/.dotfiles"
for entry in exports aliases functions man_colors; do
  [ -r "${DOTFILES_DIR}/zshrc.d/${entry}" ] && \
    source "${DOTFILES_DIR}/zshrc.d/${entry}"
done
[ -r "${HOME}/.bashrc.local" ] && source "${HOME}/.bashrc.local"

# Hishtory Config:
if [[ -x ${HOME}/.hishtory/hishtory ]]; then
  export PATH="$PATH:${HOME}/.hishtory"
  source ${HOME}/.hishtory/config.sh
fi
