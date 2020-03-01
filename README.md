# Self-healing Apache Zookeeper ECS cluster

## General information
This repo contains terraform code and docker file which will allow you to create self-healing Apache Zookeeper cluster into AWS ECS

## Usage
Terraform code can be found in `terraform` directory, just update variable.tf file with values related to your AWS VPC and execute `terraform plan && terraform apply`
 
Dockerfile for building custom Apache Zookeeper image can be found in `docker` directory. It contains only few custom changes in comparing to the original Apache Zookeeper dockerfile. The main one is generation of `myid` from ECS service name.

## Blog post
More details about this setup can be found at https://XXXXX