# Postgres with replication

Aim of this project is to write a terraform script that runs 3 VMs with natively installed postgres with replication enabled and at least 1 VM running HAProxy that will direct traffic to the postgres databases with the usage of virtual IP

<div aling="center">
  <img src="docs/postgres_haproxy_vm_layout.svg" alt="vms_layout">
</div>

I was inspired by the Techno Tim's youtube video: 
<div align="center">
<a href="https://www.youtube.com/watch?v=RHwglGf_z40">
  <img src="https://img.youtube.com/vi/RHwglGf_z40/maxresdefault.jpg" alt="Techno Tim Video" width="50%">
</a>
</div>

## Table of contents
* [Requirements](#requirements)
* [Quickstartup](#quickstartup)
* [Milestones](#milestones)
* [Troubleshooting](#troubleshooting)

## Requirements

1. qemu-kvm installed
2. terraform installed

## Quickstartup

Run terraform init:

`terraform init` 

Run VMs:

`terraform apply`

To cleanup:

`terraform destroy`

## Troubleshooting

List of encountered solutions to the encountered problems:

https://github.com/dmacvicar/terraform-provider-libvirt/issues/1024#issuecomment-2660060520 <br>
https://github.com/dmacvicar/terraform-provider-libvirt/issues/1163
