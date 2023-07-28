locals {
  values_default = yamlencode({
    "config" : {
      "localDnsIp" : "169.254.20.11",
      "zones" : {
        ".:53" : {
          "plugins" : {
            "errors" : true,
            "reload" : true,
            "debug" : false,
            "log" : {
              "format" : "combined",
              "classes" : "all"
            },
            "cache" : {
              "parameters" : 30,
              "denial" : {
                size : 0,
                ttl : 1
              },
              "success" : {},
              "prefetch" : {},
              "serve_stale" : false
            },
            "forward" : {
              "parameters" : "172.20.0.10",
              "force_tcp" : true,
              "prefer_udp" : false,
              "policy" : "",
              "max_fails" : "",
              "expire" : "",
              "health_check" : "",
              "except" : ""
            },
            "prometheus" : true,
            "health" : {
              "port" : 8080
            }
          }
        },
        "ip6.arpa:53" : {
          "plugins" : {
            "errors" : true,
            "reload" : true,
            "debug" : false,
            "log" : {
              "classes" : "error"
            },
            "cache" : {
              "parameters" : 30
            },
            "forward" : {
              "parameters" : "172.20.0.10",
              "force_tcp" : true
            },
            "prometheus" : true,
            "health" : {
              "port" : 8081
            }
          }
        },
        "in-addr.arpa:53" : {
          "plugins" : {
            "errors" : true,
            "reload" : true,
            "debug" : false,
            "log" : {
              "classes" : "error"
            },
            "cache" : {
              "parameters" : 30
            },
            "forward" : {
              "parameters" : "172.20.0.10",
              "force_tcp" : true
            },
            "prometheus" : true,
            "health" : {
              "port" : 8082
            }
          }
        }
      }
    },
    "useHostNetwork" : true,
    "priorityClassName" : "system-node-critical",
    "podAnnotations" : {},
    "podSecurityContext" : {},
    "securityContext" : {
      "privileged" : true
    },
    "readinessProbe" : null,
    "serviceAccount" : {
      "create" : true,
      "annotations" : {
        "eks.amazonaws.com/role-arn" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.this[0].name}"
      },
      "name" : var.service_account_name
    },
    "affinity" : {},
    "tolerations" : [
      {
        "key" : "CriticalAddonsOnly",
        "operator" : "Exists"
      },
      {
        "effect" : "NoExecute",
        "operator" : "Exists"
      },
      {
        "effect" : "NoSchedule",
        "operator" : "Exists"
      }
    ],
    "resources" : {
      "requests" : {
        "cpu" : "70m",
        "memory" : "100Mi"
      }
    },
  })

  metrics_port = yamlencode({
      "metrics" : { 
        "prometheusScrape" : "true",
        "port" : random_integer.metrics_port[0].result 
      }
  })

  release_name_suffixed = "${var.helm_release_name}-${one(random_pet.release_name_suffix[*].id)}"

}

resource "random_integer" "metrics_port" {
  count = var.enabled ? 1 : 0

  min = 1025
  max = 32667

  keepers = {
    values = random_pet.release_name_suffix[count.index].id
  }
}

resource "random_pet" "release_name_suffix" {
  count = var.enabled ? 1 : 0
  keepers = {
    var_values = jsonencode(var.values),
    default_values = jsonencode(local.values_default)
  }
}

data "aws_caller_identity" "current" {}

data "utils_deep_merge_yaml" "values" {
  count = var.enabled ? 1 : 0
  input = compact([
    local.values_default,
    var.values,
    local.metrics_port
  ])
}
