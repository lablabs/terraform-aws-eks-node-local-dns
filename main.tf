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

    helm_chart_version = "2.2.0"
    helm_repo_url      = "https://lablabs.github.io/k8s-nodelocaldns-helm"
  }

  addon_irsa = {
    (local.addon.name) = {}
  }

  addon_values = yamlencode({
    serviceAccount = {
      create = module.addon-irsa[local.addon.name].service_account_create
      name   = module.addon-irsa[local.addon.name].service_account_name
      annotations = module.addon-irsa[local.addon.name].irsa_role_enabled ? {
        "eks.amazonaws.com/role-arn" = module.addon-irsa[local.addon.name].iam_role_attributes.arn
      } : tomap({})
    }
  })
}
