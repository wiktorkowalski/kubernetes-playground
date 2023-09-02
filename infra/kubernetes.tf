provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.playground.token
}

data "aws_eks_cluster_auth" "playground" {
  name = module.eks.cluster_name
}

module "kubernetes_dashboard" {
  source = "cookielab/dashboard/kubernetes"
  version = "0.9.0"

  kubernetes_namespace_create = true
  kubernetes_dashboard_csrf = "214bbf08-61eb-44b9-b573-a756dbc1fc7d"
}

output "dashboard_url" {
  value = module.kubernetes_dashboard.dashboard_url
}
