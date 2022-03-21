
resource "tls_private_key" "ssh" {
  algorithm = var.ssh_key.algorithm
  rsa_bits  = var.ssh_key.rsa_bits
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = pathexpand("~/.ssh/${var.ssh_key.private_key_name}.pem")
  file_permission = var.ssh_key.file_permission
}

resource "null_resource" "clear_ssh_key_ubuntu" {
  count = var.ubuntu.count
  provisioner "local-exec" {
    command = var.dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.ubuntu[count.index].default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split("/", var.ubuntu_ip4_addresses[count.index])[0]}\" || true"
  }
}

resource "null_resource" "clear_ssh_dns" {
  count = 1
  provisioner "local-exec" {
    command = var.dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.dns[count.index].default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split("/", var.ubuntu_ip4_addresses[-1])[0]}\" || true"
  }
}