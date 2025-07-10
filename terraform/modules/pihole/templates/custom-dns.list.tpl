# Custom DNS Records - Managed by Terraform
# Format: IP_ADDRESS HOSTNAME
%{ for record in dns_records ~}
${record.ip} ${record.hostname}
%{ endfor ~} 