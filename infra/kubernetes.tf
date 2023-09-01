provider "kubernetes" {
  host                   = aws_eks_cluster.playground.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.playground.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.playground.token
}

data "aws_eks_cluster_auth" "playground" {
  name = aws_eks_cluster.playground.name
}

# resource "kubernetes_namespace" "kubernetes_dashboard" {
#   metadata {
#     name = "kubernetes-dashboard"
#   }
# }

# resource "kubernetes_service_account" "kubernetes_dashboard" {
#   metadata {
#     name      = "kubernetes-dashboard"
#     namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
#   }
# }

# resource "kubernetes_cluster_role_binding" "kubernetes_dashboard" {
#   metadata {
#     name = "kubernetes-dashboard"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.kubernetes_dashboard.metadata[0].name
#     namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
#   }
# }

# resource "kubernetes_deployment" "kubernetes_dashboard" {
#   metadata {
#     name      = "kubernetes-dashboard"
#     namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
#   }
#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         k8s-app = "kubernetes-dashboard"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           k8s-app = "kubernetes-dashboard"
#         }
#       }
#       spec {
#         container {
#           image = "kubernetesui/dashboard:v2.7.0"
#           name  = "kubernetes-dashboard"
#           args  = ["--auto-generate-certificates", "--namespace=kubernetes-dashboard"]
#         }
#         service_account_name = kubernetes_service_account.kubernetes_dashboard.metadata[0].name
#       }
#     }
#   }
# }

# resource "kubernetes_service" "kubernetes_dashboard" {
#   metadata {
#     name      = "kubernetes-dashboard"
#     namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
#     labels = {
#       k8s-app = "kubernetes-dashboard"
#     }
#   }
#   spec {
#     selector = {
#       k8s-app = "kubernetes-dashboard"
#     }
#     port {
#       port        = 443
#       target_port = 8443
#     }
#   }
# }

# output "kubernetes_dashboard_url" {
#   value = "${aws_eks_cluster.playground.endpoint}/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
# }
