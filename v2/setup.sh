#!/usr/bin/env bash
# =============================================================================
# RKE2 Cluster Setup — Cilium CNI + Longhorn Storage
# =============================================================================
# Tested on: Ubuntu 20.04 / 22.04, RHEL/Rocky 8+, AMD ROCm DevCloud nodes
#
# USAGE
#   First server (init)  : sudo bash setup-rke2-cilium-longhorn.sh server --init
#   Extra server (join)  : sudo bash setup-rke2-cilium-longhorn.sh server --join <IP> <TOKEN>
#   Worker agent         : sudo bash setup-rke2-cilium-longhorn.sh agent  <IP> <TOKEN>
#
# ALL ISSUES FIXED
#   [1] node-role.kubernetes.io/* labels are kubelet-protected since k8s 1.24 →
#       removed from node-label; API server applies them automatically.
#   [2] CNI approach changed: cni:cilium (RKE2 built-in) + HelmChartConfig
#       manifest instead of cni:none + external Helm install. Eliminates the
#       "pod sandbox not found" race and the kubelet exit-status-1 crash loop.
#   [3] kubeProxyReplacement configured via HelmChartConfig (not Helm CLI).
#   [4] k8sServiceHost set to "localhost" — correct for single-node and HA.
#   [5] Stale /run/k3s/containerd socket cleaned before every start.
#   [6] cgroup version auto-detected (ROCm DevCloud nodes run cgroup v2).
#   [7] wait_for_node_ready polls actual Ready condition, not just API reachability.
#   [8] Tools (kubectl, k9s, helm) installed after RKE2 so the bundled binary
#       is available for symlinking.
#   [9] Optional cleanup prompt on re-runs so stale state doesn't block startup.
# =============================================================================

set -euo pipefail

# ─── Configurable Variables ───────────────────────────────────────────────────

RKE2_VERSION="${RKE2_VERSION:-v1.30.3+rke2r1}"
LONGHORN_VERSION="${LONGHORN_VERSION:-1.6.2}"
CLUSTER_CIDR="${CLUSTER_CIDR:-10.42.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.43.0.0/16}"
LONGHORN_REPLICAS="${LONGHORN_REPLICAS:-3}"
LONGHORN_DATA_PATH="${LONGHORN_DATA_PATH:-/var/lib/longhorn}"

# ─── Colours ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
step()    { echo -e "\n${CYAN}══════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}  $*${NC}"
            echo -e "${CYAN}══════════════════════════════════════════════════${NC}"; }

# ─── Argument Parsing ─────────────────────────────────────────────────────────

NODE_ROLE="${1:-}"   # server | agent
MODE="${2:-}"        # --init | --join | <SERVER_IP> for agent
SERVER_IP="${3:-}"   # join target IP (server --join) or TOKEN (agent)
TOKEN="${4:-}"       # cluster token (server --join only)

print_usage() {
  echo -e "
${CYAN}Usage:${NC}
  Init first server  : sudo $0 server --init
  Join extra server  : sudo $0 server --join <SERVER_IP> <TOKEN>
  Join worker agent  : sudo $0 agent  <SERVER_IP> <TOKEN>
"
  exit 1
}

[[ -z "$NODE_ROLE" ]] && print_usage
[[ "$NODE_ROLE" != "server" && "$NODE_ROLE" != "agent" ]] && print_usage
[[ $EUID -ne 0 ]] && error "This script must be run as root (sudo)."

# ─── Global env ───────────────────────────────────────────────────────────────

export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
export PATH="/var/lib/rancher/rke2/bin:${PATH}"

# ─── Helpers ──────────────────────────────────────────────────────────────────

wait_for() {
  local cmd="$1" desc="${2:-command}" retries="${3:-40}" delay="${4:-10}"
  local i=0
  until eval "$cmd" &>/dev/null; do
    ((i++))
    [[ $i -ge $retries ]] && error "Timed out waiting for: $desc"
    info "Waiting for $desc … ($i/$retries)"
    sleep "$delay"
  done
  success "$desc is ready."
}

wait_for_node_ready() {
  local retries=60 i=0
  info "Polling node Ready condition…"
  until kubectl get nodes 2>/dev/null | grep -E '\s+Ready\s+' | grep -qv 'NotReady'; do
    ((i++))
    [[ $i -ge $retries ]] && error "Node never became Ready. Run: journalctl -u rke2-server -f"
    info "Node not Ready yet ($i/$retries) — waiting 10 s…"
    sleep 10
  done
  success "Node is Ready."
}

detect_cgroup_version() {
  local fs
  fs=$(stat -fc %T /sys/fs/cgroup/ 2>/dev/null || echo "unknown")
  [[ "$fs" == "cgroup2fs" ]] && echo "v2" || echo "v1"
}

# ─── Step 1: System Prerequisites ────────────────────────────────────────────

install_prerequisites() {
  step "1/5  System prerequisites"

  if command -v apt-get &>/dev/null; then
    info "apt detected (Debian/Ubuntu)"
    apt-get update -qq
    apt-get install -y -qq \
      curl wget tar jq bash-completion \
      open-iscsi nfs-common \
      cryptsetup dmsetup lvm2 2>/dev/null || true

  elif command -v dnf &>/dev/null; then
    info "dnf detected (RHEL/Rocky/Fedora)"
    dnf install -y -q \
      curl wget tar jq bash-completion \
      iscsi-initiator-utils nfs-utils \
      cryptsetup device-mapper lvm2

  elif command -v yum &>/dev/null; then
    info "yum detected (CentOS)"
    yum install -y -q \
      curl wget tar jq bash-completion \
      iscsi-initiator-utils nfs-utils \
      cryptsetup device-mapper lvm2
  else
    warn "No recognised package manager — ensure curl, open-iscsi, nfs-utils are installed."
  fi

  # iSCSI — Longhorn requires the initiator daemon
  systemctl enable --now iscsid 2>/dev/null || true

  # Kernel modules required by Cilium and Longhorn
  for mod in overlay br_netfilter iscsi_tcp; do
    modprobe "$mod" 2>/dev/null || warn "modprobe $mod skipped (may be built-in)"
  done
  cat > /etc/modules-load.d/rke2.conf <<'EOF'
overlay
br_netfilter
iscsi_tcp
EOF

  # Sysctl
  cat > /etc/sysctl.d/99-rke2.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv6.conf.all.forwarding        = 1
fs.inotify.max_user_watches         = 524288
fs.inotify.max_user_instances       = 512
EOF
  sysctl --system -q

  # Disable swap — kubelet refuses to start otherwise
  swapoff -a
  sed -i '/\bswap\b/d' /etc/fstab 2>/dev/null || true

  # FIX [5]: clean stale containerd socket from any prior failed attempt
  rm -f /run/k3s/containerd/containerd.sock 2>/dev/null || true

  local cgv
  cgv=$(detect_cgroup_version)
  info "cgroup version: ${cgv}"

  success "Prerequisites done."
}

# ─── Step 2: Install kubectl + k9s + setup kubeconfig ───────────────────────

setup_kubeconfig() {
  local src="/etc/rancher/rke2/rke2.yaml"
  local dest="$HOME/.kube/config"

  if [[ ! -f "$src" ]]; then
    warn "RKE2 kubeconfig not found at ${src} yet — skipping copy."
    return
  fi

  mkdir -p "$HOME/.kube"
  cp "$src" "$dest"
  chmod 600 "$dest"

  # ── Export for the current shell session ────────────────────────────────────
  export KUBECONFIG="$dest"

  # ── Persist for all future logins (bash + profile) ──────────────────────────
  # Write to both .bashrc and .bash_profile / .profile so it loads whether
  # the user opens an interactive shell or a login shell.
  for rc in /root/.bashrc /root/.bash_profile /root/.profile; do
    if [[ -f "$rc" ]] || [[ "$rc" == "/root/.bashrc" ]]; then
      grep -q 'KUBECONFIG=.*\.kube/config' "$rc" 2>/dev/null && continue
      cat >> "$rc" <<RCBLOCK

# ── kubectl / RKE2 kubeconfig ───────────────────────────────────────────────
export KUBECONFIG=\$HOME/.kube/config
export PATH=/var/lib/rancher/rke2/bin:\$PATH
RCBLOCK
    fi
  done

  # ── System-wide fallback in /etc/environment ─────────────────────────────────
  # This ensures KUBECONFIG is set even for non-login, non-interactive shells
  # (e.g. systemd services, cron jobs, ssh one-liners).
  if ! grep -q 'KUBECONFIG' /etc/environment 2>/dev/null; then
    echo "KUBECONFIG=${dest}" >> /etc/environment
  fi

  success "Kubeconfig: ${src} → ${dest}"
  success "KUBECONFIG exported for this session and all future shells."
  info    "Run: kubectl get nodes"
}

install_tools() {
  step "2/5  kubectl + k9s + kubeconfig"

  # ── kubectl ────────────────────────────────────────────────────────────────
  # Prefer the RKE2-bundled binary (already the right version, no extra download)
  if [[ -f /var/lib/rancher/rke2/bin/kubectl ]]; then
    ln -sf /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
    success "kubectl → RKE2 bundle ($(kubectl version --client --short 2>/dev/null | head -1))"
  else
    info "Fetching kubectl from upstream…"
    local ver
    ver=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${ver}/bin/linux/amd64/kubectl" \
      -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl
    success "kubectl ${ver} installed."
  fi

  # ── kubeconfig → ~/.kube/config ────────────────────────────────────────────
  setup_kubeconfig

  # ── Shell aliases + completion ─────────────────────────────────────────────
  kubectl completion bash > /etc/bash_completion.d/kubectl 2>/dev/null || true
  grep -q 'alias k=' /root/.bashrc 2>/dev/null || cat >> /root/.bashrc <<'BASHRC'

# ── RKE2 / kubectl ───────────────────────────────────────────────────────────
export KUBECONFIG=$HOME/.kube/config
export PATH=/var/lib/rancher/rke2/bin:$PATH
alias k='kubectl'
alias kgp='kubectl get pods -A'
alias kgn='kubectl get nodes -o wide'
alias kgs='kubectl get svc -A'
alias kd='kubectl describe'
complete -o default -F __start_kubectl k
BASHRC

  # ── k9s via webi (non-fatal — network issues must not abort the cluster install)
  if command -v k9s &>/dev/null; then
    success "k9s already installed: $(k9s version --short 2>/dev/null | head -1)"
  else
    info "Installing k9s via webi…"
    if curl -sS https://webi.sh/k9s | sh; then
      [[ -f "$HOME/.config/envman/PATH.env" ]] &&         source "$HOME/.config/envman/PATH.env" || true
      local webi_bin="$HOME/.local/bin/k9s"
      if [[ -f "$webi_bin" ]]; then
        ln -sf "$webi_bin" /usr/local/bin/k9s
        success "k9s installed: $(k9s version --short 2>/dev/null | head -1)"
      else
        warn "k9s binary not found at $webi_bin — run manually: curl -sS https://webi.sh/k9s | sh"
      fi
      grep -q 'envman/PATH.env' /root/.bashrc 2>/dev/null ||         echo '[[ -f "$HOME/.config/envman/PATH.env" ]] && source "$HOME/.config/envman/PATH.env"'           >> /root/.bashrc
    else
      warn "k9s install via webi failed — cluster setup continues. Install manually later."
    fi
  fi
}

# ─── Step 3: Helm ─────────────────────────────────────────────────────────────

install_helm() {
  step "3/5  Helm"
  if command -v helm &>/dev/null; then
    success "Helm already present: $(helm version --short)"
    return
  fi
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  success "Helm installed: $(helm version --short)"
}

# ─── Step 4: Install RKE2 binaries ───────────────────────────────────────────

install_rke2() {
  local role="$1"
  step "4/5  RKE2 ${role} — ${RKE2_VERSION}"
  INSTALL_RKE2_VERSION="$RKE2_VERSION" \
  INSTALL_RKE2_TYPE="$role" \
    sh <(curl -sfL https://get.rke2.io)
  success "RKE2 ${role} binaries installed."
}

# ─── Step 5a: Config — first server ──────────────────────────────────────────
#
# CRITICAL DESIGN NOTES
# ─────────────────────
# FIX [1] — node-role.kubernetes.io/* labels
#   These are protected in k8s 1.24+. Kubelet rejects them with:
#   "unknown 'kubernetes.io' label … [node-role.kubernetes.io/master]"
#   The API server sets control-plane/master/etcd roles automatically on server
#   nodes. No node-label entry is needed for roles.
#
# FIX [2] — CNI approach
#   OLD (broken): cni:none → wait for cluster → Helm install Cilium externally.
#   NEW (correct): cni:cilium → RKE2 deploys its bundled Cilium Helm chart
#   automatically. We customise it via a HelmChartConfig manifest dropped into
#   /var/lib/rancher/rke2/server/manifests/ BEFORE starting RKE2.
#   This means Cilium is ready as soon as the node comes up — no CNI gap.
#
# FIX [3+4] — kubeProxyReplacement / k8sServiceHost
#   Set via the HelmChartConfig values, not Helm CLI flags.
#   k8sServiceHost:"localhost" is correct for both single-node and HA.
# ─────────────────────────────────────────────────────────────────────────────

write_config_server_init() {
  step "5/5  Writing configs (server init)"

  local node_ip
  node_ip=$(hostname -I | awk '{print $1}')

  mkdir -p /etc/rancher/rke2
  mkdir -p /var/lib/rancher/rke2/server/manifests

  # ── RKE2 main config ─────────────────────────────────────────────────────
  cat > /etc/rancher/rke2/config.yaml <<EOF
# ── RKE2 Server — cluster init ───────────────────────────────────────────────
cluster-init: true
write-kubeconfig-mode: "0644"

# CNI: use RKE2's built-in Cilium (customised via HelmChartConfig manifest)
cni: cilium
disable-kube-proxy: true

cluster-cidr: "${CLUSTER_CIDR}"
service-cidr: "${SERVICE_CIDR}"

tls-san:
  - "${node_ip}"
  - "127.0.0.1"
  - "localhost"

disable:
  - rke2-canal
  - rke2-ingress-nginx

# Kubelet args
# NOTE: Do NOT add node-role.kubernetes.io/* here — they are protected labels
#       in k8s 1.24+. The API server assigns control-plane/master roles itself.
kubelet-arg:
  - "max-pods=250"
  - "serialize-image-pulls=false"
EOF

  # ── Cilium HelmChartConfig ────────────────────────────────────────────────
  # RKE2's built-in Helm controller picks this up and applies it when it
  # deploys the bundled rke2-cilium chart. Must be in place BEFORE rke2 starts.
  cat > /var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml <<'EOF'
---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-cilium
  namespace: kube-system
spec:
  valuesContent: |-
    # Replace kube-proxy with Cilium eBPF
    kubeProxyReplacement: true

    # "localhost" hits the local API server — works for single-node and HA
    k8sServiceHost: "localhost"
    k8sServicePort: "6443"

    # Delegate pod CIDR allocation to the k8s node-ipam controller
    ipam:
      mode: kubernetes

    # Encapsulation — VXLAN is the safest default (works on any cloud/bare-metal)
    tunnelProtocol: "vxlan"

    # eBPF masquerade (replaces iptables NAT rules)
    bpf:
      masquerade: true

    # Hubble observability (UI + relay)
    hubble:
      enabled: true
      relay:
        enabled: true
      ui:
        enabled: true

    # Operator — increase to 2 once you have ≥2 nodes
    operator:
      replicas: 1

    # Ensure correct iptables/kernel state on every node boot
    nodeinit:
      enabled: true
EOF

  success "RKE2 config and Cilium HelmChartConfig written."
}

# ─── Step 5b: Config — joining server ────────────────────────────────────────

write_config_server_join() {
  local server_ip="$1" token="$2"
  step "5/5  Writing configs (server join → ${server_ip})"

  local node_ip
  node_ip=$(hostname -I | awk '{print $1}')

  mkdir -p /etc/rancher/rke2

  cat > /etc/rancher/rke2/config.yaml <<EOF
# ── RKE2 Server — join existing cluster ──────────────────────────────────────
server: "https://${server_ip}:9345"
token: "${token}"
write-kubeconfig-mode: "0644"

cni: cilium
disable-kube-proxy: true
cluster-cidr: "${CLUSTER_CIDR}"
service-cidr: "${SERVICE_CIDR}"

tls-san:
  - "${node_ip}"
  - "${server_ip}"
  - "127.0.0.1"
  - "localhost"

disable:
  - rke2-canal
  - rke2-ingress-nginx

kubelet-arg:
  - "max-pods=250"
  - "serialize-image-pulls=false"
EOF

  success "Server join config written."
}

# ─── Step 5c: Config — agent ──────────────────────────────────────────────────

write_config_agent() {
  local server_ip="$1" token="$2"
  step "5/5  Writing configs (agent → ${server_ip})"

  mkdir -p /etc/rancher/rke2

  cat > /etc/rancher/rke2/config.yaml <<EOF
# ── RKE2 Agent (worker node) ─────────────────────────────────────────────────
server: "https://${server_ip}:9345"
token: "${token}"

# FIX [1]: node-role.kubernetes.io/worker is a protected label — do NOT use it.
# Use custom labels in an allowed namespace instead.
node-label:
  - "workload-type=gpu-worker"
  - "longhorn.io/storage-node=true"

kubelet-arg:
  - "max-pods=250"
  - "serialize-image-pulls=false"
EOF

  success "Agent config written."
}

# ─── Start RKE2 service ───────────────────────────────────────────────────────

start_rke2() {
  local role="$1"
  step "★   Starting rke2-${role}.service"

  # FIX [5]: remove stale containerd socket that causes
  # "dial unix /run/k3s/containerd/containerd.sock: connect: no such file or directory"
  rm -f /run/k3s/containerd/containerd.sock 2>/dev/null || true

  systemctl daemon-reload
  systemctl enable "rke2-${role}.service"
  systemctl restart "rke2-${role}.service"

  success "rke2-${role}.service started."

  if [[ "$role" == "server" ]]; then
    info "Waiting 20 s for API server to initialise…"
    sleep 20

    # Symlink kubectl (binaries now extracted by RKE2)
    ln -sf /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl 2>/dev/null || true
    export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"

    wait_for "kubectl cluster-info" "Kubernetes API server" 40 10

    # FIX [7]: poll actual node Ready condition
    wait_for_node_ready

    # Copy kubeconfig to ~/.kube/config now that cluster is confirmed up
    setup_kubeconfig
  fi
}

# ─── Install Longhorn ─────────────────────────────────────────────────────────

install_longhorn() {
  step "★   Longhorn v${LONGHORN_VERSION}"

  export KUBECONFIG="$HOME/.kube/config"

  # ── Guard: helm must be present ─────────────────────────────────────────────
  if ! command -v helm &>/dev/null; then
    error "helm not found — run install_helm() first."
  fi

  # ── Guard: API server must be reachable ─────────────────────────────────────
  if ! kubectl cluster-info &>/dev/null; then
    error "Cannot reach API server. Check: export KUBECONFIG=/etc/rancher/rke2/rke2.yaml"
  fi

  # ── Auto-detect replica count based on node count ───────────────────────────
  local node_count
  node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  local replicas="${LONGHORN_REPLICAS}"
  if [[ "$node_count" -lt "$replicas" ]]; then
    warn "Only ${node_count} node(s) found — reducing Longhorn replicas to ${node_count} (from ${replicas})"
    replicas="$node_count"
  fi

  mkdir -p "${LONGHORN_DATA_PATH}"

  helm repo add longhorn https://charts.longhorn.io --force-update
  helm repo update longhorn

  kubectl create namespace longhorn-system 2>/dev/null || true

  info "Installing Longhorn ${LONGHORN_VERSION} with ${replicas} replica(s)…"

  helm upgrade --install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --version "${LONGHORN_VERSION}" \
    --set defaultSettings.defaultReplicaCount="${replicas}" \
    --set defaultSettings.defaultDataPath="${LONGHORN_DATA_PATH}" \
    --set defaultSettings.storageOverProvisioningPercentage=200 \
    --set defaultSettings.storageMinimalAvailablePercentage=10 \
    --set defaultSettings.replicaSoftAntiAffinity=true \
    --set defaultSettings.replicaAutoBalance=best-effort \
    --set defaultSettings.snapshotDataIntegrity=fast-check \
    --set defaultSettings.autoSalvage=true \
    --set defaultSettings.autoDeletePodWhenVolumeDetachedUnexpectedly=true \
    --set persistence.defaultClassReplicaCount="${replicas}" \
    --set persistence.defaultFsType=ext4 \
    --set ingress.enabled=false \
    --set longhornUI.replicas=1 \
    --wait --timeout 10m

  # Verify the release actually landed
  if ! helm status longhorn -n longhorn-system &>/dev/null; then
    error "Longhorn helm release not found after install — check: helm list -A"
  fi

  kubectl patch storageclass longhorn \
    -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

  success "Longhorn ${LONGHORN_VERSION} installed (${replicas} replica(s)) — default StorageClass set."

  info "Longhorn pods:"
  kubectl get pods -n longhorn-system --no-headers | awk '{print "  "$1, $3}'
}

# ─── Clean up a broken previous install ───────────────────────────────────────

cleanup_previous() {
  warn "Removing previous RKE2 installation…"
  systemctl stop rke2-server rke2-agent 2>/dev/null || true
  /usr/local/bin/rke2-uninstall.sh 2>/dev/null || true
  rm -rf /var/lib/rancher/rke2 /run/k3s /etc/rancher/rke2 /var/lib/rke2
  systemctl daemon-reload
  success "Cleanup done."
}

# ─── Print summary ────────────────────────────────────────────────────────────

print_join_info() {
  export KUBECONFIG="$HOME/.kube/config"
  local token ip
  token=$(cat /var/lib/rancher/rke2/server/node-token 2>/dev/null || echo "<not-yet-available>")
  ip=$(hostname -I | awk '{print $1}')

  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║         Cluster bootstrap complete!  🎉                  ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}► Tools installed:${NC}"
  echo -e "  kubectl : $(kubectl version --client 2>/dev/null | grep 'Client Version' | awk '{print $3}' || echo 'check /usr/local/bin/kubectl')"
  echo -e "  k9s     : $(k9s version --short 2>/dev/null | head -1 || echo 'check /usr/local/bin/k9s')"
  echo -e "  helm    : $(helm version --short 2>/dev/null || echo 'check /usr/local/bin/helm')"
  echo ""
  echo -e "${CYAN}► Join an extra control-plane node:${NC}"
  echo -e "  sudo $0 server --join ${ip} ${token}"
  echo ""
  echo -e "${CYAN}► Join a worker node:${NC}"
  echo -e "  sudo $0 agent ${ip} ${token}"
  echo ""
  echo -e "${CYAN}► Kubeconfig locations:${NC}"
  echo -e "  On this node : ~/.kube/config  (ready to use — KUBECONFIG already set)"
  echo -e "  Original     : /etc/rancher/rke2/rke2.yaml"
  echo -e "${CYAN}► Copy to your laptop:${NC}"
  echo -e "  scp root@${ip}:~/.kube/config ~/.kube/config"
  echo ""
  echo -e "${CYAN}► Nodes:${NC}"
  kubectl get nodes -o wide 2>/dev/null || true
  echo ""
  echo -e "${CYAN}► Cilium pods:${NC}"
  kubectl get pods -n kube-system -l k8s-app=cilium --no-headers 2>/dev/null | \
    awk '{print $1, $3}' | column -t || true
  echo ""
  echo -e "${CYAN}► Longhorn pods:${NC}"
  kubectl get pods -n longhorn-system --no-headers 2>/dev/null | \
    awk '{print $1, $3}' | column -t || true
}

# ─── Banner ───────────────────────────────────────────────────────────────────

print_banner() {
  echo -e "\n${CYAN}"
  echo "  ██████╗ ██╗  ██╗███████╗██████╗ "
  echo "  ██╔══██╗██║ ██╔╝██╔════╝╚════██╗"
  echo "  ██████╔╝█████╔╝ █████╗   █████╔╝"
  echo "  ██╔══██╗██╔═██╗ ██╔══╝  ██╔═══╝ "
  echo "  ██║  ██║██║  ██╗███████╗███████╗"
  echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝"
  echo -e "    + Cilium CNI  +  Longhorn Storage${NC}\n"
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
  print_banner

  case "$NODE_ROLE" in

    server)
      case "$MODE" in

        --init)
          if [[ -d /var/lib/rancher/rke2 ]]; then
            warn "Previous RKE2 data found at /var/lib/rancher/rke2"
            read -rp "  Clean it up and reinstall? [y/N] " ans
            [[ "${ans,,}" == "y" ]] && cleanup_previous
          fi

          # Each step is explicit — failure prints which step failed
          info "Step [1/6] Prerequisites"
          install_prerequisites     || error "FAILED: install_prerequisites"

          info "Step [2/6] Install RKE2 binaries"
          install_rke2 server       || error "FAILED: install_rke2"

          info "Step [3/6] Write configs (RKE2 + Cilium HelmChartConfig)"
          write_config_server_init  || error "FAILED: write_config_server_init"

          info "Step [4/6] Start RKE2 + wait for node Ready"
          start_rke2 server         || error "FAILED: start_rke2"

          info "Step [5/6] Install tools (kubectl, k9s, helm)"
          install_tools             || warn  "WARNING: install_tools had errors (non-fatal)"
          install_helm              || error "FAILED: install_helm"

          info "Step [6/6] Install Longhorn"
          install_longhorn          || error "FAILED: install_longhorn"

          print_join_info
          ;;

        --join)
          [[ -z "$SERVER_IP" || -z "$TOKEN" ]] && print_usage
          install_prerequisites
          install_rke2 server
          write_config_server_join "$SERVER_IP" "$TOKEN"
          start_rke2 server
          install_tools
          success "Server node joined the cluster."
          ;;

        *)
          print_usage
          ;;
      esac
      ;;

    agent)
      # For agents: $MODE = SERVER_IP, $SERVER_IP = TOKEN
      [[ -z "$MODE" || -z "$SERVER_IP" ]] && print_usage
      install_prerequisites
      install_rke2 agent
      write_config_agent "$MODE" "$SERVER_IP"
      start_rke2 agent
      success "Agent node joined the cluster."
      ;;

    *)
      print_usage
      ;;
  esac
}

main "$@"
