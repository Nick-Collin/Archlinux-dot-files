#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
if [ -z "${DISLPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec startx
fi
