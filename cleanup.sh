#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

## Source common variables
source ./common-vars.sh

echo -e "${GREEN}Starting cleanup process...${NC}"

## Delete the deployment
echo -e "${GREEN}Deleting deployment...${NC}"
kubectl delete -f deployment.yaml

## Delete the SecretProviderClass
echo -e "${GREEN}Deleting SecretProviderClass...${NC}"
kubectl delete -f secretproviderclass.yaml

## Uninstall AWS Provider for Secrets Store CSI
echo -e "${GREEN}Uninstalling AWS Provider for Secrets Store CSI...${NC}"
kubectl delete -f ${k8s_aws_provider_ss_csi_driver}

## Uninstall Secrets Store CSI Driver
echo -e "${GREEN}Uninstalling Secrets Store CSI Driver...${NC}"
helm uninstall ${k8s_helm_release} --namespace ${k8s_namespace}

## Remove Helm repository
echo -e "${GREEN}Removing Helm repository...${NC}"
helm repo remove ${k8s_helm_repo_name}

## Delete IAM Service Account
echo -e "${GREEN}Deleting IAM Service Account...${NC}"
eksctl delete iamserviceaccount \
  --cluster ${k8s_cluster_name} \
  --namespace ${k8s_app_namespace} \
  --name ${k8s_secret_store_sa_name}

## Get the policy ARN
aws_policy_arn=$(aws iam list-policies --query "Policies[?PolicyName=='${aws_policy_name}'].Arn" --output text)

## Delete IAM Policy (handling multiple versions)
echo -e "${GREEN}Deleting IAM Policy...${NC}"
if [ -n "${aws_policy_arn}" ]; then
  # List all non-default policy versions
  policy_versions=$(aws iam list-policy-versions --policy-arn ${aws_policy_arn} --query "Versions[?IsDefaultVersion==\`false\`].VersionId" --output text)
  
  # Delete each non-default policy version
  for version in ${policy_versions}; do
    echo -e "${GREEN}Deleting policy version ${version}...${NC}"
    aws iam delete-policy-version --policy-arn ${aws_policy_arn} --version-id ${version}
  done
  
  # Delete the policy (with default version)
  echo -e "${GREEN}Deleting policy with default version...${NC}"
  aws iam delete-policy --policy-arn ${aws_policy_arn}
else
  echo -e "${GREEN}Policy ${aws_policy_name} not found, skipping deletion.${NC}"
fi

## Delete AWS Secret
echo -e "${GREEN}Deleting AWS Secret...${NC}"
aws secretsmanager delete-secret \
  --secret-id ${aws_secret_name} \
  --force-delete-without-recovery

## Remove temporary files
echo -e "${GREEN}Removing temporary files...${NC}"
rm -f csi-secrets-policy.json secretproviderclass.yaml

echo -e "${GREEN}Cleanup completed successfully!${NC}"
