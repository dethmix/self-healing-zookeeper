provider "aws" {
  region      = "${var.aws_region}"
  max_retries = 5
  version     = ">= 1.40.0"
}
