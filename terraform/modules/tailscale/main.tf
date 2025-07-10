terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Install Tailscale on each Proxmox node using SSH
resource "null_resource" "tailscale_install" {
  for_each = { for machine in var.machines : machine.name => machine }
  
  connection {
    type        = "ssh"
    user        = each.value.username
    host        = each.value.ip
    private_key = var.ssh_private_key != "" ? file(var.ssh_private_key) : null
    password    = var.ssh_password != "" ? var.ssh_password : null
  }
  
  provisioner "remote-exec" {
    inline = [
      # Test basic commands first
      "echo 'Starting installation on ${each.value.name}...'",
      "whoami",
      "pwd",
      "which curl || (echo 'Installing curl...' && apt-get update && apt-get install -y curl)",
      
      # Install Tailscale
      "echo 'Downloading Tailscale installer...'",
      "curl -fsSL https://tailscale.com/install.sh | sh",
      
      # Connect to Tailscale (no sudo needed as root)
      "echo 'Connecting to Tailscale network...'",
      "tailscale up --authkey='${var.tailscale_auth_key}' --hostname='${each.value.name}' --accept-dns=false",
      
      # Enable and start service
      "systemctl enable tailscaled",
      "systemctl start tailscaled",
      
      # Verify installation
      "echo 'Installation completed on ${each.value.name}'",
      "tailscale status || echo 'Tailscale status check failed, but service may still be connecting'"
    ]
  }
  
  # Trigger re-run if auth key or machine config changes
  triggers = {
    auth_key = var.tailscale_auth_key
    machine_config = jsonencode(each.value)
  }
}

 