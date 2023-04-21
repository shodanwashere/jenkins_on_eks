variable "aws_access_key" {
    type = string
    description = "Your AWS Access Key ID"
}

variable "aws_secret_key" {
    type = string
    description = "Your AWS Secret Access Key"
}

variable "cluster_name" {
    type = string
    description = "Your EKS Cluster name"
}

variable "jenkins_namespace" {
    type = string
    description = "Namespace in which Jenkins will be deployed"
}

variable "node_affinity_worker_hostname" {
    type = string
    description = "Worker hostname to be used in the persistent volume node affinity"
}