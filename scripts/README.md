# Scripts Directory

This directory contains automation scripts for your homelab infrastructure.

## Talos ISO Upload Scripts

Two scripts are provided to automatically download and upload Talos OS ISO images to your Proxmox servers:

### 🪟 **For Windows Users: `Upload-TalosISO.ps1`**

```powershell
# Download and upload latest Talos OS version
.\scripts\Upload-TalosISO.ps1

# Download and upload specific version
.\scripts\Upload-TalosISO.ps1 v1.6.1

# Show help
.\scripts\Upload-TalosISO.ps1 -Help
```

### 🐧 **For Linux/macOS Users: `upload-talos-iso.sh`**

```bash
# Make script executable (Linux/macOS)
chmod +x scripts/upload-talos-iso.sh

# Download and upload latest Talos OS version
./scripts/upload-talos-iso.sh

# Download and upload specific version
./scripts/upload-talos-iso.sh v1.6.1

# Show help
./scripts/upload-talos-iso.sh --help
```

## What These Scripts Do

1. **📥 Download**: Automatically downloads the latest (or specified) Talos OS ISO from GitHub releases
2. **🔍 Verify**: Tests SSH connectivity to your Proxmox hosts
3. **📤 Upload**: Copies the ISO to the correct storage location on each Proxmox server
4. **✅ Validate**: Confirms successful upload and file sizes
5. **🧹 Cleanup**: Removes temporary download files

## Prerequisites

### For Both Scripts
- **SSH Key Access**: Configured SSH keys for passwordless access to Proxmox hosts
- **Internet Connection**: To download ISOs from GitHub
- **Network Access**: To reach your Proxmox servers

### For PowerShell Script (Windows)
- **PowerShell 5.0+**: Usually included with Windows 10/11
- **SSH/SCP Tools**: Install Git for Windows (includes OpenSSH) or Windows OpenSSH feature

### For Bash Script (Linux/macOS)
- **Standard Tools**: `curl`, `jq`, `ssh`, `scp` (usually pre-installed)

## Configuration

Before running, update the scripts with your specific details:

```bash
# Edit these values in the scripts:
PROXMOX_HOSTS=("192.168.100.10" "192.168.100.20")  # Your Proxmox IPs
PROXMOX_USER="root"                                  # SSH user
SSH_KEY_PATH="$HOME/.ssh/id_rsa"                    # Your SSH key path
```

## Output Example

```
[2024-01-15 10:30:15] [INFO] Starting Talos ISO upload process...
[2024-01-15 10:30:15] [INFO] Target Proxmox hosts: 192.168.100.10, 192.168.100.20
[2024-01-15 10:30:16] [SUCCESS] All dependencies found
[2024-01-15 10:30:17] [INFO] Fetching latest Talos OS version from GitHub...
[2024-01-15 10:30:18] [SUCCESS] Latest version: v1.6.1
[2024-01-15 10:30:18] [INFO] Downloading Talos OS v1.6.1...
[2024-01-15 10:35:22] [SUCCESS] Downloaded Talos ISO successfully
[2024-01-15 10:35:23] [INFO] Processing Proxmox host: 192.168.100.10
[2024-01-15 10:35:24] [SUCCESS] SSH connection to 192.168.100.10 successful
[2024-01-15 10:37:45] [SUCCESS] Successfully uploaded ISO to 192.168.100.10
[2024-01-15 10:37:45] [INFO] Remote file size: 147M
[2024-01-15 10:37:46] [SUCCESS] Successfully uploaded to 2/2 hosts
[2024-01-15 10:37:46] [INFO] Talos ISO location: /var/lib/vz/template/iso/metal-v1.6.1-amd64.iso
[2024-01-15 10:37:46] [INFO] Use in Terraform as: local:iso/metal-v1.6.1-amd64.iso
[2024-01-15 10:37:46] [SUCCESS] Talos ISO upload process completed!
```

## After Upload

Once the script completes successfully:

1. **✅ Update Terraform**: The ISO will be available as `local:iso/metal-v1.6.1-amd64.iso`
2. **🚀 Deploy Cluster**: Run `terraform apply` to create your Kubernetes cluster
3. **🔍 Verify**: Check Proxmox web interface under Storage > local > ISO Images

## Troubleshooting

### SSH Connection Issues
```bash
# Test manual SSH connection
ssh -i ~/.ssh/id_rsa root@192.168.100.10

# Check if SSH key is loaded
ssh-add -l

# Add SSH key if needed
ssh-add ~/.ssh/id_rsa
```

### Missing Dependencies (Windows)
```powershell
# Install Git for Windows (includes SSH/SCP)
winget install Git.Git

# Or enable Windows OpenSSH
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### Download Issues
- Check internet connectivity
- Verify GitHub is accessible
- Try downloading manually: https://github.com/siderolabs/talos/releases

### Upload Issues
- Verify Proxmox hosts are reachable
- Check SSH key permissions (should be 600)
- Ensure sufficient disk space on Proxmox storage

## Manual Alternative

If the scripts don't work, you can manually download and upload:

```bash
# Download manually
curl -LO https://github.com/siderolabs/talos/releases/latest/download/metal-amd64.iso

# Upload manually
scp metal-amd64.iso root@192.168.100.10:/var/lib/vz/template/iso/

# Rename for clarity
ssh root@192.168.100.10 "mv /var/lib/vz/template/iso/metal-amd64.iso /var/lib/vz/template/iso/metal-v1.6.1-amd64.iso"
```

## Integration with Terraform

After successful upload, update your `terraform.tfvars`:

```hcl
talos_cluster = {
  enabled   = true
  iso_image = "local:iso/metal-v1.6.1-amd64.iso"  # Use exact filename from upload
  # ... other configuration
}
```

Then deploy your cluster:

```bash
cd terraform
terraform plan
terraform apply
``` 