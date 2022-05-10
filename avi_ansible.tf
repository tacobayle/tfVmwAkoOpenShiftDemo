
data "template_file" "avi_yaml_values" {
  template = file("templates/avi_yaml_values.yml.template")
  vars = {
    controller_ip = vsphere_virtual_machine.controller_dhcp[0].default_ip_address
    controller_ntp = jsonencode(var.controller.ntp)
    controller_dns = jsonencode(var.controller.dns)
    avi_password = var.avi_password
    avi_old_password = var.avi_old_password
    avi_version = var.avi_version
    avi_username = var.avi_username
    vsphere_username = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    domains = jsonencode(var.avi.config.vcenter.domains)
    cloud_name = var.avi.config.vcenter.cloud.name
    dc = var.vcenter_dc
    dchp_enabled = jsonencode(var.avi.config.vcenter.cloud.dhcp_enabled)
    network_management = jsonencode(var.avi.config.vcenter.cloud.network_management)
    network_vip = jsonencode(var.avi.config.vcenter.cloud.network_vip)
    network_backend = jsonencode(var.avi.config.vcenter.cloud.network_backend)
    service_engine_groups = jsonencode(var.avi.config.vcenter.service_engine_groups)
    pools = jsonencode(var.avi.config.vcenter.pools)
    pool_groups = jsonencode(var.avi.config.vcenter.pool_groups)
    virtual_services = jsonencode(var.avi.config.vcenter.virtual_services)
  }
}

resource "null_resource" "ansible" {
  depends_on = [
    vsphere_virtual_machine.ubuntu,
    vsphere_virtual_machine.controller_dhcp]

  connection {
    host = vsphere_virtual_machine.ubuntu[0].default_ip_address
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    content = data.template_file.avi_yaml_values.rendered
    destination = "avi_yaml_values.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ansible",
      "cd ~/ansible ; git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag}; cd ${split("/", var.ansible.aviConfigureUrl)[4]}",
      "ansible-playbook vcenter.yml --extra-vars @../../avi_yaml_values.yml"
    ]
  }
}