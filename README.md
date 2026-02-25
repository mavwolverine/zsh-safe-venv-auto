# zsh-safe-venv-auto

A security-aware ZSH plugin that automatically activates and deactivates Python virtual environments as you navigate directories, with built-in protection against untrusted environments.

## Features

- 🐍 **Automatic activation** - Activates venv when entering project directories
- 🔒 **Security first** - Prompts before activating unknown virtual environments
- 📁 **Smart discovery** - Searches parent directories for `venv` or `.venv` folders
- ✅ **Trust management** - Whitelist/blocklist system for venv approval
- 🚫 **Malware protection** - Prevents execution of potentially malicious activation scripts

## Why This Plugin?

Unlike other auto-activation plugins, this adds a critical security layer. When you clone a repository or enter an unfamiliar project, it prompts you to trust, block, or skip the venv before activation - protecting you from potentially malicious code in activation scripts.

**What it does:** Protects you from automatically activating untrusted Python virtual environments.

**What it doesn't do:** Does not secure the virtual environment itself or scan packages for vulnerabilities.

## Installation

### Oh My Zsh

```bash
git clone https://github.com/mavwolverine/zsh-safe-venv-auto ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-safe-venv-auto
```

Add to your `.zshrc`:
```bash
plugins=(... zsh-safe-venv-auto)
```

### Manual

Clone the repository:
```bash
git clone https://github.com/mavwolverine/zsh-safe-venv-auto ~/.zsh/zsh-safe-venv-auto
```

Add to your `.zshrc`:
```bash
source ~/.zsh/zsh-safe-venv-auto/zsh-safe-venv-auto.plugin.zsh
```

### Antidote

Add to your `.zsh_plugins.txt`:
```
mavwolverine/zsh-safe-venv-auto
```

### Zinit

```bash
zinit light mavwolverine/zsh-safe-venv-auto
```

## Usage

Simply navigate to a directory containing a `venv` or `.venv` folder. The plugin will:

1. **First time** - Prompt you to trust, block, or skip the venv
2. **Trusted venvs** - Automatically activate without prompting
3. **Blocked venvs** - Never activate (won't ask again)
4. **Skipped venvs** - Ask again next time

### Security Management

Manage trusted and blocked virtual environments:

```bash
# Check current lists
venv-security list

# Trust a venv
venv-security trust /path/to/venv

# Block a venv
venv-security block /path/to/venv

# Remove from both lists
venv-security remove /path/to/venv
```

Short alias available: `vnvsec`

### Example Workflow

```bash
$ cd ~/projects/new-project
🔒 Unknown virtual environment detected:
   /Users/you/projects/new-project/venv

Trust and activate this venv? [y/N/block] y
✓ Added to trusted list
🐍 Activated virtual environment new-project.

$ cd ..
🔒 Deactivated virtual environment new-project.
```

## Configuration

Configuration is stored in `~/.config/zsh-safe-venv-auto/config.json`:

```json
{
  "trusted": [
    "/Users/you/projects/my-project/venv"
  ],
  "blocked": [
    "/Users/you/sketchy-repo/.venv"
  ]
}
```

## How It Works

- Hooks into ZSH's `chpwd()` function (runs on directory change)
- Searches up the directory tree for virtual environments
- Prefers `venv` over `.venv` if both exist
- Checks security status before activation
- Normalizes paths to handle symlinks correctly

## Requirements

- ZSH shell
- Python 3 (recommended for security features)
  - If `python3` command is not available, the plugin will still work but security checks will be disabled with a warning

## Credits

Based on the excellent work by [Michael Kennedy](https://mkennedy.codes):
- Blog post: [Always activate the venv (a shell script)](https://mkennedy.codes/posts/always-activate-the-venv-a-shell-script/)
- Original gist: [mikeckennedy/010a96dc6a406242d5b49d12e5d51c22](https://gist.github.com/mikeckennedy/010a96dc6a406242d5b49d12e5d51c22)

This plugin packages his security-aware auto-activation scripts into a standard ZSH plugin format for easier installation and management.

## License

MIT

## Contributing

Contributions welcome! Please open an issue or submit a pull request.
