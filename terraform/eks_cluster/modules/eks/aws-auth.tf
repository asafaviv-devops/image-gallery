###########################################################
# aws-auth configmap (managed fully by Terraform)
###########################################################

locals {
  node_role_arn     = aws_iam_role.node.arn
  cluster_role_arn  = aws_iam_role.cluster.arn
}

resource "kubectl_manifest" "aws_auth" {
  yaml_body = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${local.node_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

    - rolearn: ${local.cluster_role_arn}
      username: admin
      groups:
        - system:masters

  mapUsers: |
    - userarn: arn:aws:iam::184890426414:user/asaf_aviv
      username: admin
      groups:
        - system:masters
EOF

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.default
  ]
}


