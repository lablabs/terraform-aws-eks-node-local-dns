locals {
  values_default = yamlencode({
        "config": {
        "localDnsIp": "169.254.20.11",
        "zones": [
            {
                "zone": ".:53",
                "plugins": {
                    "errors": true,
                    "reload": true,
                    "debug": false,
                    "log": {
                        "format": "combined",
                        "classes": "all"
                    },
                    "cache": {
                        "parameters": 30,
                        "denial": {},
                            # size: 0
                            # ttl: 1
                        "success": {},
                            # size: 8192
                            # ttl: 30
                        "prefetch": {},
                            # amount: 1
                            # duration: 10m
                            # percentage: 20%
                        "serve_stale": false
                    },
                    "forward": {
                        "parameters": "172.20.0.10",
                        "force_tcp": false,
                        "prefer_udp": false,
                        "policy": "",  # random|round_robin|sequential
                        "max_fails": "",
                        "expire": "",
                        "health_check": "",
                        "except": ""
                    },
                    "prometheus": true,
                    "health": {
                        "port": 8080
                    }
                }
            },
            {
                "zone": "ip6.arpa:53",
                "plugins": {
                    "errors": true,
                    "reload": true,
                    "debug": false,
                    "log": {
                        "format": "combined",
                        "classes": "all"
                    },
                    "cache": {
                        "parameters": 30
                    },
                    "forward": {
                        "parameters": "172.20.0.10",
                        "force_tcp": false
                    },
                    "prometheus": true,
                    "health": {
                        "port": 8080
                    }
                }
            },
            {
                "zone": "in-addr.arpa:53",
                "plugins": {
                    "errors": true,
                    "reload": true,
                    "debug": false,
                    "log": {
                        "format": "combined",
                        "classes": "all"
                    },
                    "cache": {
                        "parameters": 30
                    },
                    "forward": {
                        "parameters": "172.20.0.10",
                        "force_tcp": false
                    },
                    "prometheus": true,
                    "health": {
                        "port": 8080
                    }
                }
            }
        ]
    },
    "useHostNetwork": true,
    "updateStrategy": {
        "rollingUpdate": {
            "maxUnavailable": "10%"
        }
    },
    "priorityClassName": "system-node-critical",
    "podAnnotations": {},
    "podSecurityContext": {},
    "securityContext": {
        "privileged": true
    },
    "readinessProbe": null,
    "serviceAccount": {
        "create": true,
        "annotations": {},
        "name": ""
    },
    "nodeSelector": {},
    "affinity": {},
    "tolerations": [
        {
            "key": "CriticalAddonsOnly",
            "operator": "Exists"
        },
        {
            "effect": "NoExecute",
            "operator": "Exists"
        },
        {
            "effect": "NoSchedule",
            "operator": "Exists"
        }
    ],
    "resources": {
        "requests": {
            "cpu": "30m",
            "memory": "50Mi"
        }
    },
    "metrics": {
        "prometheusScrape": "true",
        "port": 9253
    }
  })
}

data "utils_deep_merge_yaml" "values" {
  count = var.enabled ? 1 : 0
  input = compact([
    local.values_default,
    var.values
  ])
}
