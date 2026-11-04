# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil -*-
# zsh-listview: PSReadLine ListView-style inline history suggestions for Zsh
# Zero dependencies. Pure native ZLE.

autoload -Uz add-zle-hook-widget

typeset -ga _zsh_listview_items
typeset -gi _zsh_listview_idx=0
typeset -g _zsh_listview_orig_buf=""

_zsh_listview_reset() {
  POSTDISPLAY=""
  _zsh_listview_items=()
  _zsh_listview_idx=0
  _zsh_listview_orig_buf=""
}

_zsh_listview_update() {
  # If currently cycling selections, keep view updated with pointer
  if (( _zsh_listview_idx > 0 )); then
    local out=""
    local i
    for (( i=1; i<=${#_zsh_listview_items}; i++ )); do
      if (( i == _zsh_listview_idx )); then
        out+=$'\n> '"${_zsh_listview_items[i]}"
      else
        out+=$'\n  '"${_zsh_listview_items[i]}"
      fi
    done
    POSTDISPLAY="$out"
    return
  fi

  _zsh_listview_reset
  _zsh_listview_orig_buf="$BUFFER"

  # Trigger after at least 2 chars
  [[ ${#BUFFER} -lt 2 ]] && return

  local line
  typeset -A seen

  for line in ${(Oa)history}; do
    if [[ "$line" == ${BUFFER}* && "$line" != "$BUFFER" && -z "${seen[$line]}" ]]; then
      seen[$line]=1
      _zsh_listview_items+=("$line")
      [[ ${#_zsh_listview_items} -ge 4 ]] && break
    fi
  done

  if [[ ${#_zsh_listview_items} -gt 0 ]]; then
    local out=""
    local i
    for (( i=1; i<=${#_zsh_listview_items}; i++ )); do
      out+=$'\n  '"${_zsh_listview_items[i]}"
    done
    POSTDISPLAY="$out"
  fi
}

_zsh_listview_down() {
  if [[ ${#_zsh_listview_items} -gt 0 ]]; then
    (( _zsh_listview_idx++ ))
    if (( _zsh_listview_idx > ${#_zsh_listview_items} )); then
      _zsh_listview_idx=0
      BUFFER="$_zsh_listview_orig_buf"
    else
      BUFFER="${_zsh_listview_items[_zsh_listview_idx]}"
    fi
    CURSOR=$#BUFFER
  else
    zle down-line-or-history
  fi
}

_zsh_listview_up() {
  if [[ ${#_zsh_listview_items} -gt 0 && _zsh_listview_idx -gt 0 ]]; then
    (( _zsh_listview_idx-- ))
    if (( _zsh_listview_idx == 0 )); then
      BUFFER="$_zsh_listview_orig_buf"
    else
      BUFFER="${_zsh_listview_items[_zsh_listview_idx]}"
    fi
    CURSOR=$#BUFFER
  else
    zle up-line-or-history
  fi
}

_zsh_listview_clear() {
  _zsh_listview_reset
  zle clear-screen
}

zle -N _zsh_listview_down
zle -N _zsh_listview_up
zle -N _zsh_listview_clear

# Keybindings: Arrow Down / Arrow Up / Ctrl+L (Clear Screen)
bindkey '^[[B' _zsh_listview_down
bindkey '^[OB' _zsh_listview_down
bindkey '^[[A' _zsh_listview_up
bindkey '^[OA' _zsh_listview_up
bindkey '^L'   _zsh_listview_clear

add-zle-hook-widget line-pre-redraw _zsh_listview_update
add-zle-hook-widget line-finish     _zsh_listview_reset
