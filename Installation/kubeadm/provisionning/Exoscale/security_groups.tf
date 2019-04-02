resource "exoscale_security_group" "default" {
  name = "k8s"
  description = "K8S Security Group"
}

resource "exoscale_security_group_rule" "default" {
  type = "INGRESS"
  security_group_id = "${exoscale_security_group.default.id}"
  protocol = "TCP"
  start_port = 0
  end_port = 65000
  cidr = "0.0.0.0/0"
}
