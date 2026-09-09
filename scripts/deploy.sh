#!/usr/bin/zsh -ex

SCRIPT_DIR=${${(%):-%x}:A:h}
for name in bashrc tmux.conf vim vimrc zshrc; do
  ln -svfT "${SCRIPT_DIR}/../${name}" "${HOME}/.${name}"
done
ln -svfT "${SCRIPT_DIR}/tmux_statusline.sh" "${HOME}/.tmux_statusline.sh"
ln -svfT "${SCRIPT_DIR}/tmux_statusleft.sh" "${HOME}/.tmux_statusleft.sh"

# SSH agent socket link for tmux forwarding
mkdir -p "${HOME}/.ssh"
ln -svfT "${SCRIPT_DIR}/../ssh_rc" "${HOME}/.ssh/rc"

# Clean up broken legacy dotfile symlinks
for dead in aliases exports functions; do
  test -L "${HOME}/.${dead}" && test ! -e "${HOME}/.${dead}" && \
    rm -vf "${HOME}/.${dead}" || :
done

touch "${HOME}/.zshrc.local"
touch "${HOME}/.bashrc.local"

git -C "${SCRIPT_DIR}/.." submodule update --init --recursive
vim -es -u "${HOME}/.vimrc" -i NONE -c "PlugInstall --sync" -c "qa"
