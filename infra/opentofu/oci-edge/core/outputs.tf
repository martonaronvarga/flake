output "reserved_public_ip" {
  description = "Stable public IPv4 address for gloam. Point DNS and dusk WireGuard endpoint here."
  value       = oci_core_public_ip.edge.ip_address
}

output "active_backend" {
  value = var.active_backend
}

output "amd_availability_domain" {
  value = local.amd_availability_domain
}
output "amd_instance_id" {
  value = try(oci_core_instance.amd[0].id, null)
}

output "amd_private_ip" {
  value = try(data.oci_core_private_ips.amd[0].private_ips[0].ip_address, null)
}

output "capacity_inputs" {
  description = "Non-secret inputs written to the separately managed capacity root."
  value = {
    compartment_ocid = var.compartment_ocid
    subnet_id        = oci_core_subnet.public.id
    nsg_id           = oci_core_network_security_group.edge.id
  }
}

output "ssh_command" {
  description = "ubuntu default user is ubuntu. For NixOS, switch user to root/usu after deployment."
  value       = "ssh -p ${var.ssh_port} ubuntu@${oci_core_public_ip.edge.ip_address}"
}
