data "template_file" "network_dns" {
  count            = (var.dhcp == false ? 1 : 0)
  template = file("templates/network.template")
  vars = {
    if_name = var.dns.if_name
    ip4 = var.ubuntu_ip4_addresses[-1]
    gw4 = var.gateway4
    dns = var.nameservers
  }
}

data "template_file" "dns_userdata_static" {
  template = file("${path.module}/userdata/dns_static.userdata")
  count            = (var.dhcp == false ? 1 : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    netplanFile = var.dns.net_plan_file
    hostname = "${var.dns.basename}${random_string.id.result}${count.index}"
  }
}

data "template_file" "dns_userdata_dhcp" {
  template = file("${path.module}/userdata/dns_dhcp.userdata")
  count            = (var.dhcp == true ? 1 : 0)
  vars = {
    password      = var.ubuntu_password == null ? random_string.password.result : var.ubuntu_password
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    hostname = "${var.dns.basename}${random_string.id.result}${count.index}"
    keyName = var.dns.bind.key_name
    secret = base64encode(var.ubuntu_password == null ? random_string.password.result : var.ubuntu_password)
    domain = var.domain
    openshift_cidr = split("/", var.vcenter_network_openshift_cidr)[0]
    ocpname = var.openshift_cluster_name
    openshift_api_ip = var.openshift_api_ip
    openshift_ingress_ip = var.openshift_ingress_ip
  }
}

resource "vsphere_virtual_machine" "dns" {
  count            = 1
  name             = "${var.dns.basename}${random_string.id.result}${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
                      network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.dns.cpu
  memory = var.dns.memory
  wait_for_guest_net_routable = var.dns.wait_for_guest_net_routable
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.dns.disk
    label            = "${var.dns.basename}.lab_vmdk"
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
     hostname    = "${var.dns.basename}${random_string.id.result}${count.index}"
     public-keys = chomp(tls_private_key.ssh.public_key_openssh)
     user-data   = var.dhcp == false ? base64encode(data.template_file.dns_userdata_static[count.index].rendered) : base64encode(data.template_file.dns_userdata_dhcp[0].rendered)
   }
 }

  connection {
   host        = var.dhcp == false ? split("/", var.ubuntu_ip4_addresses[-1])[0] : self.default_ip_address
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