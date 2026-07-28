variable "postgres_vm_count" {
  description = "Number of postgres instances"
  type        = number
  default     = 3
}

variable "subnet_id" {
  description = "Subnet ID to launch postgres instances into"
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

data "aws_subnet" "selected" {
  id = var.subnet_id
}

# Allocate fixed private IPs so nodes can reference each other before boot
resource "aws_network_interface" "postgres" {
  count     = var.postgres_vm_count
  subnet_id = var.subnet_id

  tags = {
    Name = "postgres-nic-${count.index}"
  }
}

locals {
  # Collect the private IPs once the NICs are allocated
  node_ips   = [for nic in aws_network_interface.postgres : nic.private_ip]
  etcd_hosts = join(",", [for ip in local.node_ips : "${ip}:2379"])
}

resource "aws_instance" "postgres" {
  count         = var.postgres_vm_count
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.postgres[count.index].id
    device_index         = 0
  }

  user_data = templatefile("${path.module}/../cloudInit/user_data.yml", {
    hostname     = "postgres-${count.index}"
    ca_crt       = filebase64("${path.module}/../certs/etcd/ca.crt")
    node_crt     = filebase64("${path.module}/../certs/etcd/etcd${count.index}.crt")
    node_key     = filebase64("${path.module}/../certs/etcd/etcd${count.index}.key")
    server_crt   = filebase64("${path.module}/../certs/postgres/server.crt")
    server_key   = filebase64("${path.module}/../certs/postgres/server.key")
    server_req   = filebase64("${path.module}/../certs/postgres/server.req")
    patroni_cnf  = base64encode(templatefile("${path.module}/../patroni/config.yml.tpl", {
      node_index           = count.index
      node_ip              = local.node_ips[count.index]
      node_ips             = local.node_ips
      etcd_hosts           = local.etcd_hosts
      superuser_password   = var.superuser_password
      replication_password = var.replication_password
    }))
    etcd_env     = base64encode(templatefile("${path.module}/../etcd/etcd.env.tpl", {
      node_index      = count.index
      node_ip         = local.node_ips[count.index]
      initial_cluster = join(",", [for i, ip in local.node_ips : "postgresql-${i}=https://${ip}:2380"])
    }))
    etcd_service = filebase64("${path.module}/../etcd/etcd.service")
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "postgres-${count.index}"
  }
}

# vdb equivalent — 20 GB data disk
resource "aws_ebs_volume" "data_vdb" {
  count             = var.postgres_vm_count
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = 20
  type              = "gp3"

  tags = { Name = "postgres-data-vdb-${count.index}" }
}

resource "aws_volume_attachment" "data_vdb" {
  count       = var.postgres_vm_count
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.data_vdb[count.index].id
  instance_id = aws_instance.postgres[count.index].id
}

# vdc equivalent — 5 GB data disk
resource "aws_ebs_volume" "data_vdc" {
  count             = var.postgres_vm_count
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = 5
  type              = "gp3"

  tags = { Name = "postgres-data-vdc-${count.index}" }
}

resource "aws_volume_attachment" "data_vdc" {
  count       = var.postgres_vm_count
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.data_vdc[count.index].id
  instance_id = aws_instance.postgres[count.index].id
}
