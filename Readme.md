# GKE Cluster Creation - Standard Mode

## Prerequisites
- Google Cloud Project
- gcloud CLI installed and configured
- Appropriate IAM permissions

---

## GKE Cluster Creation Methods

### Two Types of Cluster Creation:

1. **Standard Mode**
   - You manually manage everything: node pools, machine types, scaling, updates
   - More control but requires more effort
   - **This guide covers Standard Mode**

2. **Autopilot Mode**
   - Google fully manages the cluster for you: nodes, updates, scaling
   - Less control but easier to use and maintain
   - Best for teams who want less operational overhead

---

## Step 1: Enable Kubernetes Engine API

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project from the project dropdown
3. Navigate to **APIs & Services** > **Library**
4. Search for "Kubernetes Engine API"
5. Click on **Kubernetes Engine API**
6. Click the **ENABLE** button
7. Wait for the API to be enabled (this may take a few minutes)

You can also enable it via gcloud CLI:
```bash
gcloud services enable container.googleapis.com
```

Once enabled, you should see a confirmation message.

---

## Step 2: Set Up IAM Service Accounts for GKE

GKE uses IAM service accounts attached to your nodes to run system tasks like logging and monitoring.

1. Go to the [Welcome page](https://console.cloud.google.com/welcome)
2. Copy your **Project Number**
3. Go to [IAM page](https://console.cloud.google.com/iam-admin/iam)
4. Click **Grant access**
5. In the **New principals** field, enter: `PROJECT_NUMBER-compute@developer.gserviceaccount.com`
6. Select the role: **Kubernetes Engine Default Node Service Account**
7. Click **Save**

**Best Practice:** Create a custom service account with minimal permissions instead of using the default service account.

---

## Step 3: Create a Cluster

### Supported Machine Series

**Default Node Pool:**
- **E2** - Low cost, day-to-day computing (e.g., `e2-standard-4`, `e2-standard-8`)

**Arm Node Pool:**
- **C4A** - Cost-effective Arm machines
- **N4A** - General-purpose Arm machines  
- **T2A (Tau)** - High-performance Arm machines

### Create via Google Cloud Console

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **Kubernetes Engine** > **Clusters**
3. Click **Create** button
4. Choose **Standard** cluster mode
5. Enter cluster details:
   - **Name**: `devops-junction-cluster`
   - **Location type**: Choose **Regional** or **Zonal**
   - **Region/Zone**: Select `us-central1` (or your preferred region)
6. Under **Node Pools** (Default node pool):
   - **Machine type**: Select `e2-standard-4` (Low cost, day-to-day computing)
   - **Number of nodes**: Set to `1`
   - Click **Create** to proceed to additional node pool configuration
7. Add an Arm Node Pool:
   - Click **Add Node Pool** to add Arm-based nodes
   - **Machine type**: Select an Arm machine type (e.g., `c4a-standard-8`, `n4a-standard-4`, or `t2a-standard-16`)
   - **Number of nodes**: Set to `3` (or your desired count)
8. Review other settings (networking, security, etc.) as needed
9. Click **Create** to create the cluster

Wait for the cluster to be created (this may take 5-10 minutes).

---

## Step 5: Connect to the Cluster from Cloud Shell

Once your cluster is created and ready, you can connect to it using Cloud Shell:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Click the **Cloud Shell** button (terminal icon) at the top right of the console
3. Cloud Shell will open at the bottom of the screen
4. Run the following command to get the connection credentials:
   ```bash
   gcloud container clusters get-credentials devops-junction-cluster --region us-central1
   ```
   **Note:** Replace `us-central1` with your cluster's region/zone if you used a different location

5. Verify the connection by running:
   ```bash
   kubectl get nodes
   ```
   This will list all the nodes in your cluster (both E2 default nodes and Arm nodes)

6. You should see output similar to:
   ```
   NAME                                      STATUS   ROLES    AGE   VERSION
   gke-devops-junction-cluster-default-pool-xxxxx   Ready    <none>   5m    v1.xx.x
   gke-devops-junction-cluster-arm-pool-xxxxx       Ready    <none>   5m    v1.xx.x
   ```

**Tip:** You're now ready to deploy workloads to your GKE cluster! Use `kubectl apply -f <manifest-file>` to deploy applications.

---

## Step 6: Deploy NGINX on the Cluster

Now let's deploy NGINX to demonstrate your cluster is working:

### Option 1: Deploy using Cloud Shell (Recommended for Demo)

1. In the **Cloud Shell** terminal, run the following command to create an NGINX deployment:
   ```bash
   kubectl create deployment nginx --image=nginx
   ```

2. Verify the deployment was created:
   ```bash
   kubectl get deployments
   ```
   You should see:
   ```
   NAME    READY   UP-TO-DATE   AVAILABLE   AGE
   nginx   1/1     1            1           30s
   ```

3. Check the running pods:
   ```bash
   kubectl get pods
   ```
   Output:
   ```
   NAME                     READY   STATUS    RESTARTS   AGE
   nginx-5d59d67564-xxxxx   1/1     Running   0          45s
   ```

4. Expose the NGINX deployment as a service:
   ```bash
   kubectl expose deployment nginx --type=LoadBalancer --port=80
   ```

5. Get the external IP address (this may take 1-2 minutes to be assigned):
   ```bash
   kubectl get service nginx
   ```
   You should see:
   ```
   NAME    TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
   nginx   LoadBalancer   10.0.0.xxx      34.xx.xxx.xx     80:30xxx/TCP   20s
   ```

6. Once you have the **EXTERNAL-IP**, open it in your browser:
   - Copy the **EXTERNAL-IP** value (e.g., `34.xx.xxx.xx`)
   - Open a new browser tab and go to: `http://34.xx.xxx.xx`
   - You should see the NGINX welcome page!

### Clean Up (Optional)

To delete the NGINX deployment after your demo:
```bash
kubectl delete deployment nginx
kubectl delete service nginx
```

---

## GitHub Actions CI/CD

For setting up secure keyless authentication using Workload Identity Federation (WIF) and Service Account, see the dedicated guide:

[WIF-SETUP.md](./WIF-SETUP.md)

---

