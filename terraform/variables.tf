variable "aws_region" {
  default = "us-east-1"
}

variable "zookeeper_image" {
  default = "dpavlovsmartling/zookeeper-35-ecs"
}

variable "zookeeper_instance_type" {
  default = "t3.small"
}
variable "zookeeper_image_version" {
   default = "latest"
}

variable "zookeeper_port" {
  default = "2181"
}
variable "zookeeper_port_communication" {
  default = "2888"
}

variable "zookeeper_port_election" {
  default = "3888"
}

variable "zookeeper-instance-number" {
  default = 3
}

variable "zookeeper-elect-port-retry" {
  default     = 999
}

variable "zookeeper_4lw_commands_whitelist" {
  default = "*"
}

variable "zookeeper-servers" {
  default = "server.1=zookeeper1.zoo.test:2888:3888;2181 server.2=zookeeper2.zoo.test:2888:3888;2181 server.3=zookeeper3.zoo.test:2888:3888;2181"
}

variable "dns_zone" {
  description = "DNS zone for autodiscovery"
  default     = "zoo.test"
}

variable "vpc_id" {
  default = "vpc-XXXXXXXXXX"
  description = "used for discovery namespace"
}

variable "vpc_subnets" {
  default = ["subnet-XXXXXXXX"]
}

variable "vpc_cidr" {
  default = "XX.XX.XX.XX/YY"
}
variable "project" {
  default = "zookeeper"
}

variable "image_id" {
  default = "ami-XXXXXXXXX"
}

variable "ssh_key_name" {
  default = "XXXXXXXXX"
}
