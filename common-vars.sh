#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Common variables for setup and cleanup scripts
k8s_cluster_name=$(cat cluster-name)
k8s_secret_store_sa_name="secrets-store-csi-driver-sa"
k8s_helm_repo_name="secrets-store-csi-driver"
k8s_helm_chart_repo="https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
k8s_namespace="kube-system"
k8s_app_namespace="default"
k8s_helm_release="csi-secrets-store"
k8s_aws_provider_ss_csi_driver="https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
aws_secret_name="my-app-secret"
aws_policy_name="SecretsStoreCSIReadSecrets"
