# Automated Tailscale Deployment for Datacenter Servers

This Terraform project automatically installs and configures Tailscale on your datacenter servers using remote execution. The modular design makes it easy to add other services later.

## 🏗️ Project Structure

```
terraform/
├── 📄 main.tf                      # Main configuration
├── 📄 variables.tf                 # Input variables
├── 📄 outputs.tf                   # Output definitions
├── 📄 providers.tf                 # Terraform providers
├── 📄 terraform.tfvars             # Your configuration
├── 📄 README.md                    # This file
│
└── 📂 modules/
    └── 📂 tailscale/               # Tailscale module
        ├── main.tf                 # Module logic (remote-exec)
        ├── variables.tf            # Module variables
        ├── outputs.tf              # Module outputs
        └── 📂 templates/           # Backup script templates
            ├── install-tailscale.sh.tpl
            └── deploy-all.sh.tpl
```

## 🎯 What This Does

- **Automated Installation** - Terraform connects via SSH and installs Tailscale automatically
- **Modular Design** - Easy to extend with other services
- **Remote Execution** - No manual script running required
- **Scalable** - Easy to add more servers

## 📋 Prerequisites

- Terraform installed
- SSH access to your servers (key-based preferred)
- Tailscale account and auth key

## 🚀 Quick Start

### 1. Get Your Tailscale Auth Key

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Generate a new auth key
3. Copy the key for configuration

### 2. Configure SSH Access

Make sure you have SSH access to your servers:
```bash
# Test SSH access
ssh automation@192.168.1.10
ssh automation@192.168.1.20
```

### 3. Configure Terraform

Edit `terraform.tfvars`:

```hcl
# Tailscale Configuration
tailscale_auth_key = "tskey-auth-your-key-here"

# SSH Connection (choose one method)
# Option 1: SSH Key (recommended)
ssh_private_key = "~/.ssh/id_rsa"
# Option 2: SSH Password (less secure)
# ssh_password = "your-ssh-password"

# Your datacenter servers
machines = [
  {
    name     = "server1"
    ip       = "192.168.1.10"
    username = "automation"
  },
  {
    name     = "server2"
    ip       = "192.168.1.20"
    username = "automation"
  }
]
```

### 4. Deploy Automatically

```bash
terraform init
terraform apply
```

Terraform will:
1. Connect to each server via SSH
2. Update packages
3. Install Tailscale
4. Connect to your Tailscale network
5. Enable the service

## 📈 Adding More Servers

1. Add to `terraform.tfvars`:
```hcl
machines = [
  {
    name     = "server1"
    ip       = "192.168.1.10"
    username = "automation"
  },
  {
    name     = "server2"
    ip       = "192.168.1.20"
    username = "automation"
  },
  {
    name     = "server3"    # New server
    ip       = "192.168.1.30"
    username = "automation"
  }
]
```

2. Apply changes:
```bash
terraform apply
```

Terraform will automatically install Tailscale on the new server!

## 🔧 Adding Other Services

The modular structure makes it easy to add other services:

1. **Create a new module** in `modules/new-service/`
2. **Add module files**:
   - `main.tf` - Service logic with remote-exec
   - `variables.tf` - Service variables
   - `outputs.tf` - Service outputs
3. **Import in main.tf**:
```hcl
module "new_service" {
  source = "./modules/new-service"
  
  machines        = var.machines
  ssh_private_key = var.ssh_private_key
  # other variables...
}
```

## 🔍 Verification

Check installation:
```bash
ssh automation@192.168.1.10 'tailscale status'
ssh automation@192.168.1.20 'tailscale status'
```

Or check your [Tailscale Admin Console](https://login.tailscale.com/admin/machines)

## 🛠️ Troubleshooting

**SSH connection fails**: 
- Verify SSH key path in terraform.tfvars
- Test manual SSH connection
- Check username and IP addresses

**Tailscale auth fails**: 
- Check auth key validity
- Ensure key hasn't expired

**Permission denied**: 
- Ensure user has sudo access
- Test: `ssh user@host 'sudo whoami'`

**Re-run installation**:
```bash
terraform apply -replace="module.tailscale.null_resource.tailscale_install[\"server1\"]"
```

## 🔐 Security Notes

- Use SSH keys instead of passwords
- Consider using a dedicated SSH user for automation
- Tailscale provides secure remote access to your datacenter
- Auth keys can be set to expire for additional security

Perfect for automated infrastructure management! 🎉 