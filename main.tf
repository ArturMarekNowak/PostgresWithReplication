terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-24.04.qcow2"
  pool   = "default"
  
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    }
  }
}

resource "libvirt_volume" "os_disk" {
  count  = 3
  name   = "postgres-os-disk-${count.index}.qcow2"
  pool   = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }
  capacity = 2147483648

  backing_store = {
    path   = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_domain" "postgres" {
  name         = "postgres-${count.index}"
  type         = "kvm"
  memory       = 4096
  memory_unit  = "MiB"
  vcpu         = 2
  count        = 3
  
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }
  
  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.os_disk[count.index].pool
            volume = libvirt_volume.os_disk[count.index].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      }
    ]
    graphics = [
      {
        vnc = {
          auto_port = true
          listen   = "127.0.0.1"
        }
      }
    ]
  }  

  running = true
}
