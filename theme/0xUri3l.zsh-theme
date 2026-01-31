#Author : 0xUri3l 0xUri (https://github.com/0xUri)

# Load and configure vcs_info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' formats       '🪵 %b %u%c'
zstyle ':vcs_info:*' actionformats '🪵 %b %F{yellow}%a%f %u%c'
zstyle ':vcs_info:*' stagedstr     '%F{green}%f'
zstyle ':vcs_info:*' unstagedstr   '%F{yellow}%f'

# Command execution time
preexec() {
  cmd_timestamp=$SECONDS
}

precmd() {
  if [[ -n "$cmd_timestamp" ]]; then
    local cmd_duration=$(($SECONDS - $cmd_timestamp))
    unset cmd_timestamp
    if [[ $cmd_duration -ge 5 ]]; then
      if [[ $cmd_duration -ge 60 ]]; then
        local minutes=$((cmd_duration / 60))
        local seconds=$((cmd_duration % 60))
        cmd_exec_time="${minutes}m${seconds}s"
      else
        cmd_exec_time="${cmd_duration}s"
      fi
      export cmd_exec_time
    else
      unset cmd_exec_time
    fi
  fi
  vcs_info
}

# Battery info
get_battery_info() {
  local percentage
  local battery_status
  local bat_path
  local status_icon
  local color_code

  if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
    bat_path="/sys/class/power_supply/BAT0"
  elif [[ -f /sys/class/power_supply/BAT1/capacity ]]; then
    bat_path="/sys/class/power_supply/BAT1"
  fi

  if [[ -n "$bat_path" ]]; then
    percentage=$(cat "$bat_path/capacity")
    if [[ -f "$bat_path/status" ]]; then
      battery_status=$(cat "$bat_path/status")
    fi
  else
    if command -v upower &> /dev/null; then
      local battery_path=$(upower -e | grep 'BAT')
      if [[ -n "$battery_path" ]]; then
        percentage=$(upower -i "$battery_path" | awk '/percentage:/ {print int($2)}')
        battery_status=$(upower -i "$battery_path" | awk '/state:/ {print $2}')
      fi
    fi
  fi

  if [[ -z "$percentage" ]]; then
    echo "%F{red} N/A%f"
    return
  fi

  local is_charging=false
  if [[ "$battery_status" == "Charging" || "$battery_status" == "charging" ]]; then
    is_charging=true
  fi

  if (( percentage > 90 )); then
    $is_charging && status_icon="󰂊" || status_icon="󰁹"
    color_code="%F{green}"
  elif (( percentage > 80 )); then
    $is_charging && status_icon="󰂉" || status_icon="󰂂"
    color_code="%F{green}"
  elif (( percentage > 60 )); then
    $is_charging && status_icon="󰂈" || status_icon="󰂀"
    color_code="%F{green}"
  elif (( percentage > 40 )); then
    $is_charging && status_icon="󰂇" || status_icon="󰁾"
    color_code="%F{yellow}"
  elif (( percentage > 20 )); then
    $is_charging && status_icon="󰂆" || status_icon="󰁼"
    color_code="%F{yellow}"
  elif (( percentage > 10 )); then
    $is_charging && status_icon="󰂅" || status_icon="󰁺"
    color_code="%F{red}"
  else
    status_icon="󰂃"
    color_code="%F{red}"
  fi

  echo "${color_code}${status_icon} ${percentage}%%%f"
}

# Pyenv info
get_pyenv_info() {
  if command -v pyenv &>/dev/null; then
    local ver=$(pyenv version-name 2>/dev/null)
    if [[ -n "$ver" && "$ver" != "system" ]]; then
      echo " %F{white}•  %f%F{yellow}🪝 ${ver}%f"
    fi
  fi
}

PROMPT='
 ┌[%F{magenta} %~%f
┌└%F{yellow} $USER%f💀🚬%F{yellow}%m%f %F{white}⮞  %f%F{cyan}$(get_battery_info)%f %F{white}⮞  %f%F{green}$(get_ip_address)%f$(get_pyenv_info)$( [[ -n "$vcs_info_msg_0_" ]] && echo " %F{white}•  %f$(vcs_info_wrapper)" )
└➤ '

RPROMPT='$([ -n "$cmd_exec_time" ] && echo "[%F{yellow}↱ ${cmd_exec_time}%f]")'

# Wrapper for vcs_info
vcs_info_wrapper() {
  if [[ -n "$vcs_info_msg_0_" ]]; then
    local raw_branch_name=$(echo "$vcs_info_msg_0_" | command grep -oP '(?<=🪵 )[^ %]+' || echo "")
    local git_status=$(echo "$vcs_info_msg_0_" | sed -E 's/.*🪵 [^ ]+ ?(.*)/\1/')

    # Couleur selon le type de branche
    local branch_color
    if [[ "$raw_branch_name" == "main" || "$raw_branch_name" == "master" ]]; then
      branch_color="%F{green}"
    elif [[ "$raw_branch_name" == "dev" || "$raw_branch_name" == "develop" || "$raw_branch_name" == dev/* ]]; then
      branch_color="%F{yellow}"
    else
      branch_color="%F{cyan}"
    fi

    # Indicateur : clean, dirty ou besoin de push
    local indicators=""
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
    if (( ahead > 0 )); then
      indicators=" %F{white}»%f %F{yellow}↑%f"
    elif [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      indicators=" %F{white}»%f %F{red}✗%f"
    else
      indicators=" %F{white}»%f %F{green}✓%f"
    fi

    echo "${branch_color}🪵%f ${branch_color}${raw_branch_name}%f${indicators} ${git_status}"
  fi
}

get_ip_address() {
  local found=0
  local ips=()
  while IFS= read -r line; do
    local iface=$(echo "$line" | awk '{print $2}')
    local ip=$(echo "$line" | awk '{print $4}' | cut -d'/' -f1)
    local linkinfo=$(ip -o link show "$iface")
    # Exclure lo et les interfaces Docker (docker*, br-*, veth*)
    if [[ "$iface" != "lo" && "$iface" != docker* && "$iface" != br-* && "$iface" != veth* && -n "$ip" && "$linkinfo" == *"UP"* ]]; then
      local icon=""
      local color="%F{cyan}"
      if [[ "$iface" == tun* || "$iface" == tap* || "$iface" == wg* || "$iface" == *vpn* || "$iface" == *VPN* || "$linkinfo" == *POINTOPOINT* ]]; then
        icon="👻"
        color="%F{magenta}"
      elif [[ "$iface" == eth* || "$iface" == enp* ]]; then
        icon=""
      elif [[ "$iface" == wlan* || "$iface" == wlp* || "$iface" == wlo* ]]; then
        icon="🔗"
      else
        icon=""
      fi
      ips+=("${color}${icon} ${ip}%f")
      found=1
    fi
  done < <(ip -o -4 addr show)
  if (( found )); then
    printf "%s " "${ips[@]}"
    echo
  else
    echo "%F{red}%f"
  fi
}
