# EKS Cluster with Managed Node Group

In Amazon EKS, a **Managed Node Group** means that **AWS takes care of provisioning, updating, and managing the lifecycle of EC2 instances (worker nodes)** in your Kubernetes cluster. A **node group** is one or more EC2 instances that are deployed in an **EC2 Auto Scaling group**.

In short: **Managed Node Group** = AWS manages the EC2 nodes (your worker nodes) for you.

![](https://docs.aws.amazon.com/images/eks/latest/best-practices/images/reliability/SRM-MNG.jpeg)

---

### Key Features

| Feature                         | Explanation |
|----------------------------------|-------------|
| **Auto-provisioned**             | AWS creates and configures the EC2 instances in an Auto Scaling Group. |
| **Automatic updates**            | AWS can update the AMI version for security patches and Kubernetes version compatibility. |
| **Integrated with EKS**          | Node groups are tightly integrated with the EKS control plane — you don’t need to manage bootstrap scripts. |
| **Node draining on upgrade**     | When updating or scaling down, AWS safely drains nodes to avoid disrupting running workloads. |
| **Easier scaling**               | You can scale node groups up/down via the EKS console, API, CLI, or Terraform. |
| [**Node auto repair**](https://docs.aws.amazon.com/eks/latest/userguide/node-health.html)             | This feature allows to continuously monitor the health of nodes. It automatically reacts to detected problems and replaces nodes when possible. |

> There are no additional costs to use Amazon EKS managed node groups, you only pay for the AWS resources you provision. These include Amazon EC2 instances, Amazon EBS volumes, Amazon EKS cluster hours, and any other AWS infrastructure. There are no minimum fees and no upfront commitments. For more information, see [Amazon EC2 pricing](https://aws.amazon.com/ec2/pricing/).

---

### Behind the scenes

When you define a managed node group:
- AWS uses a **standard AMI** (like [`Amazon EKS-optimized Linux`](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)).
- Creates an **Auto Scaling Group** for the nodes.
- Automatically **joins nodes to the EKS cluster**.
- Nodes launched as part of a managed node group are **automatically tagged for auto-discovery by the Kubernetes [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)**

---

### Self-managed vs Managed Node Groups

| Feature | Managed Node Group | Self-managed Node Group |
|--------|---------------------|--------------------------|
| Provisioned by AWS? | ✅ Yes | ❌ No (you create the ASG manually) |
| Node lifecycle managed? | ✅ Yes | ❌ You manage it |
| Updates and draining? | ✅ Yes | ❌ Manual |
| Custom bootstrap logic? | ❌ Limited | ✅ Full control |
| Use custom AMIs easily? | ⚠️ Somewhat tricky | ✅ Fully customizable |

---

### Access the cluster

To update your local `kubeconfig` file and access cluster, run:
```bash
aws eks update-kubeconfig --region us-east-1 --name eks-cluster
```

To verify access:
```bash
kubectl get no
```

---

### Inspect the cluster

Set the following variables:
```bash
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=eks-cluster
export EKS_MNG_NAME=<node_group_name>
```

To get the actual name of the provisioned node group name, run:
```bash
terraform output
```

Node group name should look like this: `example-20250416095857186100000013`

Inspect the provisioned managed node group:
```bash
eksctl get nodegroup --cluster $EKS_CLUSTER_NAME --name $EKS_MNG_NAME
```

![](https://i.imgur.com/25VDxbr.png)

You can also inspect the nodes and the placement in the availability zones.
```bash
kubectl get nodes -o wide --label-columns topology.kubernetes.io/zone
```

You should see that by default nodes are distributed over multiple subnets in various availability zones, providing high availability

![](https://i.imgur.com/T2bUuWp.png)


---

### Add nodes to the cluster

While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads.
We will be using the `aws eks update-nodegroup-config` command to scale a node group.

We'll scale the nodegroup by changing the node count from 2 to 4 for **desired capacity** using below command:
```bash
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_MNG_NAME --scaling-config minSize=2,maxSize=6,desiredSize=4
```

After making changes to the node group it may take up to **2-3 minutes for node provisioning** and configuration changes to take effect. Let's retrieve the nodegroup configuration again and look at minimum size, maximum size and desired capacity of nodes using `eksctl` command below:
```bash
eksctl get nodegroup --name $EKS_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

Monitor the nodes in the cluster using the following command with the --watch argument until there are 4 nodes:
```bash
kubectl get nodes --watch
```

You should see 4 provisioned nodes:

![](https://i.imgur.com/am4A2VQ.png)

---

### (OPTIONAL) Deploy the sample application 

The sample application models a simple web store application, where customers can browse a catalog, add items to their cart and complete an order through the checkout process.

![](https://eksworkshop.com/assets/images/home-139b528766858df3dd66ae3c09ec12ad.webp)

You can find the full source code for the sample application on [GitHub](https://github.com/aws-containers/retail-store-sample-app).

The application has several components and dependencies:

![](https://eksworkshop.com/assets/images/architecture-e1a8acbd5d28dacee67a6548ca9dbefa.webp)

| Component      | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| UI             | Provides the front end user interface and aggregates API calls to the various other services. |
| Catalog        | API for product listings and details                                        |
| Cart           | API for customer shopping carts                                             |
| Checkout       | API to orchestrate the checkout process                                     |
| Orders         | API to receive and process customer orders                                  |
| Static assets  | Serves static assets like images related to the product catalog             |

Use kubectl to run the application:
```bash
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
kubectl wait --for=condition=available deployments --all
```

Get the URL for the frontend load balancer like so:
```bash
kubectl get svc ui
```

![](https://i.imgur.com/KujZN3f.png)

To remove the application use kubectl again:
```bash
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
```

---

### Upgrading AMIs

The [Amazon EKS optimized Amazon Linux AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-amis.html) is built on top of Amazon Linux 2, and is configured to serve as the base image for Amazon EKS nodes. It's considered a best practice to use the latest version of the EKS-Optimized AMI when you add nodes to an EKS cluster, as new releases include Kubernetes patches and security updates. It's also important to upgrade existing nodes already provisioned in the EKS cluster.

EKS managed node groups provides the capability to automate the update of the AMI being used by the nodes it manages. It will automatically drain nodes using the Kubernetes API and respects the [Pod disruption budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/) that you set for your Pods to ensure that your applications stay available.

> A **Pod Disruption Budget (PDB)** is a Kubernetes policy that ensures a certain number of pods always stay running by limiting how many can be taken down during voluntary disruptions like node upgrades or scaling operations.

The Amazon EKS managed worker node upgrade has 4 phases:

**Setup**:
- Create a new Amazon EC2 Launch Template version associated with Auto Scaling group with the latest AMI
- Point your Auto Scaling group to use the latest version of the launch template
- Determine the maximum number of nodes to upgrade in parallel using the `updateconfig` property for the node group.

**Scale Up**:
- During the upgrade process, the upgraded nodes are launched in the same availability zone as those that are being upgraded
- Increments the Auto Scaling Group’s maximum size and desired size to support the additional nodes
- After scaling the Auto Scaling Group, it checks if the nodes using the latest configuration are present in the node group.
- Applies a `eks.amazonaws.com/nodegroup=unschedulable:NoSchedule` taint on every node in the node group without the latest labels. This prevents nodes that have already been updated from a previous failed update from being tainted.

**Upgrade**:
- Randomly selects a node and drains the Pods from the node.
- Cordons the node after every Pod is evicted and waits for 60 seconds
- Sends a termination request to the Auto Scaling Group for the cordoned node.
- Applies same across all nodes which are part of Managed Node group making sure there are no nodes with older version

**Scale Down**:
- The scale down phase decrements the Auto Scaling group maximum size and desired size by one until the the values are the same as before the update started.

To find out what the latest AMI version is available for EKS:
```bash
EKS_VERSION=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.version" --output text)
aws ssm get-parameter --name /aws/service/eks/optimized-ami/$EKS_VERSION/amazon-linux-2/recommended/image_id --region $AWS_REGION --query "Parameter.Value" --output text
```

When you initiate a managed node group update, Amazon EKS automatically updates your nodes for you, completing the steps listed above. If you're using an Amazon EKS optimized AMI, Amazon EKS automatically applies the latest security patches and operating system updates to your nodes as part of the latest AMI release version.

To initiate  an update of the managed node group, run:
```bash
aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_MNG_NAME
```

You can watch activity on the nodes using `kubectl`:
```bash
kubectl get nodes --watch
```

---

### (OPTIONAL) Enable Deletion Protection for the Cluster 

You can enable deletion protection for your EKS cluster in order to avoid any accidental deletions. For more information, see [Protect EKS clusters from accidental deletion](https://docs.aws.amazon.com/eks/latest/userguide/deletion-protection.html)

To enable deletion protection:
```bash
aws eks update-cluster-config --deletion-protection --name my-eks-cluster
```

To disable deletion protection:
```bash
aws eks update-cluster-config --no-deletion-protection --name my-eks-cluster
```

---

### References

- [AWS Docs: Simplify node lifecycle with managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [Amazon EKS: Best Practices for Reliability](https://docs.aws.amazon.com/eks/latest/best-practices/reliability.html)
- [Terraform module to create Amazon Elastic Kubernetes (EKS) resources](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [EKS Workshop: Managed Node Groups](https://eksworkshop.com/docs/fundamentals/managed-node-groups/)