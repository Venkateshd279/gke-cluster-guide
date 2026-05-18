# GitHub Actions Authentication with Workload Identity Federation (WIF)

WIF allows GitHub Actions to authenticate with GCP **without storing any service account keys**. GCP verifies the identity of the GitHub Actions runner using OIDC tokens.

```
GitHub Actions → OIDC Token → GCP verifies token → Temporary credentials issued → Deploy to GKE
```

No JSON keys. No secrets rotation. Secure by default.

---

## Step 1: Create a Workload Identity Pool

1. Go to **IAM & Admin → Workload Identity Federation**
2. Click **"Create Pool"**
3. Enter:
   - **Name**: `github-pool2`
4. Click **Continue**

---

## Step 2: Add a Provider to the Pool

1. Select **"Generic Identity Provider"** from the list
2. Choose **OIDC** as the provider type
3. Enter:
   - **Provider name**: `github-provider`
   - **Issuer URL**: `https://token.actions.githubusercontent.com`
   - **Audience**: `https://iam.googleapis.com/projects/379973440745/locations/global/workloadIdentityPools/github-pool2/providers/github-provider`
4. Click **Continue**
5. Under **Attribute Mapping**, add:
   - `google.subject` → `assertion.sub`
   - `attribute.repository` → `assertion.repository`
6. Under **Attribute Conditions**, enter:
   ```
   attribute.repository == "Venkateshd279/gke-cluster-guide"
   ```
7. Click **Save**

---

## Step 3: Create a Service Account

1. Go to **IAM & Admin → Service Accounts**
2. Click **"Create Service Account"**
3. Enter name: `github-actions-sa`
4. Assign these roles:
   - `Kubernetes Engine Developer`
   - `Artifact Registry Writer`
5. Click **Done**

---

## Step 4: Grant WIF Access to the Service Account

1. Click on the Service Account `github-actions-sa@thematic-ruler-494815-f6.iam.gserviceaccount.com`
2. Go to the **Permissions** tab
3. Click **"Grant Access"**
4. In the **New Principal** field, enter:
   ```
   principalSet://iam.googleapis.com/projects/379973440745/locations/global/workloadIdentityPools/github-pool2/attribute.repository/Venkateshd279/gke-cluster-guide
   ```
5. Role: **Workload Identity User**
6. Click **Save**

---

## Step 4b: Grant Service Account Token Creator (One-time, run locally)

This is required for the pipeline to impersonate the service account:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@thematic-ruler-494815-f6.iam.gserviceaccount.com \
  --member="principalSet://iam.googleapis.com/projects/379973440745/locations/global/workloadIdentityPools/github-pool2/attribute.repository/Venkateshd279/gke-cluster-guide" \
  --role="roles/iam.serviceAccountTokenCreator"
```

---

## Step 5: Add GitHub Secrets

Go to **GitHub → Your Repo → Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|---|---|
| `WIF_PROVIDER` | `projects/379973440745/locations/global/workloadIdentityPools/github-pool2/providers/github-provider` |
| `WIF_SERVICE_ACCOUNT` | `github-actions-sa@thematic-ruler-494815-f6.iam.gserviceaccount.com` |
| `GCP_PROJECT_ID` | `thematic-ruler-494815-f6` |

---

## GitHub Actions Workflow (Reference)

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Authenticate to GCP
    uses: google-github-actions/auth@v2
    with:
      workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
      service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```
