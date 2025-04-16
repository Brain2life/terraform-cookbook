output "eks_node_group_id_map" {
  description = "Map of node group names to their Node Group IDs"
  value       = { for name, ng in module.eks.eks_managed_node_groups : name => ng.node_group_id }
}
