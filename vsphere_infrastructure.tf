#
data "vsphere_datacenter" "dc" {
  name = var.vcenter.dc
}
#
data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
#
data "vsphere_datastore" "datastore" {
  name = var.vcenter.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
#
data "vsphere_resource_pool" "pool" {
  name          = var.vcenter.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}
#
data "vsphere_network" "network" {
  name = var.vcenter.network
  datacenter_id = data.vsphere_datacenter.dc.id
}
#
resource "vsphere_folder" "folder" {
  path          = "${var.vcenter_folder}-${random_string.id.result}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}