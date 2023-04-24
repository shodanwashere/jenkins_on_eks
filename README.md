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
aws_region    ="Your AWS region"
cluster_name="The name of the cluster you want to deploy Jenkins in"
jenkins_namespace="The name of the namespace you want to create for Jenkins"
node_affinity_worker_hostname="The hostname of the worker node Jenkins should run on"
hosted_zone="name of the hosted zone domain you will host jenkins on"
private_zone=true|false # is the hosted zone private?
jenkins_vpc_id="id of the VPC Jenkins will be located inside of"
lb_arn="load balancer ARN"
lb_name="load balancer name"
lb_listener_arn="ARN of the load balancer listener"
tg_name="name of the target group that will be created"
tg_port=443 #port used for the new target group
tg_protocol="internal target group protocol"
worker_tag="value of the Name tag on the workers you want to use for the target group"
host_header_rule=["hh1.com","hh2.com",...] # List of host headers to which the load balancer listener rule should apply
subdomain="jenkins subdomain name"
```

## Usage

Start your module like this:
```
$ terraform init
```

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

## Forewarning

By default, this repo ships with a `.gitignore` which makes git ignore all `.tfvars` files. **You should keep it like this**. If you leak things like access and secret keys, cluster and namespace names, worker node hostnames, and anything else by uploading it to your repo, your infrastructure is prone to suffer harm.

Thankfully, AWS has counter-measures against Access Key and Secret Key leaking, and will lock down an account if it detects any of its keys have been made public on a repository.

Beware that this does not apply to worker node hostnames, cluster names or namespace names. **Take care of your infra like it's your own fucking child.** That was my PSA. Thank you for reading this.
