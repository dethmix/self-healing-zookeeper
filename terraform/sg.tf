
resource "aws_security_group" "ecs" {
  name = "${var.project}"
  description = "${var.project} security group"
  vpc_id = "${var.vpc_id}"
  tags {
    Name = "${var.project}"
    Description = "SG for ${var.project}"
    Project     = "${var.project}"
  }
}

resource "aws_security_group_rule" "ecs_egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = "${aws_security_group.ecs.id}"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Egress rule for ${var.project}"
}

resource "aws_security_group_rule" "ecs_self" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  self = true
  security_group_id = "${aws_security_group.ecs.id}"
  description = "Allow all communications inside security group"
}