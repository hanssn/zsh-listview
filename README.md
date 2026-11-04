# zsh-listview

Lightweight, zero-dependency Zsh plugin inspired by PowerShell's PSReadLine `ListView`.

Displays real-time, non-intrusive unique history suggestions below your prompt as you type, navigatable using arrow keys.

## Features

- **As-you-type**: Suggestions appear automatically without manual trigger keys.
- **Deduplicated**: Shows only unique commands from history.
- **Zero dependencies**: Pure Zsh (`ZLE` + `POSTDISPLAY`), no Python/Go/Rust binary needed.
- **Clean**: No full-screen takeover, no terminal artifacts.

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
Add `zsh-listview` to your plugins list in `~/.zshrc`:
```zsh
plugins=(... zsh-listview)
```

## Keybindings

- `↓` (Down Arrow): Cycle forward through suggestions.
- `↑` (Up Arrow): Cycle backward through suggestions.
- `Cmd+L` / `Ctrl+L`: Clear screen cleanly without leftover suggestions.
