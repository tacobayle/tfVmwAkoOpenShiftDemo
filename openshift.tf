data "template_file" "install_config" {
  template = file("templates/install-config.yaml.template")
  vars = {
    name = var.openshift_cluster_name
    apiVIP = var.openshift_api_ip
    cluster  = var.vcenter_cluster
    datacenter = var.vcenter_dc
    datastore = var.vcenter_datastore
    ingressVIP = var.openshift_ingress_ip
    network = var.vcenter_network_mgmt_name
    password = var.vsphere_password
    username = var.vsphere_username
    vCenter = var.vsphere_server
    folder_name = "${var.vcenter_folder}-${random_string.id.result}"
    pullSecret = var.openshift_pull_secret
  }
}

resource "null_resource" "install_openshift" {
  count = 1
  connection {
    host = var.dhcp == false ? split("/", var.ubuntu_ip4_addresses[count.index])[0] : vsphere_virtual_machine.ubuntu[0].default_ip_address
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "cat > install-config.yaml <<EOL\n${data.template_file.install_config.rendered}\nEOL"
    ]
  }

  provisioner "file" {
    source = "bin/openshift-install-linux.tar.gz"
    destination = "openshift-install-linux.tar.gz"
  }

  provisioner "remote-exec" {
    inline      = [
      "tar -xvf openshift-install-linux.tar.gz"
    ]
  }
}