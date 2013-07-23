#aliases
alias ls="ls --color=always -h"
alias ko="kde-open"
#ack-grep is slooooooooow
#alias grep="ack-grep --color-match=red"
alias grep="grep -I --color=auto -n --exclude=tags " #GREPOPTIONS isn't working
alias ggrep="git grep -pnI --break --color=auto "
alias less="less -rgIM" #LESS env variable isn't working
alias omnitags="ctags -R --sort=1 --c++-kinds=+p --fields=+iaS --extra=+q --language-force=C++ *"

#update path to include user's bin/
export PATH=/usr/sbin:~/bin:/sbin:$PATH
export PAGER="less"
export EDITOR="vim"
export LESS="-rgIM "
export GREPOPTIONS=" --color=always -n --exclude=tags"
PS1="[\u@\h:\W]\$ "

#colored man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;34m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#some convinient shortcuts
bind '\C-e:unix-filename-rubout'

#start or attach to tmux session on startup
tmux_exists=`ps u | grep tmux`
if [ "$TERM" != "screen" ]; then
	if [ -z "$tmux_exists" ]; then
		tmux
	else
		tmux attach -d
	fi
fi

function cgrep ()
{
    find . -name .repo -prune -o -name .git -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}
