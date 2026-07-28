terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "superuser_password" {
  description = "PostgreSQL superuser password"
  type        = string
  sensitive   = true
}

variable "replication_password" {
  description = "PostgreSQL replication password"
  type        = string
  sensitive   = true
}

resource "libvirt_network" "shared_net" {
  name      = "cluster-net"
  autostart = true
  forward   = { mode = "nat" }
  bridge    = { name = "virbr-cluster" }
  domain    = { name = "cluster.local" }
  ips = [{
    address = "10.0.1.1"
    prefix  = 24
    dhcp = {
      enabled = true
      ranges  = [{ start = "10.0.1.100", end = "10.0.1.250" }]
      hosts = concat(
        [for i in range(3) : {
          ip   = "10.0.1.3${i}"
          mac  = "52:54:00:12:34:5${i}"
          name = "postgres-${i}"
        }],
        [for i in range(2) : {
          ip   = "10.0.1.2${i}"
          mac  = "52:54:00:12:34:4${i}"
          name = "haproxy-${i}"
        }]
      )
    }
  }]
}

module "postgres" {
  source               = "../../modules/postgres/kvm"
  network_name         = libvirt_network.shared_net.name
  superuser_password   = var.superuser_password
  replication_password = var.replication_password
}

module "haproxy" {
  source       = "../../modules/haproxy/kvm"
  network_name = libvirt_network.shared_net.name
}
