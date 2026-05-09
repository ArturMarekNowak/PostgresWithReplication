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
  name   = "ubuntu-22.04.qcow2"
  pool   = "default"
  
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    }
  }
}

resource "libvirt_volume" "vm_disks" {
  count          = 3
  name           = "postgres-disk-${count.index}.qcow2"
  pool           = "default"
  capacity       = 10 * 1024 * 1024 * 1024
}


resource "libvirt_domain" "postgres" {
  name         = "postgres-${count.index}"
  type         = "kvm"
  memory       = 2048
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
            pool   = "default"
            volume = libvirt_volume.vm_disks[count.index].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      }
    ]
  }  

  running = true
}
