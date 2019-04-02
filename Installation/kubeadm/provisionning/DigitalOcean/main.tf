# Configure the DigitalOcean Provider
provider "digitalocean" {
    token = "${var.token}"
}

# Create nodes
resource "digitalocean_droplet" "node" {
  count = "${var.node_number}"
  image = "${var.image}"
  name = "node-${count.index+1}"
  region = "${var.region}"
  size = "${var.size}"
}
output "node" {
  value = "${digitalocean_droplet.node.*.ipv4_address}"
}

## Output
resource "template_file" "node_ansible" {
  count = "${var.node_number}"
  template = "$${name} $${ip}"
  vars {
    name  = "node-${count.index+1}"
    ip = "ansible_host=${element(digitalocean_droplet.node.*.ipv4_address, count.index)}"
  }
}

resource "template_dir" "inventory" {
  source_dir = "${path.module}/templates"
  destination_dir = "../../configuration/inventories/DigitalOcean"

  vars {
    nodes = "${join("\n",template_file.node_ansible.*.rendered)}"
  }
}
