#!/usr/bin/env bash
# setup-upgrade-controller.sh - System Upgrade Controller deployment
# Deploys Rancher System Upgrade Controller for automated K3s upgrades

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

# System Upgrade Controller URL
SUC_MANIFEST_URL="https://github.com/rancher/system-upgrade-controller/releases/latest/download/system-upgrade-controller.yaml"

# Check kubectl
check_kubectl() {
    if ! has_cmd kubectl; then
        i18n_error "failed" "kubectl not found, please install K3s first"
        return 1
    fi
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        i18n_error "failed" "Cannot connect to K3s cluster"
        return 1
    fi
    
    i18n_success "completed" "kubectl connectivity check"
}

# Deploy System Upgrade Controller
deploy_controller() {
    local sudo_cmd
    sudo_cmd=$(get_sudo)
    
    i18n_info "info" "Deploying System Upgrade Controller"
    
    # Apply manifest
    if kubectl apply -f "$SUC_MANIFEST_URL"; then
        i18n_success "completed" "System Upgrade Controller deployment"
    else
        i18n_error "failed" "System Upgrade Controller deployment"
        return 1
    fi
    
    # Wait for pod to be ready
    i18n_info "info" "Waiting for controller pod to be ready..."
    if kubectl wait --for=condition=ready pod \
        -l upgrade.cattle.io/controller=system-upgrade-controller \
        -n system-upgrade \
        --timeout=300s 2>/dev/null; then
        i18n_success "running" "System Upgrade Controller pod"
    else
        i18n_warn "warning" "Timeout waiting for pod, check status manually"
    fi
}

# Deploy K3s upgrade plan
deploy_upgrade_plan() {
    local target_version="${1:-latest}"
    
    i18n_info "info" "Deploying K3s upgrade plan (version: $target_version)"
    
    # Create upgrade plan manifest
    local manifest=$(cat <<EOF
---
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-server
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: Exists
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
  version: $target_version

---
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-agent
  namespace: system-upgrade
spec:
  concurrency: 2
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
  prepare:
    args:
    - prepare
    - k3s-server
    image: rancher/k3s-upgrade
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
  version: $target_version
EOF
)
    
    # Apply manifest
    if echo "$manifest" | kubectl apply -f -; then
        i18n_success "completed" "K3s upgrade plan deployment"
    else
        i18n_error "failed" "K3s upgrade plan deployment"
        return 1
    fi
}

# Show upgrade status
show_upgrade_status() {
    print_title "System Upgrade Controller Status"
    
    echo "Controller Pod:"
    kubectl get pods -n system-upgrade -l upgrade.cattle.io/controller=system-upgrade-controller 2>/dev/null || echo "  Not found"
    echo ""
    
    echo "Upgrade Plans:"
    kubectl get plans -n system-upgrade 2>/dev/null || echo "  No plans deployed"
    echo ""
    
    echo "Upgrade Jobs:"
    kubectl get jobs -n system-upgrade 2>/dev/null || echo "  No jobs running"
    echo ""
}

# Interactive deployment
deploy_interactive() {
    echo ""
    echo "System Upgrade Controller Deployment"
    echo ""
    
    # Check if already deployed
    if kubectl get deployment system-upgrade-controller -n system-upgrade >/dev/null 2>&1; then
        echo "$(msg 'info') System Upgrade Controller is already deployed"
        echo ""
        if ! ask_yes_no "Redeploy?" "n"; then
            i18n_info "skipped" "System Upgrade Controller deployment"
            return 0
        fi
    fi
    
    # Deploy controller
    deploy_controller
    
    echo ""
    echo "K3s Upgrade Plan Configuration"
    echo ""
    echo "$(msg 'info') Target version options:"
    echo "  - latest: Always upgrade to latest stable version"
    echo "  - v1.28.5+k3s1: Specific version (recommended for production)"
    echo ""
    
    if ask_yes_no "Deploy K3s upgrade plan?" "y"; then
        read -r -p "Enter target version (default: latest): " version
        version="${version:-latest}"
        
        deploy_upgrade_plan "$version"
        
        echo ""
        echo "$(msg 'info') Upgrade plan deployed"
        echo "  - Server nodes: Serial upgrade (concurrency: 1)"
        echo "  - Agent nodes: Parallel upgrade (concurrency: 2)"
        echo "  - Target version: $version"
        echo ""
        
        if [[ "$version" == "latest" ]]; then
            echo "$(msg 'warning') Using 'latest' version"
            echo "  - Automatic upgrades enabled"
            echo "  - For production, consider using specific version"
            echo ""
            echo "To change to specific version:"
            echo "  kubectl patch plan k3s-server -n system-upgrade --type merge -p '{\"spec\":{\"version\":\"v1.28.5+k3s1\"}}'"
            echo "  kubectl patch plan k3s-agent -n system-upgrade --type merge -p '{\"spec\":{\"version\":\"v1.28.5+k3s1\"}}'"
        fi
    else
        i18n_info "skipped" "K3s upgrade plan deployment"
        echo ""
        echo "$(msg 'info') You can deploy upgrade plan later:"
        echo "  bash $0 upgrade-plan [version]"
    fi
    
    echo ""
    show_upgrade_status
}

# Main function
main() {
    local action="${1:-interactive}"
    local version="${2:-latest}"
    
    print_title "System Upgrade Controller"
    
    # Check kubectl
    check_kubectl
    
    case "$action" in
        controller)
            i18n_info "starting" "System Upgrade Controller deployment"
            deploy_controller
            i18n_success "completed" "System Upgrade Controller deployment"
            ;;
        upgrade-plan)
            i18n_info "starting" "K3s upgrade plan deployment"
            deploy_upgrade_plan "$version"
            i18n_success "completed" "K3s upgrade plan deployment"
            ;;
        all|interactive)
            deploy_interactive
            ;;
        status|show)
            show_upgrade_status
            ;;
        *)
            echo "Usage: $0 {controller|upgrade-plan|all|status} [version]"
            echo ""
            echo "Actions:"
            echo "  controller    - Deploy System Upgrade Controller only"
            echo "  upgrade-plan  - Deploy K3s upgrade plan only"
            echo "  all           - Deploy controller and upgrade plan (default)"
            echo "  status        - Show upgrade status"
            echo ""
            echo "Examples:"
            echo "  $0 all"
            echo "  $0 controller"
            echo "  $0 upgrade-plan v1.28.5+k3s1"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
