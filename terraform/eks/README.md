# Terraform for EKS

The Terraform code inside this repository provides a simple way to create an EKS cluster. 

To start, ensure AWS credentials are configured or passed as environment variables, and simply issue: 

```bash
terraform init
terraform apply 
```

Once everything is set up, you can update your kubeconfig with

```bash 
aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)
```

After this, there will be two available namespaces:
- The `playground` namespace, containing the vulnerable app
- The `datadog` namespace, containing the Datadog agent, deployed with Helm via Terraform