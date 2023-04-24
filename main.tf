###
#   Terraform -> Jenkins on EKS
#   By: Nuno Dias @ CELFOCUS AppSec
#
#   
#
#   Written using the following docs:
#   - https://www.jenkins.io/doc/book/installing/kubernetes/
#   - https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
#   - https://registry.terraform.io/providers/hashicorp/aws/latest/docs
###

terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "~> 2.0"
        }

        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    # TODO: Config options for the specific AWS account
    region = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    # Use variables file that is included in a .gitignore #
}

data "aws_eks_cluster" "cluster" {
    name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks_auth" {
    name = var.cluster_name
}

data "aws_route53_zone" "zone" {
    name = var.hosted_zone
    private_zone = var.private_zone
}

data "aws_lb" "load_balancer" {
    arn = var.lb_arn
    name = var.lb_name
}

data "aws_lb_listener" "https443"{
    arn = var.lb_listener_arn
}

data "aws_vpc" "jenkins_vpc" {
    id = var.jenkins_vpc_id
}

resource "aws_lb_target_group" "jenkins_tg"{
    name = var.tg_name
    port = var.tg_port
    protocol = var.tg_protocol
    target_type = "instance"
    vpc_id = data.aws_vpc.jenkins_vpc.id
}

data "aws_instances" "workers" {
    instance_tags = {
        Name = var.worker_tag
    }

    instance_state_names = ["running"]
}

data "aws_instance" "worker_instances" {
    count = length(data.aws_instances.workers.ids)
    instance_id = data.aws_instances.workers.ids[count.index]
}

resource "aws_lb_target_group_attachment" "tg_attachs" {
    count = length(data.aws_instances.workers.ids)
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
    target_id = data.aws_instances.workers.ids[count.index]
    port = 32000
}

resource "aws_lb_listener_rule" "jenkins_elb_rule" {
    listener_arn = data.aws_lb_listener.https443.arn

    condition {
        host_header {
            values = var.host_header_rule
        }
    }

    condition {
        path_pattern {
            values = ["/*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.jenkins_tg.arn
    }
}

resource "aws_route53_record" "jenkins_record" {
    zone_id = data.aws_route53_zone.zone.zone_id
    name    = "${var.subdomain}.${data.aws_route53_zone.zone.name}"
    type    = "A"

    alias {
        name    = data.aws_lb.load_balancer.dns_name
        zone_id = data.aws_lb.load_balancer.zone_id
        evaluate_target_health = true
    }
}

provider "kubernetes" {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_auth.token
}

# comment if namespace already exists
resource "kubernetes_namespace" "jenkins_ns" {
    metadata {
      annotations = {
        name = "example-annotation"
      }

      labels = {
        mylabel = "label-value"
      }

      name = var.jenkins_namespace
    }
}

resource "kubernetes_cluster_role" "jenkins_cr" {
    metadata {
      name = "jenkins-admin"
    }

    rule {
        api_groups = [""]
        resources  = ["*"]
        verbs      = ["*"]
    }
}

resource "kubernetes_service_account_v1" "jenkins_sa" {
    metadata {
      name = "jenkins-admin"
      namespace = var.jenkins_namespace
    }
}

resource "kubernetes_cluster_role_binding" "jenkins_crb" {
    metadata {
      name = "jenkins-admin"
    }

    role_ref {
      api_group = "rbac.authorization.k8s.io"
      kind      = "ClusterRole"
      name      = "jenkins-admin"
    }

    subject {
      kind      = "ServiceAccount"
      name      = "jenkins-admin"
      namespace = var.jenkins_namespace
    }
}

resource "kubernetes_storage_class_v1" "jenkins_sc" {
  metadata {
    name = "local-storage"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_persistent_volume_v1" "jenkins_pv" {
    metadata {
        name = "jenkins-pv-volume"
        labels = {
          type = "local"
        }
    }

    spec {
        storage_class_name = "local-storage"
        
        claim_ref {
            name = "jenkins-pv-claim"
            namespace = var.jenkins_namespace
        }

        capacity = {
          storage = "10Gi"
        }

        access_modes = ["ReadWriteOnce"]

        node_affinity {
            required {
                node_selector_term {
                    match_expressions {
                        key = "kubernetes.io/hostname"
                        operator = "In"
                        values = [ for w in data.aws_instance.worker_instances : w.private_dns ]
                    }
                }
            }
        }

        persistent_volume_source {
            local {
                path = "/mnt"
            }
        }
    }
}

resource "kubernetes_persistent_volume_claim_v1" "jenkins_pvc" {
    metadata {
        name      = "jenkins-pv-claim"
        namespace = var.jenkins_namespace
    }

    spec {
        storage_class_name = "local-storage"
        access_modes       = ["ReadWriteOnce"]
        resources {
            requests = {
                storage = "3Gi"
            }
        }
    }
}

resource "kubernetes_deployment_v1" "jenkins_deploy" {
    wait_for_rollout = true

    metadata {
      name = "jenkins"
      namespace = var.jenkins_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "jenkins-server"
            }
        }

        template {
            metadata {
                labels = {
                    app = "jenkins-server"
                }
            }
            spec {

                security_context {
                    fs_group = 1000
                    run_as_user = 1000
                }

                service_account_name = "jenkins-admin"

                container {
                    name = "jenkins"
                    image = "jenkins/jenkins:lts"

                    resources {
                        limits = {
                            memory = "2Gi"
                            cpu    = "1000m"
                        }
                        requests = {
                            memory = "500Mi"
                            cpu    = "500m"
                        }
                    }
                    
                    port {
                        name = "httpport"
                        container_port = 8080
                    }

                    port {
                        name = "jnlport"
                        container_port = 50000
                    }

                    liveness_probe {
                        http_get {
                            path = "/login"
                            port = 8080
                        }

                        initial_delay_seconds = 90
                        period_seconds = 10
                        timeout_seconds = 5
                        failure_threshold = 5
                    }

                    readiness_probe {
                        http_get {
                            path = "/login"
                            port = 8080
                        }
                        initial_delay_seconds = 60
                        period_seconds = 10
                        timeout_seconds = 5
                        failure_threshold = 3
                    }

                    volume_mount {
                        name = "jenkins-data"
                        mount_path = "/var/jenkins_home"
                    }
                }

                volume {
                    name = "jenkins-data"
                    persistent_volume_claim {
                        claim_name = "jenkins-pv-claim"
                    }
                }
            }
        }
    }
}

resource "kubernetes_service_v1" "jenkins-srv" {
    metadata {
        name = "jenkins-service"
        namespace = var.jenkins_namespace
        annotations = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/path"   = "/"
            "prometheus.io/port"   = "8080"
        }
    }

    spec {
        selector = {
            app = "jenkins-server"
        }
        type = "NodePort"
        port {
            port = 8080
            target_port = 8080
            node_port = "32000"
        }
    }
}