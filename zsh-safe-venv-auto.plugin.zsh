# Virtual Environment Auto-Activation
# ===================================
# Automatically activates/deactivates Python virtual environments
# when changing directories
# See full write up at https://mkennedy.codes/posts/always-activate-the-venv-a-shell-script/

# Get plugin directory
local PLUGIN_DIR="${0:A:h}"
local SECURITY_SCRIPT="${PLUGIN_DIR}/bin/venv-security.py"

# Check for Python availability
local PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
fi

# Security check function
_venv_security_check() {
    local venv_path="$1"
    
    if [[ -z "$PYTHON_CMD" ]]; then
        echo "⚠️  Warning: Python not found. Security checks disabled."
        return 0  # Fail open - allow activation without security
    fi
    
    "$PYTHON_CMD" "$SECURITY_SCRIPT" check "$venv_path"
}

# Auto-activate virtual environment for any project with a venv directory
function chpwd() {
    # Function to find venv directory in current path or parent directories
    # Prefers 'venv' over '.venv' if both exist
    local find_venv() {
        local dir="$PWD"
        while [[ "$dir" != "/" ]]; do
            if [[ -d "$dir/venv" && -f "$dir/venv/bin/activate" ]]; then
                echo "$dir/venv"
                return 0
            elif [[ -d "$dir/.venv" && -f "$dir/.venv/bin/activate" ]]; then
                echo "$dir/.venv"
                return 0
            fi
            dir="$(dirname "$dir")"
        done
        return 1
    }

    local venv_path
    venv_path=$(find_venv)

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
                source "$venv_path/bin/activate"
                local project_name=$(basename "$(dirname "$venv_path")")
                echo "🐍 Activated virtual environment \033[95m$project_name\033[0m."
            fi
        fi
    else
        # No venv found, deactivate if we have one active
        if [[ -n "${VIRTUAL_ENV:-}" ]] && type deactivate >/dev/null 2>&1; then
            local project_name=$(basename "$(dirname "${VIRTUAL_ENV}")")
            deactivate
            echo "🔒 Deactivated virtual environment \033[95m$project_name\033[0m."
        elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
            # VIRTUAL_ENV is set but deactivate function is not available
            # This can happen when opening a new shell with VIRTUAL_ENV from previous session
            unset VIRTUAL_ENV
        fi
    fi
}

# Venv security management aliases
if [[ -n "$PYTHON_CMD" ]]; then
    alias venv-security="$PYTHON_CMD $SECURITY_SCRIPT"
    alias vnvsec="$PYTHON_CMD $SECURITY_SCRIPT"
else
    alias venv-security="echo 'Error: Python not found. Cannot manage venv security.'"
    alias vnvsec="echo 'Error: Python not found. Cannot manage venv security.'"
fi

# Run the chpwd function when the shell starts
# Suppress output on initial load to avoid interfering with instant prompt
if [[ -o interactive ]]; then
    {
        chpwd
    } &>/dev/null
fi
