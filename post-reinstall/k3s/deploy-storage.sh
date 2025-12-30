#!/usr/bin/env bash
# deploy-storage.sh - K3s storage deployment
# Deploys MinIO or Garage for S3-compatible storage

set -Eeuo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load common functions and i18n
source "$TOOLKIT_ROOT/utils/common.sh"
source "$TOOLKIT_ROOT/utils/i18n.sh"

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

# Deploy MinIO
deploy_minio() {
    local storage_size="${1:-10Gi}"
    local root_user="${2:-admin}"
    local root_password="${3:-changeme123456}"
    
    i18n_info "info" "Deploying MinIO (storage: $storage_size)"
    
    # Create manifest
    local manifest=$(cat <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: minio

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc
  namespace: minio
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $storage_size
  storageClassName: local-path

---
apiVersion: v1
kind: Secret
metadata:
  name: minio-secret
  namespace: minio
type: Opaque
stringData:
  MINIO_ROOT_USER: "$root_user"
  MINIO_ROOT_PASSWORD: "$root_password"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /data
        - --console-address
        - ":9001"
        env:
        - name: MINIO_ROOT_USER
          valueFrom:
            secretKeyRef:
              name: minio-secret
              key: MINIO_ROOT_USER
        - name: MINIO_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: minio-secret
              key: MINIO_ROOT_PASSWORD
        ports:
        - containerPort: 9000
          name: api
        - containerPort: 9001
          name: console
        volumeMounts:
        - name: data
          mountPath: /data
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: minio-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  selector:
    app: minio
  ports:
  - name: api
    port: 9000
    targetPort: 9000
  - name: console
    port: 9001
    targetPort: 9001
  type: ClusterIP
EOF
)
    
    # Apply manifest
    if echo "$manifest" | kubectl apply -f -; then
        i18n_success "completed" "MinIO deployment"
        
        echo ""
        echo "$(msg 'info') MinIO deployed successfully"
        echo "  - Namespace: minio"
        echo "  - API Port: 9000"
        echo "  - Console Port: 9001"
        echo "  - Storage: $storage_size"
        echo "  - Root User: $root_user"
        echo "  - Root Password: $root_password"
        echo ""
        echo "$(msg 'warning') Please change the default password!"
        echo ""
        echo "Access MinIO console:"
        echo "  kubectl port-forward -n minio svc/minio 9001:9001"
        echo "  Then open: http://localhost:9001"
    else
        i18n_error "failed" "MinIO deployment"
        return 1
    fi
}

# Deploy Garage
deploy_garage() {
    local storage_size="${1:-50Gi}"
    local replicas="${2:-3}"
    
    i18n_info "info" "Deploying Garage (storage: $storage_size, replicas: $replicas)"
    
    # Create manifest
    local manifest=$(cat <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: garage

---
apiVersion: v1
kind: Secret
metadata:
  name: garage-config
  namespace: garage
type: Opaque
stringData:
  rpc-secret: "$(openssl rand -hex 32)"
  admin-token: "$(openssl rand -hex 32)"

---
apiVersion: v1
kind: Service
metadata:
  name: garage-rpc
  namespace: garage
spec:
  clusterIP: None
  ports:
  - name: rpc
    port: 3901
    targetPort: 3901
  selector:
    app: garage

---
apiVersion: v1
kind: Service
metadata:
  name: garage-s3
  namespace: garage
spec:
  type: ClusterIP
  ports:
  - name: s3-api
    port: 3900
    targetPort: 3900
  - name: admin
    port: 3903
    targetPort: 3903
  selector:
    app: garage

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: garage-config
  namespace: garage
data:
  garage.toml: |
    metadata_dir = "/meta"
    data_dir = "/data"
    replication_mode = "2"
    compression_level = 1
    rpc_bind_addr = "[::]:3901"
    
    [s3_api]
    s3_region = "garage"
    api_bind_addr = "[::]:3900"
    root_domain = ".s3.garage"
    
    [admin]
    api_bind_addr = "[::]:3903"

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: garage
  namespace: garage
spec:
  serviceName: garage-rpc
  replicas: $replicas
  selector:
    matchLabels:
      app: garage
  template:
    metadata:
      labels:
        app: garage
    spec:
      containers:
      - name: garage
        image: dxflrs/garage:v0.9.4
        ports:
        - containerPort: 3900
          name: s3-api
        - containerPort: 3901
          name: rpc
        - containerPort: 3903
          name: admin
        env:
        - name: GARAGE_RPC_SECRET
          valueFrom:
            secretKeyRef:
              name: garage-config
              key: rpc-secret
        - name: GARAGE_ADMIN_TOKEN
          valueFrom:
            secretKeyRef:
              name: garage-config
              key: admin-token
        volumeMounts:
        - name: data
          mountPath: /data
        - name: meta
          mountPath: /meta
        - name: config
          mountPath: /etc/garage.toml
          subPath: garage.toml
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: config
        configMap:
          name: garage-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: local-path
      resources:
        requests:
          storage: $storage_size
  - metadata:
      name: meta
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: local-path
      resources:
        requests:
          storage: 5Gi
EOF
)
    
    # Apply manifest
    if echo "$manifest" | kubectl apply -f -; then
        i18n_success "completed" "Garage deployment"
        
        echo ""
        echo "$(msg 'info') Garage deployed successfully"
        echo "  - Namespace: garage"
        echo "  - Replicas: $replicas"
        echo "  - Storage per node: $storage_size"
        echo "  - S3 API Port: 3900"
        echo "  - Admin Port: 3903"
        echo ""
        echo "$(msg 'info') Initialize Garage cluster:"
        echo "  kubectl exec -n garage garage-0 -- garage status"
        echo "  kubectl exec -n garage garage-0 -- garage layout show"
    else
        i18n_error "failed" "Garage deployment"
        return 1
    fi
}

# Show storage status
show_storage_status() {
    print_title "Storage Status"
    
    echo "MinIO:"
    if kubectl get namespace minio >/dev/null 2>&1; then
        kubectl get pods,svc,pvc -n minio 2>/dev/null || echo "  No resources found"
    else
        echo "  Not deployed"
    fi
    echo ""
    
    echo "Garage:"
    if kubectl get namespace garage >/dev/null 2>&1; then
        kubectl get pods,svc,pvc -n garage 2>/dev/null || echo "  No resources found"
    else
        echo "  Not deployed"
    fi
    echo ""
}

# Interactive deployment
deploy_interactive() {
    echo ""
    echo "K3s Storage Deployment"
    echo ""
    echo "Storage Options:"
    echo "  1. MinIO - Simple S3-compatible storage (single node)"
    echo "  2. Garage - Distributed S3-compatible storage (multi-node)"
    echo "  3. Show Status"
    echo ""
    read -r -p "Select option [1-3]: " choice
    
    case "$choice" in
        1)
            echo ""
            echo "MinIO Configuration"
            echo ""
            read -r -p "Storage size (default: 10Gi): " storage
            storage="${storage:-10Gi}"
            
            read -r -p "Root user (default: admin): " user
            user="${user:-admin}"
            
            read -r -s -p "Root password (default: changeme123456): " password
            password="${password:-changeme123456}"
            echo ""
            
            deploy_minio "$storage" "$user" "$password"
            ;;
        2)
            echo ""
            echo "Garage Configuration"
            echo ""
            read -r -p "Storage size per node (default: 50Gi): " storage
            storage="${storage:-50Gi}"
            
            read -r -p "Number of replicas (default: 3): " replicas
            replicas="${replicas:-3}"
            
            deploy_garage "$storage" "$replicas"
            ;;
        3)
            show_storage_status
            ;;
        *)
            i18n_error "failed" "Invalid option"
            exit 1
            ;;
    esac
}

# Main function
main() {
    local action="${1:-interactive}"
    local storage_size="${2:-}"
    local param3="${3:-}"
    
    print_title "K3s Storage Deployment"
    
    # Check kubectl
    check_kubectl
    
    case "$action" in
        minio)
            storage_size="${storage_size:-10Gi}"
            local user="${param3:-admin}"
            i18n_info "starting" "MinIO deployment"
            
            # Generate random password if not provided
            local password
            if [[ -z "${4:-}" ]]; then
                password="$(openssl rand -hex 16)"
                echo "$(msg 'info') Generated password: $password"
            else
                password="${4}"
            fi
            
            deploy_minio "$storage_size" "$user" "$password"
            i18n_success "completed" "MinIO deployment"
            ;;
        garage)
            storage_size="${storage_size:-50Gi}"
            local replicas="${param3:-3}"
            i18n_info "starting" "Garage deployment"
            deploy_garage "$storage_size" "$replicas"
            i18n_success "completed" "Garage deployment"
            ;;
        interactive)
            deploy_interactive
            ;;
        status|show)
            show_storage_status
            ;;
        *)
            echo "Usage: $0 {minio|garage|interactive|status} [storage-size] [user/replicas] [password]"
            echo ""
            echo "Actions:"
            echo "  minio        - Deploy MinIO"
            echo "  garage       - Deploy Garage"
            echo "  interactive  - Interactive deployment (default)"
            echo "  status       - Show storage status"
            echo ""
            echo "Examples:"
            echo "  $0 minio 20Gi admin mypassword"
            echo "  $0 garage 100Gi 3"
            echo "  $0 interactive"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
