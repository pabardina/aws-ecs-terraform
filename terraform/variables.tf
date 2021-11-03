# variables.tf

variable "aws_region" {
  description = "The AWS region things are created in"
  default     = "ca-central-1"
}

variable "environments" {
  type = set(string)
  default = ["dev", "prod"]
}

variable "alb_tls_cert_arn" {
  description = "arn of the certificate"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "digitalocean/flask-helloworld:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 5000
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "health_check_path" {
  default = "/"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "alarm_email" {
  default = "fake@fakemail.fake"
}

