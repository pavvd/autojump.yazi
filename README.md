# autojump.yazi
Change current directory via autojump.
## Installation

```bash
$ ya pack -a pavvd/autojump
```

## Requirements

- [autojump](https://github.com/wting/autojump)

## Usage

Add this at the end of ~/.config/yazi/keymap.toml.
You can change "s" to preferred key.

```toml
[[manager.prepend_keymap]]
on   = ["s"] #Multi key hotkey looks like this [ "z", "j" ]
run  = "plugin autojump"
desc = "Change directory using autojump"
```
