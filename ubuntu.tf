resource "random_string" "ubuntu_password" {
  length           = 12
  special          = true
  min_lower        = 3
  min_upper        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "%$&*_"
}

data "template_file" "network" {
  count            = (var.dhcp == false ? length(var.ubuntu_ip4_addresses) : 0)
  template = file("templates/network.template")
  vars = {
    if_name = var.ubuntu.if_name
    ip4 = var.ubuntu_ip4_addresses[count.index]
    gw4 = var.gateway4
    dns = var.nameservers
  }
}

data "template_file" "ubuntu_userdata_static" {
  template = file("${path.module}/userdata/ubuntu_static.userdata")
  count            = (var.dhcp == false ? length(var.ubuntu_ip4_addresses) : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    netplanFile = var.ubuntu.netplanFile
    hostname = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
    network_config  = base64encode(data.template_file.network[count.index].rendered)
  }
}

resource "vsphere_virtual_machine" "ubuntu" {
  count            = var.dhcp == false ? length(var.ubuntu_ip4_addresses) : var.ubuntu.count
  name             = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  network_interface {
                      network_id = data.vsphere_network.network.id
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
    template_uuid = vsphere_content_library_item.file.id
  }

  vapp {
    properties = {
     hostname    = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
     public-keys = chomp(tls_private_key.ssh.public_key_openssh)
     user-data   = var.dhcp == false ? base64encode(data.template_file.ubuntu_userdata_static[count.index].rendered) : base64encode(data.template_file.ubuntu_userdata_dhcp[0].rendered)
   }
 }

  connection {
   host        = var.dhcp == false ? split("/", var.ubuntu_ip4_addresses[count.index])[0] : self.default_ip_address
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

data "template_file" "ubuntu_userdata_dhcp" {
  template = file("${path.module}/userdata/ubuntu_dhcp.userdata")
  count            = (var.dhcp == true ? 1 : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.ubuntu_password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    hostname = "${var.ubuntu.basename}${random_string.id.result}${count.index}"
  }
}