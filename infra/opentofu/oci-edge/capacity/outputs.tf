output "instance_id" {
  value = oci_core_instance.a1.id
}

output "private_ip_id" {
  value = data.oci_core_private_ips.a1.private_ips[0].id
}

output "private_ip" {
  value = data.oci_core_private_ips.a1.private_ips[0].ip_address
}
