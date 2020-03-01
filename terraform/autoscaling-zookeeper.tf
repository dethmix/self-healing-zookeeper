resource "aws_autoscaling_group" "zookeeper" {
  name                 = "${var.project}"
  launch_configuration = "${aws_launch_configuration.zookeeper.name}"
  vpc_zone_identifier  = "${var.vpc_subnets}"
  min_size             = "${var.zookeeper-instance-number}"
  max_size             = "${var.zookeeper-instance-number}"
  desired_capacity     = "${var.zookeeper-instance-number}"
  
  tag {
    key                 = "autoscaling_group"
    value               = "${var.project}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project}"
    propagate_at_launch = true
  }

  depends_on = [
    "aws_launch_configuration.zookeeper",
  ]

}

data "template_file" "instance_user_data_zookeeper" {
  template = "${file("files/user_data.sh")}"

  vars {
    ecs_cluster_id       = "${aws_ecs_cluster.ecs.id}"
    ecs_cluster_name     = "${aws_ecs_cluster.ecs.name}"
    vpc_cidr             = "${var.vpc_cidr}"
    dns_zone             = "${var.dns_zone}"
  }
}

resource "aws_launch_configuration" "zookeeper" {
  name_prefix          = "${var.project}-"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.id}"
  key_name             = "${var.ssh_key_name}"

  security_groups = ["${aws_security_group.ecs.id}"]

  user_data = <<EOF
${data.template_file.instance_user_data_zookeeper.rendered}
EOF

  depends_on = [
    "aws_iam_instance_profile.ecs",
    "data.template_file.instance_user_data_zookeeper",
  ]

  image_id      = "${var.image_id}"
  instance_type = "${var.zookeeper_instance_type}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 32
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["image_id"]
  }
}
