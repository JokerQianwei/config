#!/bin/bash
export PATH="$PATH:/home/yqw/nvim-linux-x86_64/bin"

# 如果是非交互式 shell，则退出
[ -z "$PS1" ] && return

# 保留原有的 Cargo 环境配置
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

#######################################
# 基本设置
#######################################

# 设置历史记录大小和格式
HISTSIZE=5000
HISTFILESIZE=10000
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
export PS1="${debian_chroot:+($debian_chroot)}${Green}\u@\h${Color_Off}:${Blue}\w${Yellow}\$(parse_git_branch)${Color_Off}\$ "

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

# >>> conda 初始化 >>>
# !! 以下内容由 conda 初始化生成，请勿修改 !!
__conda_setup="$('/home/yqw/miniconda3/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "/home/yqw/miniconda3/etc/profile.d/conda.sh" ]; then
    . "/home/yqw/miniconda3/etc/profile.d/conda.sh"
  else
    export PATH="/home/yqw/miniconda3/bin:$PATH"
  fi
fi
unset __conda_setup
# <<< conda 初始化 <<<
# 自动激活 dl conda 环境
conda activate dl

#######################################
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
# 保留原有的代理配置
#######################################

function set_proxy() {
  local proxy
  local default_prefix="172.28"
  local default_port=1082

  # 智能参数处理
  if [ $# -eq 0 ]; then
    proxy="http://127.0.0.1:${default_port}"
  elif [ $# -eq 1 ]; then
    # 模式匹配：输入两个点分数字 (如 183.229)
    if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
      proxy="http://${default_prefix}.$1:${default_port}"
    # 模式匹配：标准 IP 地址无端口
    elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      proxy="http://$1:${default_port}"
    # 其他格式保持原样并补全端口
    else
      proxy="${1}:${default_port}"
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

  # 同步 Git 配置
  git config --global http.proxy "$proxy"
  git config --global https.proxy "$proxy"

  echo "Proxy set to: $proxy"
}

# 取消代理设置
function unset_proxy() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  git config --global --unset http.proxy
  git config --global --unset https.proxy
  echo "Proxy has been unset"
}

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
