# Cloud Notes Hub - Complete Deployment Checklist

This checklist will guide you through deploying the entire Cloud Notes Hub application from scratch.

## ✅ Pre-Deployment Checklist

### Prerequisites Verified
- [ ] Azure CLI installed and logged in (`az login`)
- [ ] Azure subscription active
- [ ] Terraform installed (v1.0+)
- [ ] Git configured
- [ ] Node.js 20.x installed
- [ ] Docker installed (optional, for local testing)
- [ ] Ansible installed (optional, for server deployments)

### Repository Setup
- [ ] Code pushed to GitHub
- [ ] Azure DevOps project created
- [ ] Repository imported to Azure Repos

---

## 🏗️ Phase 1: Infrastructure Deployment (Terraform)

### Step 1: Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
project_name = "cloud-notes-hub"
environment  = "prod"
location     = "East US"

supabase_url              = "https://YOUR-PROJECT.supabase.co"
supabase_anon_key         = "YOUR_ANON_KEY"
supabase_service_role_key = "YOUR_SERVICE_ROLE_KEY"

alert_email = "your-email@example.com"  # For monitoring alerts
```

### Step 2: Initialize Terraform

```bash
terraform init
```

**Expected output:** Provider downloads, backend initialization

### Step 3: Review Infrastructure Plan

```bash
terraform plan
```

**Resources to be created:**
- Resource Group
- Key Vault (with 3 secrets)
- Storage Account (with logs container)
- Log Analytics Workspace
- Application Insights
- 2 Monitoring Alerts
- Action Group
- Static Web App

**Expected:** ~13 resources to add

### Step 4: Apply Terraform Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Duration:** 3-5 minutes

### Step 5: Save Outputs

```bash
# Save all outputs
terraform output -json > ../outputs.json

# Display important values
terraform output resource_group_name
terraform output key_vault_name
terraform output static_web_app_name
terraform output static_web_app_url
terraform output -raw static_web_app_api_key
terraform output -raw application_insights_connection_string
```

**Save these values - you'll need them!**

---

## 🔐 Phase 2: Azure DevOps Setup

### Step 1: Create Personal Access Token (PAT)

1. Go to https://dev.azure.com/codecloudevops
2. User Settings → Personal access tokens
3. Click "+ New Token"
4. Settings:
   - Name: "Pipeline Access"
   - Expiration: 90 days
   - Scopes: **Agent Pools** (Read & manage)
5. **Copy the token immediately!**

### Step 2: Create Service Connection

1. Go to Project Settings → Service connections
2. Click "New service connection"
3. Select "Azure Resource Manager"
4. Choose "Service principal (automatic)"
5. Settings:
   - Subscription: Select your subscription
   - Scope: **Subscription** (recommended)
   - Service connection name: `Azure subscription 1 (95c7aa64-5227-422a-afbd-e8eb5cb30122)`
   - ✅ Grant access permission to all pipelines
6. Click "Save"

### Step 3: Create Variable Group

1. Go to Pipelines → Library
2. Click "+ Variable group"
3. Name: `cloud-notes-hub-secrets`
4. Add variable:
   - Name: `staticWebAppApiToken`
   - Value: [Paste from terraform output]
   - ✅ Mark as secret
5. Click "Save"

### Step 4: Link Key Vault (Optional but Recommended)

1. In the same variable group, click "Link secrets from an Azure key vault"
2. Select Azure subscription: `Azure subscription 1 (...)`
3. Authorize if prompted
4. Select Key Vault: `cloud-notes-hubprodkv`
5. Click "+ Add" and select:
   - `supabase-url`
   - `supabase-anon-key`
   - `app-insights-connection-string`
6. Click "Save"

---

## 🤖 Phase 3: Self-Hosted Agent Setup

### Check if Agent is Running

```bash
ps aux | grep "[A]gent.Listener"
```

**If running:** Skip to Phase 4

**If not running:**

```bash
cd ~/azagent
./run.sh &
```

**Verify:** Agent shows "Listening for Jobs"

---

## 🚀 Phase 4: Pipeline Execution

### Step 1: Verify Pipeline Configuration

File: `azure-pipelines.yml`

**Check these values match:**
- Line 14: `pool: name: 'Default'`
- Line 24: `keyVaultName: 'cloud-notes-hubprodkv'`
- Line 44, 110: Service connection name matches yours
- Variable group referenced: `cloud-notes-hub-secrets`

### Step 2: Run Initial Pipeline

1. Go to Azure DevOps → Pipelines → Pipelines
2. Select your pipeline
3. Click "Run pipeline"
4. Click "Run"

### Step 3: Authorize Resources (First Run Only)

When pipeline pauses, click "Permit" for:
- [ ] Service connection: `Azure subscription 1 (...)`
- [ ] Variable group: `cloud-notes-hub-secrets`
- [ ] Environment: `production`

### Step 4: Monitor Pipeline Execution

**Expected Stages:**
1. ✅ Build (5-10 min)
   - Install dependencies
   - Lint code
   - Type check
   - Build application
2. ✅ DockerBuild (3-5 min)
   - Get secrets from Key Vault
   - Build Docker image
   - Save image artifact
3. ✅ Deploy (2-3 min)
   - Download artifacts
   - Deploy to Static Web App
4. ✅ LogDeployment (1 min)
   - Upload logs to storage

**Total Duration:** ~15-20 minutes

### Step 5: Verify Deployment

```bash
# Get Static Web App URL
cd terraform
terraform output static_web_app_url
```

Open the URL in browser and verify:
- [ ] Application loads
- [ ] Can navigate to /login
- [ ] No console errors
- [ ] Assets loading correctly

---

## 📊 Phase 5: Monitoring Verification

### Step 1: Access Azure Portal

1. Go to https://portal.azure.com
2. Navigate to Resource Group: `cloud-notes-hub-prod-rg`

### Step 2: Verify Resources

Check these resources exist:
- [ ] Application Insights: `cloud-notes-hub-prod-ai`
- [ ] Log Analytics: `cloud-notes-hub-prod-law`
- [ ] Key Vault: `cloud-notes-hubprodkv`
- [ ] Storage Account: `cloudnoteshubprodst`
- [ ] Static Web App: `cloud-notes-hub-prod-swa`

### Step 3: Check Application Insights

1. Open Application Insights
2. Click "Live Metrics"
3. Visit your application URL
4. Verify:
   - [ ] Requests showing in Live Metrics
   - [ ] No errors appearing
   - [ ] Response times < 1s

### Step 4: Verify Alerts

1. Navigate to "Alerts" in Azure Portal
2. Check alert rules:
   - [ ] `cloud-notes-hub-prod-high-error-rate`
   - [ ] `cloud-notes-hub-prod-low-availability`

### Step 5: Confirm Email Subscription

1. Check email: codecloudevops@outlook.com
2. Look for "Azure Monitor alert" subscription email
3. Click "Confirm subscription" link

---

## 🧪 Phase 6: Testing

### Functional Testing

- [ ] User Registration
  1. Go to `/login`
  2. Create new account
  3. Verify email received (if configured)
  4. Login successful

- [ ] Notes CRUD Operations
  1. Create a new note
  2. Edit the note
  3. Mark as public/private
  4. Delete the note

- [ ] Admin Dashboard (if admin)
  1. Navigate to `/admin`
  2. View all notes
  3. View all users
  4. Verify realtime updates

### Performance Testing

```bash
# Simple load test with curl
for i in {1..10}; do
  curl -w "@-" -o /dev/null -s https://your-app-url.azurestaticapps.net <<'EOF'
    time_total:  %{time_total}s\n
EOF
done
```

**Expected:** Response times < 2s

### Monitoring Test

Trigger an error intentionally:
1. Navigate to non-existent route
2. Wait 5 minutes
3. Check Application Insights → Failures
4. Verify error logged

---

## 🐳 Phase 7: Docker Deployment (Optional)

### Local Docker Test

```bash
# Build image
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL="https://YOUR-PROJECT.supabase.co" \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY="YOUR_KEY" \
  -t cloud-notes-hub:test .

# Run container
docker run -d -p 3000:3000 --name cloud-notes-test cloud-notes-hub:test

# Test locally
curl http://localhost:3000/api/health

# Check logs
docker logs cloud-notes-test

# Cleanup
docker stop cloud-notes-test
docker rm cloud-notes-test
```

---

## 🤖 Phase 8: Ansible Deployment (Optional)

**Only if deploying to your own servers**

### Configure Inventory

Edit `ansible/inventory/hosts.yml`:
```yaml
production:
  hosts:
    cloud-notes-prod:
      ansible_host: YOUR_SERVER_IP
      ansible_user: YOUR_USERNAME
```

### Update Variables

Edit `ansible/group_vars/all.yml`:
```yaml
supabase_url: "https://YOUR-PROJECT.supabase.co"
supabase_anon_key: "YOUR_KEY"
nginx_server_name: "your-domain.com"
```

### Run Deployment

```bash
# Test connectivity
ansible all -i ansible/inventory/hosts.yml -m ping

# Deploy
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml
```

---

## ✅ Post-Deployment Checklist

### Documentation Review
- [ ] Read [SETUP_GUIDE.md](SETUP_GUIDE.md)
- [ ] Review [MONITORING.md](MONITORING.md)
- [ ] Check [DOCKER_ANSIBLE.md](DOCKER_ANSIBLE.md)

### Security
- [ ] Rotate Supabase service role key (not exposed publicly)
- [ ] Review Key Vault access policies
- [ ] Enable MFA on Azure account
- [ ] Review Static Web App authentication settings

### Monitoring
- [ ] Set up custom dashboard in Application Insights
- [ ] Configure availability tests
- [ ] Review alert thresholds
- [ ] Test alert notifications

### Backups
- [ ] Verify Supabase automatic backups enabled
- [ ] Document recovery procedures
- [ ] Test backup restoration (in staging)

### Performance
- [ ] Enable CDN for static assets (optional)
- [ ] Review Application Insights performance data
- [ ] Optimize slow queries
- [ ] Consider upgrading Static Web App SKU if needed

---

## 🆘 Troubleshooting

### Pipeline Fails

**Error:** "Service connection not found"
- **Fix:** Verify service connection name matches exactly in pipeline YAML

**Error:** "Key Vault secret not found"
- **Fix:** Check Key Vault has secrets: `az keyvault secret list --vault-name cloud-notes-hubprodkv`

**Error:** "Agent not available"
- **Fix:** Start agent: `cd ~/azagent && ./run.sh &`

### Application Not Loading

**Check:**
1. Static Web App URL is correct
2. Deployment succeeded in pipeline
3. Check browser console for errors
4. Verify Supabase connection strings

### Monitoring Not Working

**Check:**
1. Application Insights connection string in Key Vault
2. Instrumentation code in application (if added)
3. Wait 5-10 minutes for data to appear

---

## 📞 Support Resources

- **Azure DevOps:** https://dev.azure.com/codecloudevops
- **Azure Portal:** https://portal.azure.com
- **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Next.js Docs:** https://nextjs.org/docs
- **Supabase Docs:** https://supabase.com/docs

---

## 🎯 Success Criteria

Deployment is successful when:
- ✅ All Terraform resources created
- ✅ Pipeline runs without errors
- ✅ Application accessible via Static Web App URL
- ✅ Can create and manage notes
- ✅ Monitoring data appearing in Application Insights
- ✅ Alerts configured and email subscribed
- ✅ Logs being stored in Storage Account

---

**Estimated Total Time:** 45-60 minutes (excluding Terraform destroy wait)

**Good luck with your deployment! 🚀**
