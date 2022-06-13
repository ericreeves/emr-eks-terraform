----

# EMR on EKS with Terraform Cloud

## Overview

The Terraform example provisions everything you need:
- A new VPC (with the [AWS VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest))
- An EKS cluster with a managed node group (with the [AWS EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest))
- All the necessary IAM and Kubernetes roles as mentioned in the [EMR on EKS Getting Started](https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up.html) documenation

### Preparing AWS and Terraform Cloud

In order to deploy this manifest using Terraform Cloud (TFC), several items must be configured in advance.
- Create an IAM user in your target AWS account, add it to the "AdministratorAccess" group, and create an AWS API Access Key for it.
  - This will be the identity TFC uses to execute actions in your AWS account.
- Create or identify an Organization in TFC.
- Create a new Workspace in TFC.
  - The workspace can be of type "CLI-driven workflow" to get started.
  - Navigate to the "Variables" tab and create the following Variables (case sensitive).
    - AWS_ACCESS_KEY_ID - Provide the previously created Access Key ID.
    - AWS_SECRET_ACCESS_KEY - Provide the previously created Secret Access Key, and mark it as "Sensitive".
    - AWS_DEFAULT_REGION - Provide the name of the target AWS region.
- Populate the Organization and Workspace names in backend.tf.

### Deploying EMR on EKS

Next, deploy it!
```shell
terraform init
terraform apply
```

The EKS cluster can take about 10-15 minutes to provision.  Upon completion of a successful run, Terraform will output information about the resources it provisioned.  

## Running an EMR Job

Now that your cluster is up, you should be able to run a job. Because the [EKS cluster autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html) is not installed by default, if you want to anything more complicated than the example below, you'll need to scale the cluster up manually.

The below example just runs a sample calculation of Pi and enables CloudWatch logging.

The EMR on EKS virtual cluster ID is provided in a `emr-virtual-cluster-id` output and the role to run the job is in the `emr-eks-job-role` output.

```shell
export EMR_EKS_CLUSTER_ID=<CLUSTER_ID>
export EMR_EKS_EXECUTION_ARN=arn:aws:iam::<ACCOUNT_ID>:role/tf_emr_eks_job_role

aws emr-containers start-job-run \
    --virtual-cluster-id ${EMR_EKS_CLUSTER_ID} \
    --name sample-pi \
    --execution-role-arn ${EMR_EKS_EXECUTION_ARN} \
    --release-label emr-6.3.0-latest \
    --job-driver '{
        "sparkSubmitJobDriver": {
            "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py"
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "cloudWatchMonitoringConfiguration": {
                "logGroupName": "/aws/eks/emr-spark",
                "logStreamNamePrefix": "pi"
            }
        }
    }'
```

## References

### IAM/K8s Roles

irsa example: https://github.com/terraform-aws-modules/terraform-aws-eks/tree/a26c9fd0c9c880d5b99c438ad620e91dda957e10/examples/irsa
StringLike condition?: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/irsa/irsa.tf#L8
And another StringLike example: https://github.com/cloudposse/terraform-aws-eks-iam-role/blob/master/main.tf#L55
helpful re: roles: https://github.com/hashicorp/terraform-provider-kubernetes/issues/322

---

Forked from https://github.com/dacort/emr-eks-terraform