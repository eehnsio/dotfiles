# License: MIT Enable color support of ls
if ls --color=auto &>/dev/null; then
	alias ls='ls -p --color=auto'
else
	alias ls='ls -p -G'
fi

# Aliases
alias ..='echo "cd .."; cd ..'
