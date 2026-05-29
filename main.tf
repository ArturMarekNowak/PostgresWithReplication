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

module "postgres" {
  source       = "./modules/postgres"
  network_name     = libvirt_network.shared_net.name
}

module "haproxy" {
  source       = "./modules/haproxy"
  network_name     = libvirt_network.shared_net.name
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
      hosts   = concat(
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
