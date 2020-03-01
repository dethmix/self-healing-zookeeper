resource "aws_service_discovery_private_dns_namespace" "discovery_namespace" {
  name        = "${var.dns_zone}"
  description = "Discovery namespace for ${var.project}"
  vpc         = "${var.vpc_id}"
}
