# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git pyenv-lazy zsh-nvm)

trap 'pkill -f "nvim"' SIGHUP

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--tmux'
export FZF_CTRL_T_OPTS=''
alias vim=nvim

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
fi

bindkey -s ^f "tmux-sessionizer\n"
bindkey -s ^t "tmux-attach\n"
bindkey -s ^w "exit\n"
bindkey -s ^v "vim .\n"

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# homebrew
export PATH="/opt/homebrew/bin:$PATH"


# python
alias python="python3"


# Go
export GOENV_DIR="$HOME/.gvm/gos/go1.25.7"
export GOROOT="$GOENV_DIR"

# Ruby
export LDFLAGS="-L/opt/homebrew/opt/openblas/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openblas/include"
# eval "$(rbenv init -)"


# java
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"


# ruby
export GEM_HOME=/Users/tedraykov/.gem/ruby/3.2.0
export PATH=$GEM_HOME/bin:$PATH


# javascript
export NVM_LAZY_LOAD=true
alias p="pnpm"

export PNPM_HOME="/Users/tedraykov/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# flutter
PATH=$HOME/dev/flutter/bin:$PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/teodor.raykov/gcloud/path.zsh.inc' ]; then . '/Users/teodor.raykov/gcloud/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/teodor.raykov/gcloud/completion.zsh.inc' ]; then . '/Users/teodor.raykov/gcloud/completion.zsh.inc'; fi

complete -C '/opt/homebrew/bin/aws_completer' aws

export LUA_PATH='/opt/homebrew/Cellar/luarocks/3.12.2/share/lua/5.1/?.lua;/opt/homebrew/share/lua/5.1/?.lua;/opt/homebrew/share/lua/5.1/?/init.lua;/opt/homebrew/lib/lua/5.1/?.lua;/opt/homebrew/lib/lua/5.1/?/init.lua;./?.lua;./?/init.lua;/Users/teodor.raykov/.luarocks/share/lua/5.1/?.lua;/Users/teodor.raykov/.luarocks/share/lua/5.1/?/init.lua'
export LUA_CPATH='/opt/homebrew/lib/lua/5.1/?.so;/opt/homebrew/lib/lua/5.1/loadall.so;./?.so;/Users/teodor.raykov/.luarocks/lib/lua/5.1/?.so'
export PATH=$HOME/.luarocks/bin:$PATH

[[ -s "/Users/teodor.raykov/.gvm/scripts/gvm" ]] && source "/Users/teodor.raykov/.gvm/scripts/gvm"
