# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil -*-
# zsh-listview: PSReadLine ListView-style inline history suggestions for Zsh
# Zero dependencies. Pure native ZLE. Simple & Linear.

autoload -Uz add-zle-hook-widget

# User configurable options with sensible defaults
: ${ZSH_LISTVIEW_PAGE_SIZE:=4}
: ${ZSH_LISTVIEW_MAX_SEARCH:=1000}
: ${ZSH_LISTVIEW_MIN_CHARS:=2}
: ${ZSH_LISTVIEW_POINTER:="> "}
: ${ZSH_LISTVIEW_INDENT:="  "}

typeset -ga _zsh_listview_items
typeset -gi _zsh_listview_idx=0
typeset -g _zsh_listview_orig_buf=""
typeset -g _zsh_listview_last_buf=""
typeset -gi _zsh_listview_active=0

_zsh_listview_render() {
  local count=${#_zsh_listview_items}
  if (( count == 0 )); then
    POSTDISPLAY=""
    return
  fi

  local page_size=$ZSH_LISTVIEW_PAGE_SIZE
  local sel=${_zsh_listview_idx:-1}
  (( sel == 0 )) && sel=1

  # Sliding window: 4 items per page
  local start_idx=$(( ((sel - 1) / page_size) * page_size + 1 ))
  local end_idx=$(( start_idx + page_size - 1 ))
  (( end_idx > count )) && end_idx=$count

  local max_w=$(( COLUMNS - 4 ))
  (( max_w < 10 )) && max_w=80

  local out="" item line_txt
  local -i i
  for (( i=start_idx; i<=end_idx; i++ )); do
    item="${_zsh_listview_items[i]}"
    (( ${#item} > max_w )) && item="${item[1,max_w-1]}…"
    if (( i == _zsh_listview_idx )); then
      line_txt="${ZSH_LISTVIEW_POINTER}${item}"
    else
      line_txt="${ZSH_LISTVIEW_INDENT}${item}"
    fi
    out+=$'\n'"$line_txt"
  done
  POSTDISPLAY="$out"
}

_zsh_listview_reset() {
  POSTDISPLAY=""
  _zsh_listview_items=()
  _zsh_listview_idx=0
  _zsh_listview_active=0
  _zsh_listview_orig_buf=""
  _zsh_listview_last_buf=""
}

_zsh_listview_update() {
  # Jangan scan ulang saat user sedang memilih item dari list
  (( _zsh_listview_active )) && return

  # Skip jika buffer belum berubah
  [[ "$BUFFER" == "$_zsh_listview_last_buf" ]] && return
  _zsh_listview_last_buf="$BUFFER"

  POSTDISPLAY=""
  _zsh_listview_items=()
  _zsh_listview_idx=0
  _zsh_listview_orig_buf="$BUFFER"

  [[ ${#BUFFER} -lt $ZSH_LISTVIEW_MIN_CHARS ]] && return

  local pattern="${(b)BUFFER}*"
  local -a matched
  # (Mao) puts newest history entries first (keys ordered descending)
  matched=( ${(Mao)history:#$~pattern} )

  typeset -A seen
  local line clean_line
  local -i scanned=0 max_scan=$ZSH_LISTVIEW_MAX_SEARCH

  # Iterate forward: newest history first
  for line in "${matched[@]}"; do
    [[ "$line" == "$BUFFER" ]] && continue

    clean_line="${line//$'\n'/ \\n }"
    if (( ! seen[$clean_line] )); then
      seen[$clean_line]=1
      _zsh_listview_items+=("$clean_line")
      (( ++scanned >= max_scan )) && break
    fi
  done

  _zsh_listview_render
}

_zsh_listview_down() {
  if [[ ${#_zsh_listview_items} -gt 0 ]]; then
    _zsh_listview_active=1
    if (( _zsh_listview_idx < ${#_zsh_listview_items} )); then
      (( _zsh_listview_idx++ ))
      BUFFER="${_zsh_listview_items[_zsh_listview_idx]}"
      CURSOR=$#BUFFER
      _zsh_listview_render
    fi
  else
    zle down-line-or-history
  fi
}

_zsh_listview_up() {
  if [[ ${#_zsh_listview_items} -gt 0 && _zsh_listview_idx -gt 0 ]]; then
    (( _zsh_listview_idx-- ))
    if (( _zsh_listview_idx == 0 )); then
      _zsh_listview_active=0
      BUFFER="$_zsh_listview_orig_buf"
    else
      _zsh_listview_active=1
      BUFFER="${_zsh_listview_items[_zsh_listview_idx]}"
    fi
    CURSOR=$#BUFFER
    _zsh_listview_render
  else
    zle up-line-or-history
  fi
}

_zsh_listview_escape() {
  if (( _zsh_listview_active || ${#_zsh_listview_items} > 0 )); then
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

# Keybindings: Arrow Down / Arrow Up / Ctrl+L / Escape
bindkey '^[[B' _zsh_listview_down
bindkey '^[OB' _zsh_listview_down
bindkey '^[[A' _zsh_listview_up
bindkey '^[OA' _zsh_listview_up
bindkey '^L'   _zsh_listview_clear
bindkey '^[ '  _zsh_listview_escape

add-zle-hook-widget line-pre-redraw _zsh_listview_update
add-zle-hook-widget line-finish     _zsh_listview_reset
add-zle-hook-widget line-init       _zsh_listview_reset
