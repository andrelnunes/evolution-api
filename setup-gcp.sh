#!/bin/bash

# Variables
PROJECT_ID="sixth-syntax-433414-v8"
REGION="us-central1"
CLUSTER_NAME="evolution-cluster"
ARTIFACT_REGISTRY="evolution-registry"

# First, ensure you have the necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:$(gcloud config get-value account)" \
    --role="roles/owner"

# Enable required APIs
gcloud services enable \
    container.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com

# Create Artifact Registry repository
gcloud artifacts repositories create $ARTIFACT_REGISTRY \
    --repository-format=docker \
    --location=$REGION

# Create GKE cluster with better defaults
gcloud container clusters create $CLUSTER_NAME \
    --region=$REGION \
    --num-nodes=2 \
    --machine-type=e2-standard-2 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3 \
    --enable-autorepair \
    --enable-ip-alias \
    --enable-network-policy \
    --workload-pool=$PROJECT_ID.svc.id.goog

# Create service accounts
gcloud iam service-accounts create cloudbuild-deploy \
    --display-name="Cloud Build Deploy"

gcloud iam service-accounts create evolution-api-sa \
    --display-name="Evolution API Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cloudbuild-deploy@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:evolution-api-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"

# Create secrets in Secret Manager
echo "staging-api-key" | gcloud secrets create evolution-staging-api-key --data-file=-
echo "production-api-key" | gcloud secrets create evolution-production-api-key --data-file=- 