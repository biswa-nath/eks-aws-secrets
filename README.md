# AWS Secrets Store CSI Driver for Kubernetes

This project demonstrates how to use the AWS Secrets Store CSI Driver to securely access AWS Secrets Manager secrets from Kubernetes pods.

## Overview

The AWS Secrets Store CSI Driver allows Kubernetes pods to mount secrets stored in AWS Secrets Manager as volumes. This provides a secure way to access secrets without storing them in Kubernetes manifests or environment variables.

Key components:
- AWS Secrets Manager for storing sensitive information
- Secrets Store CSI Driver for Kubernetes
- AWS Provider for Secrets Store CSI Driver
- IAM Roles for Service Accounts (IRSA) for secure authentication

## Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl installed and configured to access your EKS cluster
- eksctl installed
- Helm v3 installed
- An existing EKS cluster

## Setup Process

The setup process is automated through the `setup.sh` script, which performs the following steps:

1. Creates a secret in AWS Secrets Manager
2. Creates an IAM policy to allow reading the secret
3. Creates an IAM Role for Service Account (IRSA) with the policy attached
4. Installs the Secrets Store CSI Driver using Helm
5. Installs the AWS Provider for the Secrets Store CSI Driver
6. Configures a SecretProviderClass to define which secrets to access
7. Deploys a sample application that mounts the secrets

### Running the Setup

```bash
# Make sure the scripts are executable
chmod +x setup.sh
chmod +x cleanup.sh

# Run the setup script
./setup.sh
```

## Configuration Files

- `common-vars.sh`: Contains common variables used by both setup and cleanup scripts
- `csi-secrets-policy-template.json`: Template for the IAM policy to access secrets
- `secretproviderclass-template.yaml`: Template for the SecretProviderClass resource
- `deployment.yaml`: Sample deployment that mounts secrets from AWS Secrets Manager

## Accessing Secrets in Pods

Once deployed, the secrets are mounted at `/mnt/secrets-store` inside the container. You can verify this by executing:

```bash
# Get a pod name
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')

# Check the mounted secrets
kubectl exec -it $POD_NAME -- ls -la /mnt/secrets-store
```

## Cleanup

To remove all resources created by this project, run the cleanup script:

```bash
./cleanup.sh
```

This will:
1. Delete the Kubernetes deployment
2. Delete the SecretProviderClass
3. Uninstall the AWS Provider and Secrets Store CSI Driver
4. Delete the IAM Service Account
5. Delete the IAM policy
6. Delete the AWS Secrets Manager secret

## Security Considerations 

- The IAM policy follows the principle of least privilege
- Secrets are only accessible to pods using the specified service account
- Secrets are mounted as read-only volumes
- Secret rotation is enabled for the CSI driver

## Additional Resources

- [AWS Secrets Store CSI Driver Documentation](https://github.com/aws/secrets-store-csi-driver-provider-aws)
- [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [AWS IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
