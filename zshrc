autoload -U colors compinit promptinit select-word-style
colors
compinit
promptinit
select-word-style whitespace

autoload -Uz vcs_info

#use extended color pallete if available
local yellow="$fg_bold[yellow]"
local gold="$fg[yellow]"
local lightblue="$fg_bold[blue]"
local red="$fg[red]"
local green="$fg[green]"
local black="$fg[black]"
local darkgrey="$fg_bold[black]"
local lightgrey="$fg[white]"
local white="$fg_bold[white]"
local turquoise="$fg[cyan]"
local orange="$fg[yellow]"
local purple="$fg[magenta]"
local hotpink="$fg[red]"
local limegreen="$fg[green]"
local c_time="$fg[white]"
local c_user="$fg_bold[green]"
local c_at="$fg[white]"
local c_host="$fg_bold[cyan]"
local c_pwd="$fg_bold[blue]"
local c_presuf="$fg_bold[blue]"
local c_branch="$fg[yellow]"
local c_prompt="$fg_bold[yellow]"
if [ ! -z $terminfo[colors] ] && [ $terminfo[colors] -eq 256 ] ; then
  local yellow="$fg_bold[yellow]"
  local gold="%F{184}"
  local lightblue="%F{33}"
  local red="$fg[red]"
  local green="$fg[green]"
  local black="$fg[black]"
  local darkgrey="$fg_bold[black]"
  local lightgrey="$fg[white]"
  local white="$fg_bold[white]"
  local turquoise="%F{81}"
  local orange="%F{208}"
  local purple="%F{91}"
  local hotpink="%F{206}"
  local limegreen="%F{118}"
  local c_time="%F{125}"
  test "${USER}" = 'root' && local c_user="%F{202}" || local c_user="${green}"
  local c_at="%F{184}"
  local c_host="%F{33}"
  local c_pwd="%F{30}"
  local c_presuf="%F{32}"
  local c_branch="%F{148}"
  local c_prompt="%F{196}"
fi

# enable VCS systems you use
zstyle ':vcs_info:*' enable git

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true

# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stagedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
local FMT_PREFIX="%{$c_presuf%}["
local FMT_SUFFIX="%{$c_presuf%}]"
local FMT_BRANCH="(%{$c_branch%}%b%u%c)"
local FMT_ACTION="(%{$red%}%a)"
local FMT_UNSTAGED="%{$yellow%} ●"
local FMT_STAGED="%{$green%} ●"

zstyle ':vcs_info:*:prompt:*' unstagedstr   "${FMT_UNSTAGED}"
zstyle ':vcs_info:*:prompt:*' stagedstr     "${FMT_STAGED}"
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

zstyle ':completion:*' menu select
setopt completealiases

function git_precmd {
  local blink='%{[5m%}'
  local reset='%{[0m%}'
  # check for untracked files or updated submodules, since vcs_info doesn't
  local FMT_BRANCH="${FMT_PREFIX}%{$c_branch%}%b%u%c${reset}${FMT_SUFFIX}"
  if [[ -n "$(git status --porcelain 2>/dev/null | grep '^?? ')" ]]; then
    local BLINK_PART="%{$red%}${blink} ⚠️ ${reset}"
    FMT_BRANCH="${FMT_PREFIX}%{$c_branch%}%b${BLINK_PART}%u%c${reset}${FMT_SUFFIX}"
  fi
  zstyle ':vcs_info:*:prompt:*' formats "${FMT_BRANCH}"
  vcs_info 'prompt'
}
add-zsh-hook precmd git_precmd

setopt appendhistory autocd interactivecomments nomatch prompt_subst
bindkey -v
bindkey '^R'     history-incremental-search-backward
bindkey "^K"     kill-line
bindkey "^E"     end-of-line
bindkey "^[[A"   history-search-backward
bindkey "^[[B"   history-search-forward
bindkey "^[[5~"  up-line-or-history
bindkey "^[[6~"  down-line-or-history
bindkey "\e[1~"  beginning-of-line
bindkey "\e[4~"  end-of-line
bindkey "\e[5~"  beginning-of-history
bindkey "\e[6~"  end-of-history
bindkey "\e[3~"  delete-char
bindkey "\e[2~"  quoted-insert
bindkey "\e[5C"  forward-word
bindkey "\eOc"   emacs-forward-word
bindkey "\e[5D"  backward-word
bindkey "\eOd"   emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "^H"     backward-delete-word
bindkey "\e[8~"  end-of-line
bindkey "\e[7~"  beginning-of-line
bindkey "\eOH"   beginning-of-line
bindkey "\eOF"   end-of-line
bindkey "\e[H"   beginning-of-line
bindkey "\e[F"   end-of-line
bindkey '^i'     expand-or-complete-prefix

HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=1000000

# Prompt shit
# %f resets fg color
# %k resets bg color
# %b resets bold
test -r ${HOME}/.prompt && source ${HOME}/.prompt
local p_return="%(?..%{$bg[red]$fg_bold[yellow]%}[%?]%b%f%k )"
local p_docker=""
if [[ -e /.dockerenv ]]; then
  local p_docker="%K{91}%{$fg_bold[yellow]%}DOCKER%b%f%k "
fi
local p_time="%{$c_time%}%*%f"
local p_user="%{$c_user%}%n%f"
local p_host="%{$c_at%}@%{$c_host%}%m%f"
local p_pwd="%{$c_pwd%}%~%f"
local p_prompt="%{$c_prompt%}%#%f"
PROMPT='${p_return}${p_docker}${p_time} ${p_user}${p_host} ${p_pwd} $vcs_info_msg_0_
${p_prompt} '

for entry in ${HOME}/.dotfiles/zshrc.d/* \
             ${HOME}/.zsh.local; do
  test -r ${entry} && source ${entry} || :
done

# Install zsh-syntax-highlighting package first.
if [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  export ZSH_HIGHLIGHT_STYLES[globbing]='fg=blue,bold'
  export ZSH_HIGHLIGHT_STYLES[path]='fg=blue,bold'
fi

# Hishtory Config:
if [[ -x ${HOME}/.hishtory/hishtory ]]; then
  export PATH="$PATH:${HOME}/.hishtory"
  source ${HOME}/.hishtory/config.zsh
fi

# Remove duplicate PATH entries while keeping order:
typeset -U path
