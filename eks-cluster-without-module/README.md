# Provision EKS Cluster

This project shows how to provision **EKS cluster with Managed Node Groups without using any community modules**

![](../img/vpc_for_eks.png)

## Kubernetes architecture

![](../img/kubernetes-cluster-architecture.svg)

Kubernetes architecture is based on a **master-worker (control plane-node)** model. For more information, see [Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/)

---

### 1. **Control Plane (Master)**

The **Control Plane** manages the Kubernetes cluster and is responsible for the global decisions about the cluster (e.g., scheduling) and detecting/responding to cluster events (e.g., starting a pod when a deployment's replicas are unsatisfied).

### Key Components:

| Component                             | Description                                                                           |
| ------------------------------------- | ------------------------------------------------------------------------------------- |
| `kube-apiserver`                      | Frontend of the control plane. Accepts REST requests and validates (authentication and authorization) & configures data.  |
| `etcd`                                | Key-value store for all cluster data (the “brain” of the cluster).                    |
| `kube-scheduler`                      | Assigns pods to nodes based on resource availability and policies (request and limits).                    |
| `kube-controller-manager`             | Runs background controller loops to ensure desired cluster state.                     |
| `cloud-controller-manager` (optional) | Manages cloud provider-specific control logic (e.g., load balancer setup).            |

---

### 2. **Node (Worker Machines)**

Each **Node** is a VM or physical machine that runs the workloads. It contains services needed to run containers and is managed by the control plane.

### Node Components:

| Component           | Description                                                          |
| ------------------- | -------------------------------------------------------------------- |
| `kubelet`           | Agent that ensures containers are running in a Pod on the node.      |
| `kube-proxy`        | Maintains network rules on nodes for network communication.          |
| `container runtime` | Software like [containerd](https://containerd.io/) or [CRI-O](https://cri-o.io/) that actually runs the containers. |

---

## 3. **Important Controllers**

| Controller    | Function                                                   |
| ------------- | ---------------------------------------------------------- |
| Deployment    | Manages ReplicaSets and rolling updates of Pods.           |
| ReplicaSet    | Ensures a specified number of Pods are always running.     |
| StatefulSet   | Manages Pods that require persistent identity and storage. |
| DaemonSet     | Ensures a Pod runs on **all** (or selected) Nodes.         |
| Job / CronJob | Handles one-off or scheduled tasks.                        |

---

## 4. **Add-ons**

| Add-on             | Role                                                          |
| ------------------ | ------------------------------------------------------------- |
| [CoreDNS](https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html)            | Resolves service names to IP addresses within the cluster.    |
| [Metrics Server](https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html)     | Collects resource metrics (CPU/memory) from nodes and Pods.   |
| [Ingress Controller](https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/) | Manages external access to services (usually via HTTP/HTTPS). |

## VPC Configuration

To create VPC use the following example: [Provision standard type of VPC for EKS cluster](https://github.com/Brain2life/terraform-cookbook/tree/main/standard-vpc-for-eks/terraform)

## EKS IAM Roles and Policies

An Amazon EKS cluster IAM role is required for each cluster. For more information, see [Amazon EKS cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/cluster-iam-role.html)

Before you can create Amazon EKS clusters, you must create an IAM role with either of the following IAM policies:
- [AmazonEKSClusterPolicy](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSClusterPolicy.html)
- A custom IAM policy

Your **custom IAM policy must have the following minimal permissions** that allows Kubernetes cluster to manage nodes:
```json{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "ForAnyValue:StringLike": {
          "aws:TagKeys": "kubernetes.io/cluster/*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeVpcs",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstanceTopology",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
```

### EKS Trust Policy

The following trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
is attached to an IAM role to **define which entities (in this case, the EKS service) are allowed to assume the role and perform actions on behalf of your AWS account**.

This policy is **attached to the EKS cluster role**, which is required when creating an EKS cluster. The EKS service **uses this role to interact with other AWS services** (e.g., EC2, ELB, CloudWatch) to manage the cluster’s resources, such as creating load balancers, managing worker nodes, or logging.

The policy ensures that only the EKS service (`eks.amazonaws.com`) can assume the role, adhering to the principle of least privilege. This prevents unauthorized entities from assuming the role and accessing sensitive resources.

When you create an EKS cluster (e.g., using `aws eks create-cluster` or a tool like Terraform):
1. You create an IAM role (e.g., `EKSClusterRole`) with the `assume_role_policy` shown above.
2. You attach a permissions policy like `A`mazonEKSClusterPolicy` to this role, which grants specific permissions (e.g., creating load balancers or accessing CloudWatch).
3. The EKS service assumes the role using the `sts:AssumeRole` action, allowing it to perform the authorized actions in your AWS account to set up and manage the cluster.

## Setting `authentication_mode = "API"`

For more information, see [Managing cluster access](https://www.eksworkshop.com/docs/security/cluster-access-management/managing)

In EKS, the `authentication_mode = "API"` setting specifies how authentication is handled for accessing the EKS cluster’s Kubernetes API server. This setting is typically used when configuring an EKS cluster (e.g., via Terraform, AWS CLI, or AWS SDK) and is part of the cluster’s access configuration.


- **What it does**: The `authentication_mode = "API"` setting configures the EKS cluster to use **AWS IAM authentication** exclusively for authenticating users or entities to the Kubernetes API server. This means that access to the cluster’s Kubernetes API is controlled through AWS Identity and Access Management (IAM) credentials, leveraging IAM roles or users.

- **Context in EKS**:
  - EKS clusters use the Kubernetes API server to manage and interact with the cluster (e.g., via `kubectl` or other Kubernetes tools).
  - Authentication to the API server determines who or what can authenticate to the cluster, while authorization (via Kubernetes RBAC or other mechanisms) determines what they can do.
  - The `authentication_mode` setting defines how the EKS cluster validates the identity of clients trying to access the Kubernetes API.

- **Behavior with `API`**:
  - When set to `"API"`, the cluster relies solely on **AWS IAM-based authentication**. Clients must provide valid AWS IAM credentials (e.g., access keys, IAM role credentials, or temporary credentials from STS) to authenticate.
  - The authentication is facilitated by the **AWS IAM Authenticator** (or `aws-iam-authenticator`), which maps IAM identities to Kubernetes users or groups via the `aws-auth` ConfigMap in the cluster.
  - This mode does not enable native Kubernetes authentication mechanisms like client certificates or OIDC providers directly; instead, it delegates authentication to AWS IAM.

### Why This Setting Is Needed
- **Centralized Identity Management**: Using `"API"` allows you to leverage AWS IAM for authentication, which integrates with your existing AWS identity management practices (e.g., IAM users, roles, or federated identities).
- **Security**: IAM-based authentication provides a secure way to control access to the cluster without managing separate Kubernetes credentials (e.g., certificates or tokens).
- **Granular Access Control**: Combined with the `aws-auth` ConfigMap, you can map IAM users or roles to specific Kubernetes roles or cluster roles, enabling fine-grained RBAC policies.
- **Scalability**: IAM authentication scales well for organizations already using AWS, as it avoids the need to manage separate authentication systems for Kubernetes.

### Comparison with Other Authentication Modes
EKS supports multiple authentication modes (introduced in newer EKS versions, such as with [enhanced access control features](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)). The `authentication_mode` setting can take the following values:
- **API**: Only IAM-based authentication is used, as described above.
- **API_AND_CONFIG_MAP**: Combines IAM-based authentication with the `aws-auth` ConfigMap for backward compatibility. The `aws-auth` ConfigMap ([deprecated](https://docs.aws.amazon.com/eks/latest/userguide/auth-configmap.html)) maps IAM identities to Kubernetes users or groups.
- **CONFIG_MAP**: Relies solely on the `aws-auth` ConfigMap for authentication mappings, typically used in older EKS clusters or for specific use cases.

When `authentication_mode = "API"` is set, it emphasizes using IAM directly for authentication, and you manage access through IAM policies and the Kubernetes RBAC system without relying on the `aws-auth` ConfigMap for authentication mappings (though RBAC mappings may still be needed for authorization).

### Example in Terraform
Here’s how the `authentication_mode` might be configured in a Terraform `aws_eks_cluster` resource:

```hcl
resource "aws_eks_cluster" "example" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = ["subnet-123", "subnet-456"]
  }

  access_config {
    authentication_mode = "API"
  }
}
```

In this example:
- The `authentication_mode = "API"` ensures that the cluster uses IAM credentials for API server authentication.
- The `role_arn` references the IAM role with the trust policy that allows the EKS service to manage the cluster.

### Practical Implications
- **Who Uses It**: Cluster administrators set `authentication_mode = "API"` when they want to rely entirely on IAM for authentication, simplifying access management for users and applications.
- **How It Works with `kubectl`**:
  - Users authenticate to the EKS cluster using AWS credentials (e.g., via AWS CLI profiles or IAM roles).
  - The `aws-iam-authenticator` or the AWS SDK generates a token that is passed to the Kubernetes API server.
  - The API server validates the token against IAM to authenticate the user.
- **Access Management**:
  - You define IAM policies to control who can assume roles or access the cluster.
  - Kubernetes RBAC policies (via `Role` or `ClusterRole`) map the authenticated IAM identities to specific permissions within the cluster.
- **Limitations**:
  - Requires proper IAM setup, which can be complex for organizations new to AWS.
  - If you need non-IAM-based authentication (e.g., OIDC or client certificates), you’d need to use a different or combined `authentication_mode`.

### Why Use `API` Mode?
- **Streamlined IAM Integration**: Ideal for organizations heavily invested in AWS, as it aligns Kubernetes access with existing IAM workflows.
- **Reduced Overhead**: Eliminates the need to manage Kubernetes-native authentication mechanisms like certificates or static tokens.
- **Enhanced Security**: Leverages AWS’s robust IAM system, including features like MFA, temporary credentials, and role-based access.

The `authentication_mode = "API"` setting is critical for organizations that want to centralize identity management within AWS while maintaining fine-grained control over cluster access through IAM and Kubernetes RBAC.

## Setting `bootstrap_cluster_creator_admin_permissions = true`

In EKS, the [`bootstrap_cluster_creator_admin_permissions = true`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#bootstrap_cluster_creator_admin_permissions-1) setting is used when configuring an EKS cluster (typically via Terraform, AWS CLI, or AWS SDK) to grant the IAM entity (user or role) that creates the cluster **full administrative permissions** to the cluster’s Kubernetes RBAC system. This setting is part of the EKS cluster’s access configuration and is designed to simplify initial cluster setup.

- **What it does**: When set to `true`, this setting automatically grants the IAM user or role that creates the EKS cluster **Kubernetes cluster-admin privileges** via the Kubernetes RBAC (Role-Based Access Control) system. Specifically, it binds the IAM entity to the `cluster-admin` `ClusterRole`, which provides unrestricted access to all Kubernetes resources in the cluster.

  - EKS integrates AWS IAM with Kubernetes RBAC to manage access to the cluster.
  - The IAM entity that creates the cluster (e.g., an administrator’s IAM user or role) typically needs full access to configure the cluster, manage workloads, and set up additional access policies.
  - By setting `bootstrap_cluster_creator_admin_permissions = true`, AWS automatically configures the Kubernetes RBAC to grant the cluster creator full administrative rights, eliminating the need to manually configure the `aws-auth` ConfigMap or other RBAC bindings for the creator.


### Why This Setting Is Needed
- **Simplifies Initial Cluster Setup**: Without this setting, the cluster creator would need to manually configure RBAC permissions (e.g., via the `aws-auth` ConfigMap or access entries) to grant themselves administrative access. This setting automates that process, ensuring the creator can immediately manage the cluster.
- **Ensures Administrative Access**: The cluster creator typically needs full control to set up namespaces, deploy applications, configure RBAC, or troubleshoot issues. This setting guarantees they have the necessary permissions without additional steps.
- **Streamlines Onboarding**: For new EKS clusters, especially in development or testing environments, this setting reduces the complexity of access management, allowing the creator to start working with the cluster right away.
- **Security Consideration**: While convenient, this setting grants broad permissions, so it should be used carefully in production environments to avoid giving excessive access to unintended users or roles.

### Example in Terraform
Here’s how the `bootstrap_cluster_creator_admin_permissions` setting might be configured in a Terraform `aws_eks_cluster` resource:

```hcl
resource "aws_eks_cluster" "example" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = ["subnet-123", "subnet-456"]
  }

  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
}
```

In this example:
- The `bootstrap_cluster_creator_admin_permissions = true` ensures that the IAM entity creating the cluster (e.g., the user or role running the Terraform apply) is granted Kubernetes `cluster-admin` privileges.
- The `authentication_mode = "API"` (as discussed previously) ensures IAM-based authentication, and the `bootstrap` setting complements it by automatically configuring RBAC for the creator.

### When to Use `bootstrap_cluster_creator_admin_permissions = true`
- **Use Cases**:
  - **Development or Testing Clusters**: Simplifies setup for non-production environments where quick access is prioritized.
  - **Single-Admin Scenarios**: Useful when a single administrator or team creates and manages the cluster.
  - **Initial Cluster Bootstrapping**: Ideal for getting started quickly without manually configuring RBAC.
- **When to Avoid**:
  - **Production Environments**: In high-security environments, you may prefer to disable this setting (`false`) and explicitly define RBAC policies to control access more granularly.
  - **Shared IAM Roles**: If the IAM role used to create the cluster is shared across multiple users or processes, granting automatic `cluster-admin` privileges could pose a security risk.

## Worker Node IAM roles

The EKS worker nodes need the following IAM roles and permissions:
- [`AmazonEKSWorkerNodePolicy`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSWorkerNodePolicy.html): This AWS managed policy allows Amazon EKS worker nodes to connect to Amazon EKS Clusters.
- [`AmazonEKS_CNI_Policy`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKS_CNI_Policy.html): This policy provides the Amazon VPC CNI Plugin (amazon-vpc-cni-k8s) the permissions it requires to modify the IP address configuration on your EKS worker nodes.
- [`AmazonEC2ContainerRegistryReadOnly`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEC2ContainerRegistryReadOnly.html): Provides read-only access to Amazon EC2 Container Registry repositories.

## When Not To Use Highly Available Cluster

If your project is **restricted with budget and the cost is essential** for you, then consider using **single-zone EKS worker nodes**. This way it is much cheaper, as you don't have to pay for [data transfer between AZs](https://docs.aws.amazon.com/cur/latest/userguide/cur-data-transfers-charges.html). Use such setups for **non-production environments**. 

## Cluster Deployment and Access

To provision cluster:
```bash
terraform apply
```

To update your local kubeconfig file and access the cluster, run:
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-demo_platform
```

In AWS Console in Acces tab of EKS you should find your user with admin access:

![](../img/eks_access.png)

To verify access run:
```bash
kubectl get no
```

![](../img/eks_node.png)

To ensure that you have read, write access to the cluster:
```bash
kubectl auth can-i "*" "*"
```

## References
- [YouTube: Create AWS EKS Cluster using Terraform](https://www.youtube.com/watch?v=uiuoNToeMFE&list=PLiMWaCMwGJXnKY6XmeifEpjIfkWRo9v2l)
- [EKS with Managed Node Groups via Community Module](../eks-with-managed-node-group/)
