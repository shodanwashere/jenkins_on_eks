variable "aws_access_key" {
    type = string
    description = "Your AWS Access Key ID"
}

variable "aws_secret_key" {
    type = string
    description = "Your AWS Secret Access Key"
}

variable "aws_region" {
    type = string
    description = "Your AWS region"
}

variable "cluster_name" {
    type = string
    description = "Your EKS Cluster name"
}

variable "jenkins_namespace" {
    type = string
    description = "Namespace in which Jenkins will be deployed"
    default="devops-tools"
}

variable "hosted_zone" {
    type = string
    description = "name of the domain hosted zone you will have jenkins accessible on"
}

variable "private_zone" {
    type = bool
    description = "is the hosted zone private?"
}

variable "jenkins_vpc_id" {
    type = string
    description = "id of the VPC jenkins will be located inside of"
}

variable "lb_arn" {
    type = string
    description = "load balancer ARN"
}

variable "lb_name" {
    type = string
    description = "load balancer name"
}

variable "lb_listener_arn" {
    type = string
    description = "arn of the load balancer listener"
}

variable "tg_name" {
    type = string
    description = "name of the target group that will be created"
    default = "jenkins-tg"
}

variable "tg_port" {
    type=number
    description = "port used for the new target group"
}

variable "tg_protocol" {
    type = string
    description = "target group protocol"
}

variable "worker_tag"{
    type = string
    description = "value of the Name tag on the workers you want to use for the target group"
}

variable "host_header_rule"{
    type=list(string)
    description="List of host headers to which the load balancer listener rule should apply"
}

variable "subdomain"{
    type = string
    description = "subdomain name"
    default="jenkins"
}