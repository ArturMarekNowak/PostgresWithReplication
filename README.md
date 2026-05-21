# Postgres with replication

Aim of this project is to write a terraform script that runs 3 VMs with natively installed postgres with replication enabled and at least 1 VM running HAProxy that will direct traffic to the postgres databases with the usage of virtual IP. Project is still in progress

<div aling="center">
  <img src="docs/postgres_haproxy_vm_layout.svg" alt="vms_layout" width="50%">
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

## Milestones

~~1. Running 1 VM with a provider~~<br>
~~2. Running 3 VMs~~<br>
~~3. Applying proper IPv4 config to each VM~~<br>
~~4. Running 3 VMs with additional two mounts, one for postgres itself and one for patroni~~<br>
5. Running 3 VMs with postgres and patroni installed<br>
6. Running 4 VMs with postgres and 1 with HAProxy<br>
7. Configuration of virtual IP

## Troubleshooting

List of encountered solutions to the encountered problems:

https://github.com/dmacvicar/terraform-provider-libvirt/issues/1024#issuecomment-2660060520 <br>
https://github.com/dmacvicar/terraform-provider-libvirt/issues/1163
