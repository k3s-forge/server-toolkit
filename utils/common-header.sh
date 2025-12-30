# Common header for all server-toolkit scripts
# This should be sourced at the beginning of each script

# Get script directory - handle both local and downloaded execution
if [[ -n "${SCRIPT_DIR:-}" ]] && [[ -n "${BASE_URL:-}" ]]; then
    # Running from bootstrap.sh, SCRIPT_DIR is already set
    TOOLKIT_ROOT="$SCRIPT_DIR"
else
    # Running standalone
    CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Determine toolkit root based on script location
    case "$CURRENT_SCRIPT_DIR" in
        */pre-reinstall)
            TOOLKIT_ROOT="$(dirname "$CURRENT_SCRIPT_DIR")"
            ;;
        */post-reinstall/*)
            TOOLKIT_ROOT="$(dirname "$(dirname "$CURRENT_SCRIPT_DIR")")"
            ;;
        */utils)
            TOOLKIT_ROOT="$(dirname "$CURRENT_SCRIPT_DIR")"
            ;;
        *)
            TOOLKIT_ROOT="$CURRENT_SCRIPT_DIR"
            ;;
    esac
    
    SCRIPT_DIR="$TOOLKIT_ROOT"
fi

# Load common functions
if [[ -f "$TOOLKIT_ROOT/utils/common.sh" ]]; then
    source "$TOOLKIT_ROOT/utils/common.sh"
else
    echo "Error: common.sh not found at $TOOLKIT_ROOT/utils/common.sh"
    echo "TOOLKIT_ROOT=$TOOLKIT_ROOT"
    echo "SCRIPT_DIR=${SCRIPT_DIR:-not set}"
    exit 1
fi

# Load i18n functions
if [[ -f "$TOOLKIT_ROOT/utils/i18n.sh" ]]; then
    source "$TOOLKIT_ROOT/utils/i18n.sh"
fi
