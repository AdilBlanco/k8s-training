variable "key" {}
variable "secret" {}
variable "key_pair" {}

variable "template" {
  default = "Linux Ubuntu 18.04 LTS 64-bit"
}
variable "node_number" {
  default = 3
}
variable "zone" {
  default = "ch-gva-2"
}
