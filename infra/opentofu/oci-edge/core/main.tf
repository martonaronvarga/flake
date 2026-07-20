data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

locals {
  amd_availability_domain = (
    var.amd_availability_domain != ""
    ? var.amd_availability_domain
    : data.oci_identity_availability_domains.this.availability_domains[var.amd_availability_domain_index].name
  )

  common_tags = merge(var.freeform_tags, { host = var.name })
}

resource "oci_core_vcn" "edge" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name}-vcn"
  dns_label      = var.name
  defined_tags   = var.defined_tags
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "edge" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.edge.id
  display_name   = "${var.name}-igw"
  enabled        = true
  defined_tags   = var.defined_tags
  freeform_tags  = local.common_tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.edge.id
  display_name   = "${var.name}-public-rt"
  defined_tags   = var.defined_tags
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.edge.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_network_security_group" "edge" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.edge.id
  display_name   = "${var.name}-edge-nsg"
  defined_tags   = var.defined_tags
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "ssh" {
  count = var.emergency_ssh_cidr == null ? 0 : 1

  network_security_group_id = oci_core_network_security_group.edge.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.emergency_ssh_cidr
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "Temporary emergency SSH management."

  tcp_options {
    destination_port_range {
      min = var.ssh_port
      max = var.ssh_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "wireguard" {
  network_security_group_id = oci_core_network_security_group.edge.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "WireGuard public ingress for dusk."

  udp_options {
    destination_port_range {
      min = var.wireguard_port
      max = var.wireguard_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "http" {
  network_security_group_id = oci_core_network_security_group.edge.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "Public HTTP ingress for martonaronvarga.dev."

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "https" {
  network_security_group_id = oci_core_network_security_group.edge.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = false
  description               = "Public HTTPS ingress for martonaronvarga.dev."

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.edge.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  stateless                 = false
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.edge.id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.name}-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  defined_tags               = var.defined_tags
  freeform_tags              = local.common_tags
}

data "oci_core_images" "ubuntu_x86_64" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.ubuntu_version
  shape                    = "VM.Standard.E2.1.Micro"
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "amd" {
  count                = var.create_amd ? 1 : 0
  availability_domain  = local.amd_availability_domain
  compartment_id       = var.compartment_ocid
  display_name         = "${var.name}-amd"
  shape                = "VM.Standard.E2.1.Micro"
  defined_tags         = var.defined_tags
  freeform_tags        = merge(local.common_tags, { backend = "amd" })
  preserve_boot_volume = true

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_x86_64.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gbs
    boot_volume_vpus_per_gb = 10
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.edge.id]
    display_name     = "${var.name}-amd-vnic"
    hostname_label   = "${var.name}-amd"
    freeform_tags    = merge(local.common_tags, { backend = "amd" })
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

  lifecycle {
    prevent_destroy = true
  }
}

data "oci_core_vnic_attachments" "amd" {
  count               = var.create_amd ? 1 : 0
  compartment_id      = var.compartment_ocid
  availability_domain = local.amd_availability_domain
  instance_id         = oci_core_instance.amd[0].id
}

data "oci_core_vnic" "amd" {
  count   = var.create_amd ? 1 : 0
  vnic_id = data.oci_core_vnic_attachments.amd[0].vnic_attachments[0].vnic_id
}

data "oci_core_private_ips" "amd" {
  count   = var.create_amd ? 1 : 0
  vnic_id = data.oci_core_vnic.amd[0].id
}

locals {
  amd_private_ip_id    = var.create_amd ? data.oci_core_private_ips.amd[0].private_ips[0].id : null
  active_private_ip_id = var.active_backend == "amd" ? local.amd_private_ip_id : var.a1_private_ip_id
}

resource "oci_core_public_ip" "edge" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name}-reserved-public-ip"
  lifetime       = "RESERVED"
  private_ip_id  = local.active_private_ip_id
  defined_tags   = var.defined_tags
  freeform_tags  = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
