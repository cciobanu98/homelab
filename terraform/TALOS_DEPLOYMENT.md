# Quick Talos Kubernetes Deployment Guide

This guide will help you deploy a Kubernetes cluster using Talos OS on your Proxmox infrastructure.

## Prerequisites Checklist

- [ ] **Talos ISO Downloaded**: Get from [Talos Releases](https://github.com/siderolabs/talos/releases)
- [ ] **ISO Uploaded**: Upload to Proxmox storage (e.g., `local:iso/talos-amd64.iso`)
- [ ] **Network Planned**: Decide IP addresses for cluster nodes
- [ ] **Resources Available**: Ensure sufficient CPU/RAM/Disk on Proxmox nodes

## Quick Start - Single Node Cluster

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** - Enable Talos with minimal config:
   ```hcl
   talos_cluster = {
     enabled          = true
     cluster_name     = "homelab"
     cluster_endpoint = "https://192.168.100.100:6443"
     iso_image        = "local:iso/talos-amd64.iso"
     network_cidr     = "24"
     gateway          = "192.168.100.1"
     nameserver       = "192.168.100.1"
     pod_cidr         = "10.244.0.0/16"
     service_cidr     = "10.96.0.0/12"
     
     control_plane_nodes = [
       {
         name        = "k8s-cp-01"
         target_node = "server1"          # Your Proxmox node name
         vmid        = 300
         memory      = 4096               # 4GB RAM
         cores       = 4                  # 4 CPU cores
         disk_size   = "40G"              # 40GB disk
         ip_address  = "192.168.100.100"  # Change to available IP
       }
     ]
     
     worker_nodes = []  # Single node cluster
   }
   ```

3. **Initialize and deploy**:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

4. **Wait for deployment** (15-20 minutes for first run)

5. **Access your cluster**:
   ```bash
   cd modules/talos
   ./talosctl --talosconfig generated/talosconfig kubeconfig --nodes 192.168.100.100
   kubectl get nodes
   ```

## Scaling to Multiple Nodes

### Add More Control Plane Nodes (Recommended for HA)
```hcl
control_plane_nodes = [
  {
    name        = "k8s-cp-01"
    target_node = "server1"
    vmid        = 300
    memory      = 4096
    cores       = 4
    disk_size   = "40G"
    ip_address  = "192.168.100.100"
  },
  {
    name        = "k8s-cp-02"
    target_node = "server2"    # Different Proxmox node
    vmid        = 301
    memory      = 4096
    cores       = 4
    disk_size   = "40G"
    ip_address  = "192.168.100.101"
  },
  {
    name        = "k8s-cp-03"
    target_node = "server1"    # Can reuse nodes
    vmid        = 302
    memory      = 4096
    cores       = 4
    disk_size   = "40G"
    ip_address  = "192.168.100.102"
  }
]
```

### Add Dedicated Worker Nodes
```hcl
worker_nodes = [
  {
    name        = "k8s-worker-01"
    target_node = "server1"
    vmid        = 310
    memory      = 8192         # More RAM for workloads
    cores       = 6            # More CPU cores
    disk_size   = "100G"       # Larger disk
    ip_address  = "192.168.100.110"
  },
  {
    name        = "k8s-worker-02"
    target_node = "server2"
    vmid        = 311
    memory      = 8192
    cores       = 6
    disk_size   = "100G"
    ip_address  = "192.168.100.111"
  }
]
```

## Configuration for Different Use Cases

### Development/Testing Cluster
- **Control Plane**: 2GB RAM, 2 CPU, 20GB disk
- **Worker Nodes**: 4GB RAM, 2 CPU, 50GB disk
- **Count**: 1 control plane, 0-2 workers

### Production Cluster
- **Control Plane**: 4GB RAM, 4 CPU, 40GB disk
- **Worker Nodes**: 8-16GB RAM, 4-8 CPU, 100-200GB disk
- **Count**: 3 control planes, 3+ workers

### High-Memory Workloads
- **Worker Nodes**: 32-64GB RAM, 8-16 CPU, 200-500GB disk
- **Use Case**: AI/ML, databases, data processing

## Deployment Timeline

| Step | Duration | Description |
|------|----------|-------------|
| VM Creation | 2-3 min | Proxmox creates VMs |
| VM Boot | 2-3 min | VMs boot from Talos ISO |
| Talos Config | 5-8 min | Apply Talos configuration |
| K8s Bootstrap | 5-10 min | Initialize Kubernetes |
| **Total** | **15-25 min** | Complete cluster ready |

## Post-Deployment Checklist

- [ ] **Verify nodes**: `kubectl get nodes`
- [ ] **Check pods**: `kubectl get pods -A`
- [ ] **Install CNI**: If using custom networking
- [ ] **Configure storage**: Install storage provider
- [ ] **Set up ingress**: For external access
- [ ] **Configure monitoring**: Prometheus/Grafana
- [ ] **Backup configs**: Save `talosconfig` and `kubeconfig`

## Essential Commands

```bash
# Check cluster health
./talosctl --talosconfig generated/talosconfig health

# Get node information
./talosctl --talosconfig generated/talosconfig get members

# View logs
./talosctl --talosconfig generated/talosconfig logs

# Reset cluster (destructive!)
./talosctl --talosconfig generated/talosconfig reset

# Upgrade Talos OS
./talosctl --talosconfig generated/talosconfig upgrade --image ghcr.io/siderolabs/installer:v1.6.0

# Upgrade Kubernetes
./talosctl --talosconfig generated/talosconfig upgrade-k8s --to 1.29.0
```

## Troubleshooting Quick Fixes

### VMs Won't Start
```bash
# Check Proxmox logs
tail -f /var/log/pve/tasks/active

# Verify ISO path
qm config <vmid> | grep cdrom
```

### Network Issues
```bash
# Test connectivity
ping 192.168.100.100

# Check Talos logs via console
./talosctl --talosconfig generated/talosconfig logs --follow
```

### Bootstrap Fails
```bash
# Check if nodes are ready
./talosctl --talosconfig generated/talosconfig get members

# Retry bootstrap
./talosctl --talosconfig generated/talosconfig bootstrap --nodes 192.168.100.100
```

## Next Steps

1. **Install Applications**: Deploy your first workloads
2. **Set Up Storage**: Configure persistent volumes
3. **Configure Networking**: Set up ingress and load balancing
4. **Enable Monitoring**: Install metrics and logging
5. **Implement Backup**: Set up etcd and data backups
6. **Security Hardening**: Configure RBAC and network policies

## Support Resources

- **Talos Documentation**: https://www.talos.dev/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Module README**: `terraform/modules/talos/README.md`
- **Configuration Examples**: `terraform.tfvars.example` 