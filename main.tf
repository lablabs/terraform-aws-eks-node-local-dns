/**
 * # AWS EKS Node Local DNS Terraform module
 *
 * A Terraform module to deploy the [Node Local DNS](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/) on Amazon EKS cluster. The upgrade process of this module is using the `create before destroy` feature, and the already running DaemonSet will be terminated after the new one is already running.
 *
 * [![Terraform validate](https://github.com/lablabs/terraform-aws-eks-node-local-dns/actions/workflows/validate.yaml/badge.svg)](https://github.com/lablabs/terraform-aws-eks-node-local-dns/actions/workflows/validate.yaml)
 * [![pre-commit](https://github.com/lablabs/terraform-aws-eks-node-local-dns/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/lablabs/terraform-aws-eks-node-local-dns/actions/workflows/pre-commit.yml)
 */
locals {
  addon = {
    name      = "node-local-dns"
    namespace = "kube-system"

    helm_chart_version = "2.1.0"
    helm_repo_url      = "https://lablabs.github.io/k8s-nodelocaldns-helm"
  }

  addon_values = yamlencode({
    podAnnotations = {
      "checksum/configmaps" = "" # when a ConfigMap is updated a new instance of the DaemonSet is created
    }
    config = {
      zones = {
        ".:53" = {
          plugins = {
            log = {
              classes = "error"
            }
            cache = {
              denial = { # disable negative caching
                size = 0
                ttl  = 1
              }
            }
            forward = {
              force_tcp = true
            }
            health = {
              port = 8080
            }
          }
        }
        "ip6.arpa:53" = {
          plugins = {
            log = {
              classes = "error"
            }
            forward = {
              force_tcp = true
            }
            health = {
              port = 8081
            }
          }
        }
        "in-addr.arpa:53" = {
          plugins = {
            log = {
              classes = "error"
            }
            forward = {
              force_tcp = true
            }
            health = {
              port = 8082
            }
          }
        }
      }
    }
  })

  # CUSTOM config: Prometheus port is not using SO_REUSEPORT so additional instance can't bind to the same port
  addon_metrics_values = yamlencode({
    metrics = {
      port = one(random_integer.metrics_port[*].result)
    }
  })

  addon_depends_on = []
}

resource "random_pet" "release_name_suffix" {
  count = var.enabled ? 1 : 0

  keepers = {
    version = coalesce(var.helm_chart_version, local.addon.helm_chart_version)
    values  = yamlencode([local.addon_values, var.values])
  }
}

resource "random_integer" "metrics_port" {
  count = var.enabled ? 1 : 0

  min = 1025
  max = 32667

  keepers = {
    values = one(random_pet.release_name_suffix[*].id)
  }
}
