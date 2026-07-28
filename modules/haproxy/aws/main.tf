variable "haproxy_vm_count" {
  description = "Number of haproxy instances"
  type        = number
  default     = 2
}

variable "subnet_id" {
  description = "Subnet ID to launch haproxy instances into"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 24.04 AMI ID for the target region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
}

resource "aws_network_interface" "haproxy" {
  count     = var.haproxy_vm_count
  subnet_id = var.subnet_id

  tags = {
    Name = "haproxy-nic-${count.index}"
  }
}

resource "aws_instance" "haproxy" {
  count         = var.haproxy_vm_count
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.haproxy[count.index].id
    device_index         = 0
  }

  user_data = templatefile("${path.module}/cloudInit/user_data.yml", {
    hostname       = "haproxy-${count.index}"
    keepalived_cnf = filebase64("${path.module}/keepalived/keepalived-vm-0${count.index}.conf")
    check_haproxy  = filebase64("${path.module}/haproxy/check_haproxy.sh")
    haproxy_cnf    = filebase64("${path.module}/haproxy/haproxy.cfg")
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "haproxy-${count.index}"
  }
}
