# terraformVmwUbuntu

## Goal
Spin up x Ubuntu host (with a basic apache server) in vCenter from content library based on Terraform

## Prerequisites:
- Make sure terraform in installed in the orchestrator VM
- Make sure your orchestrator VM has Internet Access  
- Make sure VMware credential/details are configured as environment variable for Vcenter:
```
export TF_VAR_vsphere_username=******
export TF_VAR_vsphere_password=******
```
- Optionally, you can set the following environment variable, if set, this will be used as a password otherwise the password will be automatically generated:
```
export TF_VAR_ubuntu_password=******
```

## Environment:

Terraform Plan has/have been tested against:

### terraform

```
Terraform v0.13.1
+ provider registry.terraform.io/hashicorp/null v2.1.2
+ provider registry.terraform.io/hashicorp/template v2.1.2
+ provider registry.terraform.io/hashicorp/vsphere v1.24.0
+ provider registry.terraform.io/terraform-providers/nsxt v3.0.1
Your version of Terraform is out of date! The latest version is 0.13.2. You can update by downloading from https://www.terraform.io/downloads.html
```

### V-center/ESXi version:
```
vCSA - 7.0.0 Build 16749670
ESXi host - 7.0.0 Build 16324942
```

## Input/Parameters:
- All the variables are stored in variables.tf
- variables.tf is an example for DHCP
  - if dhcp is enabled (var.dhcp is true), amount of VM(s) is defined is var.ubuntu.count
- variables.tf.static is an example for static IP
  - if dhcp is disabled (var.dhcp is false), amount of VM(s) is defined by the amount of IPs in var.ubuntu_ip4_addresses (["10.206.112.56/22", "10.206.112.57/22"])

## Run the terraform plan:
```
git clone https://github.com/tacobayle/terraformVmwUbuntu ; cd terraformVmwUbuntu ; terraform init ; terraform apply -auto-approve
```

## Outputs:
- IP(s) of the VM (dhcp or static)
- Ssh username of the VM
- Ssh password
- Ssh private key file path