terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Generate custom DNS records file
resource "local_file" "custom_dns" {
  count = var.pihole_config.enabled ? 1 : 0
  
  content = templatefile("${path.module}/templates/custom-dns.list.tpl", {
    dns_records = var.custom_dns_records
  })
  filename = "${path.module}/generated/custom.list"
}

# Pi-hole LXC Container
resource "proxmox_lxc" "pihole" {
  count = var.pihole_config.enabled ? 1 : 0
  
  target_node  = var.pihole_config.target_node
  hostname     = var.pihole_config.hostname
  vmid         = var.pihole_config.vmid
  password     = var.pihole_config.password
  unprivileged = true
  onboot       = true
  start        = true

  # Operating system - Use more common template path
  ostemplate = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

  # Resources
  memory = var.pihole_config.memory
  cores  = var.pihole_config.cores

  # Root filesystem
  rootfs {
    storage = "local-lvm"
    size    = var.pihole_config.disk_size
  }

  # Network configuration
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.pihole_config.ip_address}/24"
    gw     = var.pihole_config.gateway
    tag    = -1
  }

  # Features for Pi-hole
  features {
    nesting = true
  }

  # SSH public key (if provided)
  ssh_public_keys = var.ssh_public_key != "" ? var.ssh_public_key : null

  lifecycle {
    ignore_changes = [
      ostemplate,
    ]
  }
}

# Get Proxmox host IP based on target_node
locals {
  proxmox_host = var.pihole_config.target_node == "server1" ? "192.168.100.10" : "192.168.100.20"
}

# Configure SSH in the container via Proxmox
resource "null_resource" "pihole_ssh_setup" {
  count = var.pihole_config.enabled ? 1 : 0
  
  depends_on = [proxmox_lxc.pihole]

  # Configure SSH via Proxmox host
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = local.proxmox_host
      private_key = var.ssh_private_key != "" ? file(var.ssh_private_key) : null
      password    = var.ssh_password != "" ? var.ssh_password : null
      timeout     = "5m"
    }

    inline = [
      # Wait for container to be fully ready
      "sleep 30",
      
      # Install and configure SSH server in the container
      "pct exec ${var.pihole_config.vmid} -- bash -c 'apt-get update'",
      "pct exec ${var.pihole_config.vmid} -- bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server'",
      
      # Configure SSH for external access
      "pct exec ${var.pihole_config.vmid} -- bash -c 'echo \"PermitRootLogin yes\" >> /etc/ssh/sshd_config'",
      "pct exec ${var.pihole_config.vmid} -- bash -c 'echo \"PasswordAuthentication yes\" >> /etc/ssh/sshd_config'",
      "pct exec ${var.pihole_config.vmid} -- bash -c 'echo \"PubkeyAuthentication yes\" >> /etc/ssh/sshd_config'",
      
      # Enable and start SSH service
      "pct exec ${var.pihole_config.vmid} -- bash -c 'systemctl enable ssh'",
      "pct exec ${var.pihole_config.vmid} -- bash -c 'systemctl start ssh'",
      
      # Verify SSH is running
      "pct exec ${var.pihole_config.vmid} -- bash -c 'systemctl status ssh --no-pager || true'",
      
      "echo 'SSH server configured in Pi-hole container'"
    ]
  }

  triggers = {
    container_id = join(",", proxmox_lxc.pihole[*].id)
  }
}

# Install and configure Pi-hole
resource "null_resource" "pihole_setup" {
  count = var.pihole_config.enabled ? 1 : 0
  
  depends_on = [null_resource.pihole_ssh_setup, local_file.custom_dns]

  connection {
    type        = "ssh"
    user        = "root"
    host        = var.pihole_config.ip_address
    private_key = var.ssh_private_key != "" ? file(var.ssh_private_key) : null
    password    = var.pihole_config.password
    timeout     = "10m"
  }

  # Upload custom DNS records file
  provisioner "file" {
    source      = "${path.module}/generated/custom.list"
    destination = "/tmp/custom.list"
  }

  provisioner "remote-exec" {
    inline = [
      # Basic connectivity test
      "echo '✅ SSH connection successful! Starting Pi-hole installation...'",
      
      # Update system
      "apt-get update",
      
      # Install essential packages including web server
      "DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget sudo systemd lighttpd php-cgi",
      
      # Pre-configure lighttpd for Pi-hole
      "systemctl stop lighttpd || true",
      
      # Create Pi-hole setup variables file for unattended install
      "mkdir -p /etc/pihole",
      "cat > /etc/pihole/setupVars.conf << 'EOF'",
      "PIHOLE_INTERFACE=eth0",
      "IPV4_ADDRESS=${var.pihole_config.ip_address}/24",
      "IPV6_ADDRESS=",
      "PIHOLE_DNS_1=1.1.1.1",
      "PIHOLE_DNS_2=8.8.8.8",
      "QUERY_LOGGING=true",
      "INSTALL_WEB_SERVER=true",
      "INSTALL_WEB_INTERFACE=true",
      "LIGHTTPD_ENABLED=true",
      "BLOCKING_ENABLED=true",
      "WEBPASSWORD=",
      "DNSMASQ_LISTENING=local",
      "DNS_FQDN_REQUIRED=true",
      "DNS_BOGUS_PRIV=true",
      "DNSSEC=false",
      "TEMPERATUREUNIT=C",
      "WEBUIBOXEDLAYOUT=traditional",
      "API_EXCLUDE_DOMAINS=",
      "API_EXCLUDE_CLIENTS=",
      "API_QUERY_LOG_SHOW=all",
      "API_PRIVACY_MODE=false",
      "EOF",
      
      # Download and install Pi-hole
      "curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended",
      
      # Set Pi-hole admin password
      "pihole -a -p '${var.pihole_admin_password}'",
      
      # Deploy custom DNS records
      "if [ -f /tmp/custom.list ] && [ -s /tmp/custom.list ]; then",
      "  echo 'Deploying custom DNS records...'",
      "  cp /tmp/custom.list /etc/pihole/custom.list",
      "  chown root:root /etc/pihole/custom.list",
      "  chmod 644 /etc/pihole/custom.list",
      "else",
      "  echo 'No custom DNS records to deploy'",
      "  touch /etc/pihole/custom.list",
      "fi",
      
      # Configure and start web server
      "systemctl enable lighttpd",
      "systemctl start lighttpd",
      
      # Start and enable Pi-hole services
      "systemctl enable pihole-FTL",
      "systemctl start pihole-FTL",
      
      # Restart Pi-hole to reload custom DNS and web interface
      "pihole restartdns",
      "systemctl restart lighttpd",
      
      # Install Tailscale
      "curl -fsSL https://tailscale.com/install.sh | sh",
      "tailscale up --authkey='${var.tailscale_auth_key}' --hostname='${var.pihole_config.hostname}' --accept-dns=false",
      "systemctl enable tailscaled",
      
      # Final status check
      "echo '✅ Pi-hole installation completed!'",
      "echo 'Web Interface: http://${var.pihole_config.ip_address}/admin'",
      "echo 'DNS Server: ${var.pihole_config.ip_address}'",
      "echo 'Custom DNS records: $(wc -l < /etc/pihole/custom.list) entries'",
      
      # Verify services are running
      "systemctl is-active lighttpd && echo '✅ Web server: Running' || echo '❌ Web server: Failed'",
      "systemctl is-active pihole-FTL && echo '✅ Pi-hole FTL: Running' || echo '❌ Pi-hole FTL: Failed'",
      "systemctl is-active tailscaled && echo '✅ Tailscale: Running' || echo '❌ Tailscale: Failed'",
      
      # Check if web interface is accessible
      "timeout 10 curl -s http://localhost/admin/ > /dev/null && echo '✅ Web interface: Accessible' || echo '⚠️  Web interface: Check manually'",
      
      "pihole status || echo 'Pi-hole status check completed'"
    ]
  }

  triggers = {
    container_id = join(",", proxmox_lxc.pihole[*].id)
    config_hash  = md5(jsonencode(var.pihole_config))
    admin_password = md5(var.pihole_admin_password)
    dns_records = md5(jsonencode(var.custom_dns_records))
  }
} 