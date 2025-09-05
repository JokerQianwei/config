#!/bin/bash
export PATH="$PATH:/home/yqw/nvim-linux-x86_64/bin"

# 如果是非交互式 shell，则退出
# [ -z "$PS1" ] && return

# 保留原有的 Cargo 环境配置
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# 设置历史记录大小和格式
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth  # 忽略重复的命令和空格开头的命令
shopt -s histappend     # 追加到历史文件而不是覆盖
HISTTIMEFORMAT="%F %T " # 添加时间戳到历史记录

# 检查窗口大小
shopt -s checkwinsize

# 设置 less 为默认分页器
export PAGER="less"
export LESS="-R"

#######################################
# 终端颜色和提示符设置
#######################################

# 颜色定义
# Reset
Color_Off='\[\e[0m\]' # Text Reset
# Regular Colors
Black='\[\e[0;30m\]'  # Black
Red='\[\e[0;31m\]'    # Red
Green='\[\e[0;32m\]'  # Green
Yellow='\[\e[0;33m\]' # Yellow
Blue='\[\e[0;34m\]'   # Blue
Purple='\[\e[0;35m\]' # Purple
Cyan='\[\e[0;36m\]'   # Cyan
White='\[\e[0;37m\]'  # White
# Bold
BBlack='\[\e[1;30m\]'  # Black
BRed='\[\e[1;31m\]'    # Red
BGreen='\[\e[1;32m\]'  # Green
BYellow='\[\e[1;33m\]' # Yellow
BBlue='\[\e[1;34m\]'   # Blue
BPurple='\[\e[1;35m\]' # Purple
BCyan='\[\e[1;36m\]'   # Cyan
BWhite='\[\e[1;37m\]'  # White

# 显示 git 分支信息
parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# 设置漂亮的提示符
export PS1="${debian_chroot:+($debian_chroot)}${Green}\u@\h${Color_Off} ${BBlue}[\t] [\w]${Yellow}\$(parse_git_branch)${Color_Off}\n${BBlue}-> \$ ${Color_Off}"

# 启用颜色支持
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

#######################################
# Conda 配置
#######################################
# 完全重置conda环境变量
unset CONDA_SHLVL
unset CONDA_PREFIX
unset CONDA_PREFIX_1
unset CONDA_PREFIX_2
unset CONDA_PREFIX_3
unset CONDA_PREFIX_4
unset CONDA_DEFAULT_ENV

# 使用最简单的方式初始化conda
eval "$(/home/yqw/miniconda3/bin/conda shell.bash hook)"

conda activate bd3lm
# <<< conda 初始化 <<<

######################################
# 实用别名
#######################################

# ls 相关别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 文件操作安全别名
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# 文件系统导航
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git 别名
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'

# 常用命令别名
alias hc='history -c'         # 清除历史记录
alias ports='netstat -tulanp' # 显示所有开放端口
alias meminfo='free -m -l -t' # 显示内存使用情况

# 显示当前目录下文件大小
alias duf='du -sk * | sort -n | perl -ne '\''($s,$f)=split(m{\t});for (qw(K M G)) {if($s<1024) {printf("%.1f",$s);print "$_\t$f"; last};$s=$s/1024}'\'

#######################################
# 代理配置管理
#######################################

# 代理配置文件路径
PROXY_CONFIG_FILE="$HOME/.proxy_config"

function set_proxy() {
  local proxy
  local default_prefix="172.28"
  local default_port=1082

  # 智能参数处理
  if [ $# -eq 0 ]; then
    # 如果没有参数，尝试从配置文件读取上次的代理设置
    if [ -f "$PROXY_CONFIG_FILE" ]; then
      proxy=$(cat "$PROXY_CONFIG_FILE")
    #  echo "Using saved proxy from $PROXY_CONFIG_FILE"
    else
      proxy="http://127.0.0.1:${default_port}"
      echo "Using default proxy (no saved configuration found)"
    fi
  elif [ $# -eq 1 ]; then
    # 模式匹配：输入两个点分数字 (如 183.229)
    if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
      proxy="http://${default_prefix}.$1:${default_port}"
    # 模式匹配：标准 IP 地址无端口
    elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      proxy="http://$1:${default_port}"
    # 检查是否是完整的URL (包含协议)
    elif [[ "$1" =~ ^https?:// ]]; then
      proxy="$1"
    # 其他格式保持原样并补全协议和端口
    else
      proxy="http://${1}:${default_port}"
    fi
  elif [ $# -eq 2 ]; then
    # 输入两个参数时视为 IP + 端口
    proxy="http://$1:$2"
  fi

  # 设置环境变量
  export http_proxy="$proxy"
  export https_proxy="$proxy"
  export HTTP_PROXY="$proxy"
  export HTTPS_PROXY="$proxy"

  # 设置 npm 环境变量代理（优先级高于 npm config）
  export npm_config_proxy="$proxy"
  export npm_config_https_proxy="$proxy"

  # 保存代理配置到文件
  echo "$proxy" >"$PROXY_CONFIG_FILE"

  # 同步 Git 配置
  git config --global http.proxy "$proxy"
  git config --global https.proxy "$proxy"

  # 同步 npm 配置（作为备用）
  if command -v npm &>/dev/null; then
    npm config set proxy "$proxy"
    npm config set https-proxy "$proxy"
    echo "npm proxy updated (config + env vars)"
  fi

  echo "Proxy set to: $proxy"
  echo "Proxy configuration saved to $PROXY_CONFIG_FILE"
}

# 取消代理设置
function unset_proxy() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  unset npm_config_proxy npm_config_https_proxy
  git config --global --unset http.proxy 2>/dev/null
  git config --global --unset https.proxy 2>/dev/null

  # 清除 npm 代理配置
  if command -v npm &>/dev/null; then
    npm config delete proxy 2>/dev/null
    npm config delete https-proxy 2>/dev/null
    echo "npm proxy cleared (config + env vars)"
  fi

  # 删除保存的代理配置文件
  if [ -f "$PROXY_CONFIG_FILE" ]; then
    rm "$PROXY_CONFIG_FILE"
    echo "Saved proxy configuration removed"
  fi

  echo "Proxy has been unset"
}

# 显示当前代理设置
function show_proxy() {
  echo "Current proxy environment variables:"
  echo "  http_proxy=$http_proxy"
  echo "  https_proxy=$https_proxy"
  echo "  HTTP_PROXY=$HTTP_PROXY"
  echo "  HTTPS_PROXY=$HTTPS_PROXY"
  echo "  npm_config_proxy=$npm_config_proxy"
  echo "  npm_config_https_proxy=$npm_config_https_proxy"

  if [ -f "$PROXY_CONFIG_FILE" ]; then
    echo "Saved proxy configuration: $(cat "$PROXY_CONFIG_FILE")"
  else
    echo "No saved proxy configuration found"
  fi

  echo "Git proxy configuration:"
  git config --global --get http.proxy 2>/dev/null && echo "  Git http.proxy: $(git config --global --get http.proxy)" || echo "  Git http.proxy: not set"
  git config --global --get https.proxy 2>/dev/null && echo "  Git https.proxy: $(git config --global --get https.proxy)" || echo "  Git https.proxy: not set"

  echo "NPM proxy configuration:"
  if command -v npm &>/dev/null; then
    echo "  npm config proxy: $(npm config get proxy)"
    echo "  npm config https-proxy: $(npm config get https-proxy)"
  fi
}

# 自动应用保存的代理设置（仅在交互式shell中）
if [[ $- == *i* ]] && [ -f "$PROXY_CONFIG_FILE" ]; then
  saved_proxy=$(cat "$PROXY_CONFIG_FILE")
  if [ -n "$saved_proxy" ]; then
    export http_proxy="$saved_proxy"
    export https_proxy="$saved_proxy"
    export HTTP_PROXY="$saved_proxy"
    export HTTPS_PROXY="$saved_proxy"
    export npm_config_proxy="$saved_proxy"
    export npm_config_https_proxy="$saved_proxy"
  # echo "Auto-applied saved proxy: $saved_proxy"
  # echo "Use 'unset_proxy' to disable or 'set_proxy <new_proxy>' to change"
  fi
fi

#######################################
# Python 相关设置
#######################################

# 为 Python 虚拟环境设置别名
alias venv='python -m venv .venv'
alias activate='source .venv/bin/activate'

# 常用 Python 别名
alias py='python'
alias ipy='ipython'
alias jn='jupyter notebook'
alias jl='jupyter lab'

#######################################
# 实用函数
#######################################

# 创建并进入目录
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# 提取常见压缩文件
extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar e $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' 无法被解压缩" ;;
    esac
  else
    echo "'$1' 不是有效的文件"
  fi
}

# 搜索历史命令
hgrep() {
  history | grep "$1"
}

# 快速查找文件
ff() {
  find . -name "*$1*" -type f
}

# 显示当前目录下大文件/目录
bigfiles() {
  du -h --max-depth=1 "$@" | sort -hr
}

# 如果存在用户自定义配置，加载它
if [ -f ~/.bashrc.user ]; then
  source ~/.bashrc.user
fi
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# export PATH="/data1/yqw/lite_diffETO:$PATH"

#######################################
# npm/npx 配置
#######################################

# 设置 npm 使用 curl 作为默认的网络请求工具
export NODE_OPTIONS="--http-parser=legacy"
export NPM_CONFIG_FETCH_RETRIES=3
export NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=10000
export NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=60000
# 明确设置为1以确保TLS证书验证（安全选项), 设置为0 跳过检验
export NODE_TLS_REJECT_UNAUTHORIZED=0

. "$HOME/.local/bin/env"
export HF_ENDPOINT=https://hf-mirror.com

export ENABLE_BACKGROUND_TASKS=1

alias claude-d='claude --dangerously-skip-permissions'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias claude="/home/yqw/.claude/local/claude"

# alias claude="/home/yqw/.claude/local/claude"

alias claude="/home/yqw/.claude/local/claude"

export PATH="$HOME/.nvm/versions/node/v22.17.1/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/bin:$PATH"