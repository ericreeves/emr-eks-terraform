----

# EMR on EKS with Terraform

## Deploying EMR on EKS

One note before getting started. The version of the EMR on EKS module needs to be pinned to `17.9.0` due to a [breaking change](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1570) and the fact this PR is based off a specific version of the AWS provider.

The Terraform example provisions everything you need:
- A new VPC (with the [AWS VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest))
- An EKS cluster with a managed node group (with the [AWS EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest))
- All the necessary IAM and Kubernetes roles as mentioned in the [EMR on EKS Getting Started](https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up.html) documenation

*Please note that I've only run this end-to-end a couple times, so there may be some dependencies that require you to run `terraform apply` again.*

By default, Terraform will use your default AWS profile and region. 

```shell
terraform init
terraform apply
```

The EKS cluster can take about 10-15 minutes to provision.

## Running a job

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

### Issues

- `update_config` was broken: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1570

---

Forked from https://github.com/dacort/emr-eks-terraform