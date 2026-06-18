# Virtual Environment Auto-Activation
# ===================================
# Automatically activates/deactivates Python virtual environments
# when changing directories
# See full write up at https://mkennedy.codes/posts/always-activate-the-venv-a-shell-script/

# Plugin configuration (single global associative array)
typeset -gA _SAFE_VENV
_SAFE_VENV[plugin_dir]="${0:A:h}"
_SAFE_VENV[security_script]="${_SAFE_VENV[plugin_dir]}/bin/venv-security.py"
_SAFE_VENV[python_cmd]=""
if command -v python3 >/dev/null 2>&1; then
    _SAFE_VENV[python_cmd]="python3"
elif command -v python >/dev/null 2>&1; then
    _SAFE_VENV[python_cmd]="python"
fi

# Security check function
_venv_security_check() {
    local venv_path="$1"
    
    if [[ -z "${_SAFE_VENV[python_cmd]}" ]]; then
        echo "⚠️  Warning: Python not found. Security checks disabled."
        return 0  # Fail open - allow activation without security
    fi
    
    "${_SAFE_VENV[python_cmd]}" "${_SAFE_VENV[security_script]}" check "$venv_path"
}

# Auto-activate virtual environment for any project with a venv directory
function _safe_chpwd() {
    # Find venv directory in current path or parent directories
    # Prefers 'venv' over '.venv' if both exist
    local venv_path=""
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/venv" && -f "$dir/venv/bin/activate" ]]; then
            venv_path="$dir/venv"
            break
        elif [[ -d "$dir/.venv" && -f "$dir/.venv/bin/activate" ]]; then
            venv_path="$dir/.venv"
            break
        fi
        dir="$(dirname "$dir")"
    done

    if [[ -n "$venv_path" ]]; then
        # Normalize paths for comparison (handles symlinks and path differences)
        # Use zsh :A modifier to resolve paths without triggering chpwd recursively
        local normalized_venv_path="${venv_path:A}"
        local normalized_current_venv=""
        if [[ -n "${VIRTUAL_ENV:-}" ]]; then
            normalized_current_venv="${VIRTUAL_ENV:A}"
        fi

        # We found a venv, check if it's already active
        if [[ "$normalized_current_venv" != "$normalized_venv_path" ]]; then
            # Deactivate current venv if different
            if [[ -n "${VIRTUAL_ENV:-}" ]] && type deactivate >/dev/null 2>&1; then
                deactivate
            fi

            # Security check: only activate trusted venvs
            if _venv_security_check "$normalized_venv_path"; then
                source "$normalized_venv_path/bin/activate"
                local project_name=$(basename "$(dirname "$normalized_venv_path")")
                print "🐍 Activated virtual environment \e[95m$project_name\e[0m."
            fi
        fi
    else
        # No venv found, deactivate if we have one active
        if [[ -n "${VIRTUAL_ENV:-}" ]] && type deactivate >/dev/null 2>&1; then
            local project_name=$(basename "$(dirname "${VIRTUAL_ENV}")")
            deactivate
            print "🔒 Deactivated virtual environment \e[95m$project_name\e[0m."
        elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
            # VIRTUAL_ENV is set but deactivate function is not available
            # This can happen when opening a new shell with VIRTUAL_ENV from previous session
            unset VIRTUAL_ENV
        fi
    fi
}

# Venv security management aliases
if [[ -n "${_SAFE_VENV[python_cmd]}" ]]; then
    alias venv-security="${_SAFE_VENV[python_cmd]} ${_SAFE_VENV[security_script]}"
    alias vnvsec="${_SAFE_VENV[python_cmd]} ${_SAFE_VENV[security_script]}"
else
    alias venv-security="echo 'Error: Python not found. Cannot manage venv security.'"
    alias vnvsec="echo 'Error: Python not found. Cannot manage venv security.'"
fi

# Register chpwd hook (doesn't override other plugins' chpwd hooks)
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _safe_chpwd

# Run on shell start; only activates already-trusted venvs silently
if [[ -o interactive ]]; then
    {
        _safe_chpwd
    } &>/dev/null
fi
