
module "rds_user_cp" {
  source      = "./rds-aws-user"
  aws_profile = "moj-cp"
}

resource "kubernetes_secret" "rds_aws_credentials" {
  depends_on = [helm_release.rds_snapshot_limit]

  metadata {
    name      = "aws-creds"
    namespace = kubernetes_namespace.rds_snapshot_limit.id
  }

  data = {
    access-key-id     = module.rds_user_cp.id
    secret-access-key = module.rds_user_cp.secret
  }
}

resource "kubernetes_namespace" "rds_snapshot_limit" {
  metadata {
    name = "rds-snapshot-limit"

    labels = {
      "cloud-platform.justice.gov.uk/environment-name" = "production"
      "cloud-platform.justice.gov.uk/is-production"    = "true"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "RDS Snapshot Limit"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-concourse"
    }
  }
}

resource "kubernetes_limit_range" "rds_snapshot_limit" {
  metadata {
    name      = "limitrange"
    namespace = kubernetes_namespace.rds_snapshot_limit.id
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "2"
        memory = "4000Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "100Mi"
      }
    }
  }
}

resource "kubernetes_secret" "rds_snapshot_limit_slack_hook" {

  metadata {
    name      = "slack-hook-url"
    namespace = kubernetes_namespace.rds_snapshot_limit.id
  }

  data = {
    value = var.slack_hook_url
  }
}

resource "kubernetes_cluster_role" "rds_snapshot_secret_reader" {
  metadata {
    name = "rds-snapshot-secret-reader"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
}


resource "kubernetes_cluster_role_binding" "rds_snapshot_secret_reader" {

  metadata {
    name = "rds-snapshot-secret-reader"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.rds_snapshot_secret_reader.id
    
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.rds_snapshot_limit.id
  }


}

data "helm_repository" "rds_snapshot_limit" {
  depends_on = [module.rds_user_cp.id]
  name = "rds-snapshot-limit"
  url  = "https://ministryofjustice.github.io/cloud-platform-helm-charts"
}

resource "helm_release" "rds_snapshot_limit" {

  depends_on = [module.rds_user_cp.id]
  name          = "rds-snapshot"
  namespace     = kubernetes_namespace.rds_snapshot_limit.id
  #repository    = data.helm_repository.rds_snapshot_limit.metadata[0].name
  #chart         = "rds-snapshot-limit"
  chart         = "/Users/imranawan/projects/moj/snapshot/rds-snapshot/"
  #version       = var.rds-snapshot-limit_chart_version
  version       = local.rds-snapshot-limit


  values = [templatefile("${path.module}/templates/values.yaml", {
    cronjobEnabled          = var.cronjob
    cronjobSchedule         = var.schedule
  })]
}

##########
# Locals #
##########

locals {
  rds-snapshot-limit = "0.1.0"
}

