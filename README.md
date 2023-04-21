# Jenkins on EKS
This is a module that deploys Jenkins to an EKS cluster, without using Helm. It is completely based on the Jenkins [Kubernetes Deployment docs](https://www.jenkins.io/doc/book/installing/kubernetes/).

## Pre-requisites
This module was written based on **Terraform 1.3.6**. I don't know if there are any breaking changes between that version and the most recent one, but in case there are, updates will ensue.

You should have your AWS configured before hand.

```
$ aws configure
AWS Access Key ID [None]: ***********
AWS Secret Access Key [None]: *************************
Default region name [None]: **-*****-*
Default output [None]:
```

## Configuration

You should create a `terraform.tfvars` file before you move on. Here are the variables you'll need to configure:

```
aws_access_key="Your AWS access key ID"
aws_secret_key="Your AWS secret access key"
cluster_name="The name of the cluster you want to deploy Jenkins in"
jenkins_namespace="The name of the namespace you want to create for Jenkins"
node_affinity_worker_hostname="The hostname of the worker node Jenkins should run on"
```

## Usage

To check what changes will happen (and see if you configured your variables correctly):
```
$ terraform plan
```

To apply the infrastructure:
```
$ terraform apply
```

To destroy the infrastructure:
```
$ terraform destroy
```