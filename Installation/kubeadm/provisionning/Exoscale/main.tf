provider "exoscale" {
  version = "~> 0.10"
  key = "${var.key}"
  secret = "${var.secret}"
}

# Create nodes
resource "exoscale_compute" "node" {
  count = "${var.node_number}"
  display_name = "node-${count.index+1}"
  template = "${var.template}"
  size = "Medium"
  disk_size = 20
  zone = "${var.zone}"
  key_pair = "${var.key_pair}"

  security_groups = ["${exoscale_security_group.default.name}"]
}

output "node" {
  value = "${exoscale_compute.node.*.ip_address}"
}

## Output
resource "template_file" "node_ansible" {
  count = "${var.node_number}"
  template = "$${name} $${ip}"
  vars {
    name  = "node-${count.index+1}"
    ip = "ansible_host=${element(exoscale_compute.node.*.ip_address, count.index)}"
  }
}

resource "template_dir" "inventory" {
  source_dir = "${path.module}/templates"
  destination_dir = "../../configuration/inventories/Exoscale"

  vars {
    nodes = "${join("\n",template_file.node_ansible.*.rendered)}"
  }
}
