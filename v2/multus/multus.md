# Multus CNI

Multus CNI is a Container Network Interface plugin for Kubernetes that enables attaching multiple network interfaces to pods. By default, each Kubernetes pod has one network interface. Multus acts as a "meta-plugin" — a CNI plugin that can call multiple other CNI plugins — enabling multi-homed pods.

## Role of Multus CNI

- Enables multi-interface support as a supplementary layer in a container network
- Attaches multiple network interfaces to pods in Kubernetes
- Acts as an intermediary between the container runtime and CNI plugins
- Is dependent on other network plugins (Flannel, Calico, Cilium, Weave) as the primary CNI
- Allows attaching DPDK/SRIOV interfaces to pods for network-intensive workloads

## Installation

Multus requires a primary CNI plugin (your "default network") installed first.
```bash
# Thick plugin (recommended for most environments)
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml

# Thin plugin (resource-constrained environments)
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml
```

### Thick vs Thin Plugin

| Feature | Thin Plugin | Thick Plugin (Multus 4.0+) |
|---------|-------------|---------------------------|
| Architecture | Single binary | Client/server (multus-daemon & multus-shim) |
| Deployment | Standard CNI | Local agent on all nodes |
| Additional Features | None | Supports metrics |
| Resource Consumption | Lower | Higher |
| Recommendation | Resource-constrained | Most environments ✅ |

## Post-Installation Verification
```bash
# Check config file was created
ls -l /etc/cni/net.d/00-multus.conf

# Read the config
cat /etc/cni/net.d/00-multus.conf | jq .

# Check current network details
ifconfig
route -n

# List CNI binaries available
ll /opt/cni/bin
```

## Secondary CNI Plugin Comparison

| Scenario | Recommended Plugin | Reason |
|----------|-------------------|--------|
| General purpose, VM-like networking | **Macvlan** (bridge mode) | Most flexible, unique identity, common in bare-metal |
| Cloud environments (AWS, GCP, Azure) | **IPvlan** (L3 mode) | Works where multiple MACs per port are blocked |
| Need pod-to-host communication | **Bridge** | Only option allowing bidirectional pod ↔ host traffic |
| Maximum performance / Low latency | **SR-IOV** | Direct hardware access for wire-speed performance |
| NFV/5G workloads (extreme speed) | **SR-IOV + DPDK** | Kernel bypass for highest packet processing rates |
| Simple pod isolation | **Macvlan** (private mode) | Easy configuration for complete isolation |

### Plugin Performance Reference

| CNI Plugin | Throughput |
|------------|-----------|
| Regular CNI (veth/Bridge) | ~10–20 Gbps |
| Macvlan / IPvlan | ~20–40 Gbps |
| SR-IOV | ~100 Gbps+ (wire speed) |
| SR-IOV + DPDK | Maximum possible (kernel bypass) |

## ⚠️ Known Issue: Cilium as Secondary CNI

When using Cilium as a secondary CNI in an RKE2 cluster with Multus, frequent CoreDNS restarts occur every few minutes.

Supported Cilium chaining modes: `none`, `generic-veth`, `aws-cni`, `flannel`, `portmap`, `calico`

GitHub issues: https://github.com/cilium/cilium/issues/23483 | https://github.com/cilium/cilium/issues/20129

## References
- https://devopstales.github.io/kubernetes/multus/
- https://github.com/anishrana2001/Kubernetes/blob/main/25.%20Multus/Lab.md
