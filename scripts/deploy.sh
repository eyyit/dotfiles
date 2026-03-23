#!//usr/bin/zsh -ex

SCRIPT_DIR=${${(%):-%x}:A:h}
for name in bashrc tmux.conf vim vimrc zshrc; do
  ln -svfT "${SCRIPT_DIR}/../${name}" "${HOME}/.${name}"
done
ln -svfT "${SCRIPT_DIR}/tmux_statusline.sh" "${HOME}/.tmux_statusline.sh"

touch ${HOME}/.zshrc.local

git submodule init
git submodule update
