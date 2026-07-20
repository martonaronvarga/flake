variable "region" {
  description = "OCI region identifier, e.g. eu-frankfurt-1."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID; used to enumerate availability domains and configure the provider."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID for networking and compute resources."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID used for API key authentication."
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint of the uploaded OCI API public key."
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to the OCI API private key PEM."
  type        = string
  sensitive   = true
  default     = "~/.config/oci/oci_private_key.pem"
}

variable "name" {
  description = "Stable edge name. Keep this as gloam even when the compute backend changes."
  type        = string
  default     = "gloam"
}

variable "amd_availability_domain" {
  description = "Exact AD name for the AMD fallback. Leave empty to use amd_availability_domain_index."
  type        = string
  default     = ""
}

variable "amd_availability_domain_index" {
  description = "Fixed AD index for the AMD fallback. Do not vary this in the A1 retry loop."
  type        = number
  default     = 0
}

variable "vcn_cidr" {
  description = "VCN IPv4 CIDR. Do not overlap with the home LAN."
  type        = string
  default     = "10.80.0.0/16"
}

variable "subnet_cidr" {
  description = "Public subnet IPv4 CIDR."
  type        = string
  default     = "10.80.1.0/24"
}

variable "ssh_public_key_path" {
  description = "Public key injected through OCI metadata/cloud-init."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_port" {
  description = "Management SSH port exposed by the OCI edge node."
  type        = number
  default     = 22
}

variable "emergency_ssh_cidr" {
  description = "Optional temporary IPv4 CIDR allowed to reach SSH. Keep null during normal operation."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.emergency_ssh_cidr == null || can(cidrnetmask(var.emergency_ssh_cidr))
    error_message = "emergency_ssh_cidr must be null or a valid IPv4 CIDR."
  }
}

variable "wireguard_port" {
  description = "Public UDP WireGuard listen port on gloam."
  type        = number
  default     = 51820
}

variable "active_backend" {
  description = "Which backend receives the reserved public IP."
  type        = string
  default     = "amd"

  validation {
    condition     = contains(["amd", "a1"], var.active_backend)
    error_message = "active_backend must be amd or a1."
  }
}

variable "a1_private_ip_id" {
  description = "Verified A1 private IP OCID used only during a manual promotion."
  type        = string
  default     = null
  nullable    = true
}

variable "create_amd" {
  description = "Create the AMD micro backend. Keep true while using the AMD fallback."
  type        = bool
  default     = true
}

variable "boot_volume_size_gbs" {
  description = "Boot volume size in GiB. OCI image launches require at least about 50 GiB."
  type        = number
  default     = 50
}

variable "defined_tags" {
  description = "Optional OCI defined tags."
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags applied to resources."
  type        = map(string)
  default = {
    managed-by = "opentofu"
    role       = "edge"
  }
}

variable "ubuntu_version" {
  description = "version number of ubuntu os."
  type        = string
  default     = "24.04"
}
