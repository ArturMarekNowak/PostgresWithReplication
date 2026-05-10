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

variable "postgres_vm_count" {
  description = "Number of postgres VMs"
  type        = number
  default     = 3
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  count = var.postgres_vm_count
  name  = "cloud_init_${count.index}"

  user_data      = file("${path.module}/user_data.yml")
  network_config = file("${path.module}/network_config.yml")

  meta_data = templatefile("${path.module}/meta_data.yml", {
    hostname = "postgres-${count.index}"
  })
}

resource "libvirt_volume" "cloud_init" {
  count = var.postgres_vm_count
  name  = "cloud_init_${count.index}.iso"
  pool  = "default"

  create = {
    content = {
      url = libvirt_cloudinit_disk.cloud_init[count.index].path
    }
  }
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
  count  = var.postgres_vm_count
  name   = "postgres-os-disk-${count.index}.qcow2"
  pool   = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }
  capacity = 21474836480

  backing_store = {
    path   = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_domain" "postgres" {
  count        = var.postgres_vm_count
  name         = "postgres-${count.index}"
  type         = "kvm"
  memory       = 4096
  memory_unit  = "MiB"
  vcpu         = 2
  
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
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloud_init[count.index].pool
            volume = libvirt_volume.cloud_init[count.index].name
          }
        }
        target = {
          bus = "sata"
          dev = "sda"
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
    consoles = [
      {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
  }  

  running = true
}
