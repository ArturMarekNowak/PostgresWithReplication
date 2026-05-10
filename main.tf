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

resource "libvirt_cloudinit_disk" "cloud_init" {
  name = "cloud_init"

  # User-data: Configure root password, enable SSH, install packages
  user_data = <<-EOF
    #cloud-config
    # Set root password to "password" (change this!)
    chpasswd:
      list: |
        root:password
      expire: false

    # Enable SSH password authentication
    ssh_pwauth: true

    # Install and enable SSH server
    packages:
      - openssh-server

    # Optional: Add SSH public key for key-based auth (more secure)
    # ssh_authorized_keys:
    #   - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0/Ho... your-key-here

    # Set timezone
    timezone: UTC

    # Final message on console
    final_message: "VM1 is ready! SSH: ssh root@<IP>"
  EOF

  # Meta-data: Instance identification
  meta_data = <<-EOF
    instance-id: vm1-001
    local-hostname: ubuntu-vm1
  EOF

  # Network config: Use DHCP (default behavior)
  network_config = <<-EOF
    version: 2
    ethernets:
      eth0:
        dhcp4: true
  EOF
}

resource "libvirt_volume" "cloud_init" {
  name = "cloud_init.iso"
  pool = "default"

  create = {
    content = {
      url = libvirt_cloudinit_disk.cloud_init.path
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
  count  = 3
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
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloud_init.pool
            volume = libvirt_volume.cloud_init.name
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
