# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil -*-
# zsh-listview: PSReadLine ListView-style inline history suggestions for Zsh
# Zero dependencies. Pure native ZLE.

autoload -Uz add-zle-hook-widget

# User configurable options with sensible defaults
: ${ZSH_LISTVIEW_MAX_ITEMS:=4}
: ${ZSH_LISTVIEW_MIN_CHARS:=2}
: ${ZSH_LISTVIEW_POINTER:="> "}
: ${ZSH_LISTVIEW_INDENT:="  "}

typeset -ga _zsh_listview_items
typeset -gi _zsh_listview_idx=0
typeset -g _zsh_listview_orig_buf=""
typeset -g _zsh_listview_last_buf=""

_zsh_listview_reset() {
  POSTDISPLAY=""
  _zsh_listview_items=()
  _zsh_listview_idx=0
  _zsh_listview_orig_buf=""
  _zsh_listview_last_buf=""
}

_zsh_listview_update() {
  # If currently cycling selections, re-render cursor marker without rescanning history
  if (( _zsh_listview_idx > 0 )); then
    local out=""
    local i
    for (( i=1; i<=${#_zsh_listview_items}; i++ )); do
      if (( i == _zsh_listview_idx )); then
        out+=$'\n'"${ZSH_LISTVIEW_POINTER}${_zsh_listview_items[i]}"
      else
        out+=$'\n'"${ZSH_LISTVIEW_INDENT}${_zsh_listview_items[i]}"
      fi
    done
    POSTDISPLAY="$out"
    return
  fi

  # Skip if buffer has not changed (prevents redraw flicker)
  [[ "$BUFFER" == "$_zsh_listview_last_buf" ]] && return
  _zsh_listview_last_buf="$BUFFER"

  POSTDISPLAY=""
  _zsh_listview_items=()
  _zsh_listview_orig_buf="$BUFFER"

  # Trigger threshold check
  [[ ${#BUFFER} -lt $ZSH_LISTVIEW_MIN_CHARS ]] && return

  local line pattern
  typeset -A seen
  # Escape special glob characters in user input to prevent pattern syntax errors
  pattern="${(b)BUFFER}*"

  for line in ${(Oa)history}; do
    if [[ "$line" == $~pattern && "$line" != "$BUFFER" && -z "${seen[$line]}" ]]; then
      # Strip multiline newlines to keep list layout clean
      local clean_line="${line//$'\n'/ \\n }"
      seen[$clean_line]=1
      _zsh_listview_items+=("$clean_line")
      [[ ${#_zsh_listview_items} -ge $ZSH_LISTVIEW_MAX_ITEMS ]] && break
    fi
  done

  if [[ ${#_zsh_listview_items} -gt 0 ]]; then
    local out=""
    local i
    for (( i=1; i<=${#_zsh_listview_items}; i++ )); do
      out+=$'\n'"${ZSH_LISTVIEW_INDENT}${_zsh_listview_items[i]}"
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
    _zsh_listview_last_buf="$BUFFER"
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
    _zsh_listview_last_buf="$BUFFER"
  else
    zle up-line-or-history
  fi
}

_zsh_listview_escape() {
  if (( _zsh_listview_idx > 0 || ${#_zsh_listview_items} > 0 )); then
    if [[ -n "$_zsh_listview_orig_buf" ]]; then
      BUFFER="$_zsh_listview_orig_buf"
      CURSOR=$#BUFFER
    fi
    _zsh_listview_reset
  else
    zle send-break
  fi
}

_zsh_listview_clear() {
  _zsh_listview_reset
  zle clear-screen
}

zle -N _zsh_listview_down
zle -N _zsh_listview_up
zle -N _zsh_listview_escape
zle -N _zsh_listview_clear

# Keybindings: Arrow Down / Arrow Up / Ctrl+L (Clear Screen) / Escape
bindkey '^[[B' _zsh_listview_down
bindkey '^[OB' _zsh_listview_down
bindkey '^[[A' _zsh_listview_up
bindkey '^[OA' _zsh_listview_up
bindkey '^L'   _zsh_listview_clear
bindkey '^[ '  _zsh_listview_escape
bindkey '^C'   _zsh_listview_escape

add-zle-hook-widget line-pre-redraw _zsh_listview_update
add-zle-hook-widget line-finish     _zsh_listview_reset
add-zle-hook-widget line-init       _zsh_listview_reset
