data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_aarch64" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.ubuntu_version
  shape                    = "VM.Standard.A1.Flex"
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = [".*aarch64.*"]
    regex  = true
  }
}

locals {
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain_index].name
  common_tags = {
    host       = var.name
    managed-by = "opentofu"
    role       = "edge-candidate"
  }
}

resource "oci_core_instance" "a1" {
  availability_domain  = local.availability_domain
  compartment_id       = var.compartment_ocid
  display_name         = "${var.name}-a1"
  shape                = "VM.Standard.A1.Flex"
  freeform_tags        = local.common_tags
  preserve_boot_volume = false

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_aarch64.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gbs
    boot_volume_vpus_per_gb = 10
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    nsg_ids          = [var.nsg_id]
    display_name     = "${var.name}-a1-vnic"
    hostname_label   = "${var.name}-a1"
    freeform_tags    = local.common_tags
  }

  metadata = {
    ssh_authorized_keys = trimspace(file(pathexpand(var.ssh_public_key_path)))
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  timeouts {
    create = "15m"
  }
}

data "oci_core_vnic_attachments" "a1" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  instance_id         = oci_core_instance.a1.id
}

data "oci_core_vnic" "a1" {
  vnic_id = data.oci_core_vnic_attachments.a1.vnic_attachments[0].vnic_id
}

data "oci_core_private_ips" "a1" {
  vnic_id = data.oci_core_vnic.a1.id
}
