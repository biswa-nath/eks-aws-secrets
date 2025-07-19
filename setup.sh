#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Source common variables
echo -e "${GREEN}Loading common variables...${NC}"
source ./common-vars.sh

echo -e "${GREEN}Starting setup process for AWS Secrets Store CSI Driver...${NC}"

## Create a Secret in AWS Secrets Manager and get the ARN
echo -e "${GREEN}Creating Secret in AWS Secrets Manager...${NC}"
aws_secret_arn=$(aws secretsmanager create-secret \
  --name ${aws_secret_name} \
  --secret-string '{"username":"admin","password":"P@ssw0rd"}' \
  --query ARN --output text)
echo -e "${GREEN}Secret created with ARN: ${aws_secret_arn}${NC}"

## Create secret read policy
echo -e "${GREEN}Updating policy document with Secret ARN...${NC}"
cp csi-secrets-policy-template.json csi-secrets-policy.json
sed -i "s|\[secret-arn\]|${aws_secret_arn}|g" csi-secrets-policy.json

## Create IAM Policy and get the ARN
echo -e "${GREEN}Creating IAM Policy for Secret access...${NC}"
aws_policy_arn=$(aws iam create-policy \
  --policy-name ${aws_policy_name} \
  --policy-document file://csi-secrets-policy.json \
  --query Policy.Arn --output text)
echo -e "${GREEN}IAM Policy created with ARN: ${aws_policy_arn}${NC}"

## Create IAM Role for Service Account (IRSA)
echo -e "${GREEN}Creating IAM Role for Service Account (IRSA)...${NC}"
eksctl create iamserviceaccount \
  --cluster ${k8s_cluster_name} \
  --namespace ${k8s_app_namespace} \
  --name ${k8s_secret_store_sa_name} \
  --attach-policy-arn ${aws_policy_arn} \
  --approve
echo -e "${GREEN}IAM Service Account created successfully${NC}"

## Install Secrets Store CSI Driver
echo -e "${GREEN}Adding Helm repository for Secrets Store CSI Driver...${NC}"
helm repo add ${k8s_helm_repo_name} ${k8s_helm_chart_repo}
echo -e "${GREEN}Installing Secrets Store CSI Driver via Helm...${NC}"
helm upgrade --install ${k8s_helm_release} ${k8s_helm_repo_name}/secrets-store-csi-driver \
  --namespace ${k8s_namespace} \
  --set enableSecretRotation=true
echo -e "${GREEN}Secrets Store CSI Driver installed successfully${NC}"

## Install AWS Provider for Secrets Store CSI
echo -e "${GREEN}Installing AWS Provider for Secrets Store CSI Driver...${NC}"
kubectl apply -f ${k8s_aws_provider_ss_csi_driver}
echo -e "${GREEN}AWS Provider installed successfully${NC}"

## SecretProviderClass Definition
echo -e "${GREEN}Configuring SecretProviderClass...${NC}"
cp secretproviderclass-template.yaml secretproviderclass.yaml
sed -i "s|\[secret-name\]|${aws_secret_name}|g" secretproviderclass.yaml
sed -i "s|\[app-namespace\]|${k8s_app_namespace}|g" secretproviderclass.yaml
echo -e "${GREEN}Applying SecretProviderClass to the cluster...${NC}"
kubectl apply -f secretproviderclass.yaml

## Deployment
echo -e "${GREEN}Deploying application with mounted secrets...${NC}"
kubectl apply -f deployment.yaml
echo -e "${GREEN}Deployment complete!${NC}"

echo -e "${GREEN}Setup process completed successfully. The application should now have access to the AWS Secret.${NC}"
