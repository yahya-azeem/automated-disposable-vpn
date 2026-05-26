# GCP Service Account & GitHub Actions Setup Guide

To deploy the TrustTunnel VPN using the new GitHub Actions workflow, you need to create a GCP Service Account with the proper permissions and add the credentials to your GitHub repository secrets.

Here is a step-by-step command guide you can run locally using your `gcloud` CLI (which is already configured with your active project `wide-ratio-423022-e8`):

---

### Step 1: Set Variables (Bash or PowerShell)

In your terminal, set your project ID:
```bash
# For Bash:
export PROJECT_ID="wide-ratio-423022-e8"

# For PowerShell:
$PROJECT_ID="wide-ratio-423022-e8"
```

---

### Step 2: Create the Service Account

Create a service account named `trusttunnel-sa`:
```bash
gcloud iam service-accounts create trusttunnel-sa \
    --description="Service Account for deploying TrustTunnel VPN via GitHub Actions" \
    --display-name="TrustTunnel Deployer"
```

---

### Step 3: Grant IAM Roles

Grant the required permissions to the service account. The action requires Compute Admin and Artifact Registry Admin roles:

#### 1. Grant Compute Admin (GCE & Firewalls management)
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:trusttunnel-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"
```

#### 2. Grant Artifact Registry Admin (Repository & image pushing)
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:trusttunnel-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"
```

#### 3. Grant Service Account User (Required to attach default service accounts to GCE VMs)
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:trusttunnel-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

---

### Step 4: Export JSON Key

Create and download the private key file for the service account:
```bash
gcloud iam service-accounts keys create trusttunnel-key.json \
    --iam-account="trusttunnel-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

This will save `trusttunnel-key.json` in your current working directory.

---

### Step 5: Configure GitHub Secrets

Go to your repository on GitHub: `Settings > Secrets and variables > Actions` and add two **Repository Secrets**:

1. **`GCP_PROJECT_ID`**:
   - Value: `wide-ratio-423022-e8`
2. **`GCP_SA_KEY`**:
   - Value: Copy and paste the entire contents of the `trusttunnel-key.json` file.

> [!WARNING]
> Keep `trusttunnel-key.json` secure and do not commit it to version control. You can safely delete it from your local machine once it is uploaded to GitHub Secrets.
