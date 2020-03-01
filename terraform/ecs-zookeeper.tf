data "template_file" "ecs-zookeeper" {
  template = "${file("task-definitions/zookeeper.json")}"

  vars {
    zookeeper_image                  = "${var.zookeeper_image}:${var.zookeeper_image_version}"
    zookeeper_port                   = "${var.zookeeper_port}"
    zookeeper_port_communication     = "${var.zookeeper_port_communication}"
    zookeeper_port_election          = "${var.zookeeper_port_election}"
    zookeeper-servers                = "${var.zookeeper-servers}"
    zookeeper-elect-port-retry       = "${var.zookeeper-elect-port-retry}"
    zookeeper_4lw_commands_whitelist = "${var.zookeeper_4lw_commands_whitelist}"
  }
}

resource "aws_ecs_task_definition" "ecs-zookeeper" {
  family                = "${var.project}"
  container_definitions = "${data.template_file.ecs-zookeeper.rendered}"
  network_mode          = "awsvpc"
  volume {
    name      = "resolv"
    host_path = "/etc/docker_resolv.conf"
  }
}

resource "aws_ecs_service" "ecs-zookeeper" {
  name = "${var.project}${count.index+1}"
  cluster         = "${aws_ecs_cluster.ecs.id}"
  task_definition = "${aws_ecs_task_definition.ecs-zookeeper.arn}"
  enable_ecs_managed_tags = true
  desired_count = 1
  propagate_tags = "SERVICE"
  # only manual task rotation via task stop
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 100
  network_configuration {
    subnets          = "${var.vpc_subnets}"
    security_groups  = ["${aws_security_group.ecs.id}"]
    assign_public_ip = false
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.discovery_service-zookeeper.*.arn[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
  count = "${var.zookeeper-instance-number}"
}

resource "aws_service_discovery_service" "discovery_service-zookeeper" {
  name = "${var.project}${count.index+1}"

  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.discovery_namespace.id}"

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
  count = "${var.zookeeper-instance-number}"
}