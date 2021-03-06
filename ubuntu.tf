
//data "template_file" "network" {
//  count            = (var.dhcp == false ? var.ubuntu.count : 0)
//  template = file("templates/network.template")
//  vars = {
//    if_name = var.ubuntu.if_name
//    ip4 = var.ubuntu_ip4_addresses[count.index]
//    gw4 = var.gateway4
//    dns = var.nameservers
//  }
//}

data "template_file" "network_dhcp_static" {
  template = file("templates/network_ubuntu_dhcp.template")
  vars = {
    dns_ip = vsphere_virtual_machine.dns[0].default_ip_address
  }
}

//data "template_file" "ubuntu_userdata_static" {
//  template = file("${path.module}/userdata/ubuntu_static.userdata")
//  count            = (var.dhcp == false ? var.ubuntu.count : 0)
//  vars = {
//    password      = var.ubuntu_password == null ? random_string.password.result : var.ubuntu_password
//    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
//    net_plan_file = var.ubuntu.net_plan_file
//    hostname = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
//  }
//}

data "template_file" "ubuntu_userdata_dhcp" {
  template = file("${path.module}/userdata/ubuntu_dhcp.userdata")
  count            = (var.dhcp == true ? 1 : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    hostname = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
    ansible_core_version = var.ansible.version.ansible-core
    ansible_version = var.ansible.version.ansible
    avi_sdk_version = var.avi_version
    username = var.ubuntu.username
//    private_key = tls_private_key.ssh.private_key_pem
    network_config  = base64encode(data.template_file.network_dhcp_static.rendered)
    net_plan_file = var.ubuntu.net_plan_file
    vcenter_server = var.vsphere_server
  }
}

resource "vsphere_virtual_machine" "ubuntu" {
  count            = 1
  name             = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
                      network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.ubuntu.cpu
  memory = var.ubuntu.memory
  wait_for_guest_net_routable = var.ubuntu.wait_for_guest_net_routable
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.ubuntu.disk
    label            = "${var.ubuntu.basename}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_ubuntu.id
  }

  vapp {
    properties = {
     hostname    = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
     public-keys = chomp(tls_private_key.ssh.public_key_openssh)
     user-data   = base64encode(data.template_file.ubuntu_userdata_dhcp[0].rendered)
   }
 }

  connection {
   host        = self.default_ip_address
   type        = "ssh"
   agent       = false
   user        = "ubuntu"
   private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }
}

//resource "null_resource" "add_nic_to_ubuntu" {
//  depends_on = [vsphere_virtual_machine.ubuntu]
//  count            = 1
//
//  provisioner "local-exec" {
//    command = <<-EOT
//      export GOVC_USERNAME=${var.vsphere_username}
//      export GOVC_PASSWORD=${var.vsphere_password}
//      export GOVC_DATACENTER=${var.vcenter_dc}
//      export GOVC_URL=${var.vsphere_server}
//      export GOVC_CLUSTER=${var.vcenter_cluster}
//      export GOVC_INSECURE=true
//      /usr/local/bin/govc vm.network.add -vm "${var.ubuntu.basename}${random_string.id.result}${count.index}" -net "${var.vcenter_network_openshift_name}"
//    EOT
//  }
//}

resource "null_resource" "ubuntu_networking" {
  depends_on = [vsphere_virtual_machine.ubuntu]

  connection {
    host = vsphere_virtual_machine.ubuntu[0].default_ip_address
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
//      "if_secondary_name=$(sudo dmesg | grep eth0 | tail -1 | awk -F' ' '{print $5}' | sed 's/://')",
//      "sudo sed -i -e \"s/if_name_secondary_to_be_replaced/\"$if_secondary_name\"/g\" /tmp/50-cloud-init.yaml",
      "sudo cp /tmp/50-cloud-init.yaml ${var.ubuntu.net_plan_file}",
      "sudo netplan apply"
    ]
  }
}