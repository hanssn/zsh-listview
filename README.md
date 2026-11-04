# zsh-listview

Lightweight, zero-dependency Zsh plugin inspired by PowerShell's PSReadLine `ListView`.

Displays real-time, non-intrusive unique history suggestions below your prompt as you type, navigatable using arrow keys.

## Features

- **As-you-type**: Suggestions appear automatically without manual trigger keys.
- **Deduplicated**: Shows only unique commands from history.
- **Zero dependencies**: Pure Zsh (`ZLE` + `POSTDISPLAY`), no external binaries.
- **Clean**: No full-screen takeover, no terminal artifacts, safe multiline handling.
- **Configurable**: Customize maximum items, pointer symbol, and character threshold.

## Installation

### Manual

Clone the repo:
```zsh
git clone https://github.com/<your-username>/zsh-listview.git ~/.zsh/zsh-listview
```

Add to `~/.zshrc`:
```zsh
source ~/.zsh/zsh-listview/zsh-listview.plugin.zsh
```

### Oh My Zsh

```zsh
git clone https://github.com/<your-username>/zsh-listview.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-listview
```
Add `zsh-listview` to your plugins array in `~/.zshrc`:
```zsh
plugins=(... zsh-listview)
```

## Configuration

You can customize these variables in your `~/.zshrc` **before** sourcing the plugin:

```zsh
# Max suggestions to show (default: 4)
ZSH_LISTVIEW_MAX_ITEMS=5

# Minimum characters before showing suggestions (default: 2)
ZSH_LISTVIEW_MIN_CHARS=2

# Pointer indicator for selected item (default: "> ")
ZSH_LISTVIEW_POINTER="> "

# Indent for non-selected items (default: "  ")
ZSH_LISTVIEW_INDENT="  "
```

## Keybindings

- `↓` (Down Arrow): Cycle forward through suggestions.
- `↑` (Up Arrow): Cycle backward through suggestions.
- `Ctrl+C`: Dismiss list and restore original typed text.
- `Cmd+L` / `Ctrl+L`: Clear screen cleanly without leftover suggestions.
- `Enter`: Execute currently selected suggestion.

## License

[MIT](LICENSE)
