locals {
  argo_application_metadata = {
    "labels" : try(var.argo_metadata.labels, {}),
    "annotations" : try(var.argo_metadata.annotations, {}),
    "finalizers" : try(var.argo_metadata.finalizers, [])
  }
  argo_application_values = {
    "project" : var.argo_project
    "source" : {
      "repoURL" : var.helm_repo_url
      "chart" : var.helm_chart_name
      "targetRevision" : var.helm_chart_version
      "helm" : {
        "releaseName" : var.helm_release_name
        "parameters" : [for k, v in var.settings : tomap({ "forceString" : true, "name" : k, "value" : v })]
        "values" : var.enabled ? data.utils_deep_merge_yaml.values[0].output : ""
      }
    }
    "destination" : {
      "server" : var.argo_destination_server
      "namespace" : var.namespace
    }
    "syncPolicy" : var.argo_sync_policy
    "info" : var.argo_info
  }
}

resource "random_integer" "metrics_port" {
  count = var.enabled && var.argo_enabled ? 1 : 0

  min = 1025
  max = 32667

  keepers = {
    values = random_pet.argo_app_suffix[count.index].id
  }
}

resource "random_pet" "argo_app_suffix" {
  count = var.enabled && var.argo_enabled ? 1 : 0
  keepers = {
    var_values = jsonencode(var.values),
    default_values = jsonencode(local.values_default)
  }
}

resource "kubernetes_manifest" "this" {
  count = var.enabled && var.argo_enabled && !var.argo_helm_enabled ? 1 : 0
  manifest = {
    "apiVersion" = var.argo_apiversion
    "kind"       = "Application"
    "metadata" = merge(
      local.argo_application_metadata,
      { "name" = "${var.helm_release_name}-${random_pet.argo_app_suffix[count.index].id}" },
      { "namespace" = var.argo_namespace },
    )
    "spec" = merge(
      local.argo_application_values,
      var.argo_spec
    )
  }
  computed_fields = var.argo_kubernetes_manifest_computed_fields

  field_manager {
    name            = var.argo_kubernetes_manifest_field_manager_name
    force_conflicts = var.argo_kubernetes_manifest_field_manager_force_conflicts
  }

  wait {
    fields = var.argo_kubernetes_manifest_wait_fields
  }
}
