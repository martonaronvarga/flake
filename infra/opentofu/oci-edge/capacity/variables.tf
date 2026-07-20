variable "region" { type = string }
variable "tenancy_ocid" { type = string }
variable "compartment_ocid" { type = string }
variable "user_ocid" {
  type      = string
  sensitive = true
}
variable "fingerprint" {
  type      = string
  sensitive = true
}
variable "private_key_path" {
  type      = string
  sensitive = true
}
variable "subnet_id" { type = string }
variable "nsg_id" { type = string }
variable "ssh_public_key_path" { type = string }
variable "name" {
  type    = string
  default = "gloam"
}
variable "availability_domain_index" {
  type    = number
  default = 0
}
variable "ocpus" {
  type    = number
  default = 1
}
variable "memory_in_gbs" {
  type    = number
  default = 6
}
variable "boot_volume_size_gbs" {
  type    = number
  default = 50
}
variable "ubuntu_version" {
  type    = string
  default = "24.04"
}
