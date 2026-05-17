# GitHub Actions Setup Guide for GKE Deployment

This guide will help you set up GitHub Actions to automatically deploy NGINX to your GKE cluster.

## Prerequisites

- GitHub repository created: `https://github.com/Venkateshd279/gke-cluster-guide`
- GKE cluster running: `devops-junction-cluster`
- Google Cloud Project

## Step 1: Create a Service Account in GCP

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **IAM & Admin** > **Service Accounts**
3. Click **Create Service Account**
4. Fill in details:
   - **Service account name**: `github-actions`
   - **Service account ID**: `github-actions`
5. Click **Create and Continue**
6. Grant roles:
   - Click **Grant roles**
   - Add role: **Kubernetes Engine Developer**
   - Click **Continue** and then **Done**

## Step 2: Create and Download Service Account Key

1. In the Service Accounts list, click on `github-actions` service account
2. Go to **Keys** tab
3. Click **Add Key** > **Create new key**
4. Choose **JSON** format
5. Click **Create** (this will download the JSON file)
6. **Save this file securely** - you'll use it in the next step

## Step 3: Add GitHub Secrets

1. Go to your GitHub repository: `https://github.com/Venkateshd279/gke-cluster-guide`
2. Click **Settings** tab
3. Go to **Secrets and variables** > **Actions**
4. Click **New repository secret** and add the following:

### Secret 1: GCP_SA_KEY
- **Name**: `GCP_SA_KEY`
- **Value**: Copy the entire content of the JSON file you downloaded (from Step 2)
- Click **Add secret**

### Secret 2: GCP_PROJECT_ID
- **Name**: `GCP_PROJECT_ID`
- **Value**: Your Google Cloud Project ID (find it in the Cloud Console)
- Click **Add secret**

## Step 4: Configure Cluster Access for Service Account

Run these commands in Cloud Shell to grant the service account permission to access your GKE cluster:

```bash
# Get your GCP project ID
PROJECT_ID=$(gcloud config get-value project)

# Grant the service account permission to access the cluster
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/container.developer
```

## Step 5: Test the Workflow

1. Make a change to your repository (e.g., update Readme.md)
2. Push the changes to the `main` branch:
   ```bash
   git add .
   git commit -m "Trigger GitHub Actions workflow"
   git push origin main
   ```

3. Go to your GitHub repository
4. Click **Actions** tab
5. You should see the "Deploy NGINX to GKE" workflow running
6. Click on it to see the logs

## Step 6: View Deployment Logs

In the GitHub Actions logs, you'll see:
- Deployment status
- Pods running
- Service details
- External IP of NGINX (once assigned)

## Workflows Available

### Option 1: deploy-nginx.yml
- Simple, inline kubectl commands
- Deploys NGINX directly without manifest file
- Good for quick demos

**Triggered by:** Push to main branch

### Option 2: deploy-nginx-manifest.yml
- Uses Kubernetes manifest files from `k8s/` directory
- More professional and scalable approach
- Better for production deployments

**Triggered by:** Push to main branch AND changes to `k8s/` folder

## Accessing Your NGINX Deployment

After the workflow completes successfully:

1. Check the GitHub Actions logs to find the external IP
2. Open your browser and go to `http://<EXTERNAL_IP>`
3. You should see the NGINX welcome page

**Note:** It may take 1-2 minutes for the LoadBalancer service to get an external IP.

## Troubleshooting

### Issue: "Repository not found" error
- Make sure you've pushed the code to GitHub first
- Verify the repository URL in your git remote

### Issue: "Authentication failed" error
- Check that the `GCP_SA_KEY` secret is correctly added
- Verify the service account has the required permissions

### Issue: NGINX still shows "pending" IP
- This is normal; it can take 1-2 minutes for the LoadBalancer to provision
- Check status with: `kubectl get svc nginx-service`

### Issue: Workflow fails with "permission denied"
- Verify the service account role is set to "Kubernetes Engine Developer"
- Make sure you ran the `gcloud projects add-iam-policy-binding` command

## Next Steps

- Modify the workflow to deploy multiple replicas
- Add health checks and autoscaling
- Set up monitoring and logging
- Create different workflows for different environments (dev, staging, prod)

## Cleanup

To remove the NGINX deployment and service:

```bash
kubectl delete deployment nginx
kubectl delete service nginx-service
```

Or use GitHub Actions to trigger the cleanup on specific conditions.
