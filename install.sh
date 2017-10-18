sudo apt-get install aptitude
sudo aptitude install tmux git vim zsh exuberant-ctags silversearcher-ag ruby

cp -R .* ~
rm -rf ~/.git ~/install.sh

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

chsh -s $(which zsh)
zsh
