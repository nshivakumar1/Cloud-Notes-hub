# Cloud Notes Hub 2.0 - Complete Setup Guide

This guide will walk you through setting up the entire Cloud Notes Hub 2.0 application from scratch, including Supabase configuration, local development, Azure infrastructure, and CI/CD pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Supabase Setup](#supabase-setup)
3. [Local Development Setup](#local-development-setup)
4. [Azure Infrastructure Setup](#azure-infrastructure-setup)
5. [Azure DevOps Pipeline Setup](#azure-devops-pipeline-setup)
6. [Testing the Application](#testing-the-application)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Node.js** 20.x or later ([Download](https://nodejs.org/))
- **npm** (comes with Node.js)
- **Git** ([Download](https://git-scm.com/))
- **Terraform** 1.0+ ([Download](https://www.terraform.io/downloads))
- **Azure CLI** ([Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))

### Required Accounts

- **Supabase Account** ([Sign up](https://supabase.com))
- **Azure Account** ([Sign up](https://azure.microsoft.com/free/))
- **Azure DevOps Account** ([Sign up](https://dev.azure.com/))
- **GitHub Account** (for OAuth - optional)
- **Google Account** (for OAuth - optional)

## Supabase Setup

### Step 1: Create a New Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Fill in the project details:
   - **Name**: Cloud Notes Hub
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is fine for development
4. Click "Create new project"
5. Wait for the project to finish setting up (2-3 minutes)

### Step 2: Get Your API Keys

1. Go to **Project Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. Copy and save these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (starts with `eyJ...`)
   - **service_role** key (starts with `eyJ...`)

### Step 3: Run Database Migrations

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New Query**
3. Open the file `supabase/migrations/00001_initial_schema.sql` from this project
4. Copy the entire contents
5. Paste into the Supabase SQL Editor
6. Click **Run** (bottom right)
7. You should see "Success. No rows returned"

### Step 4: Configure Authentication Providers

#### Email/Password (Enabled by Default)

Email/Password is already enabled. No action needed.

#### Google OAuth (Optional)

1. Go to **Authentication** > **Providers** in Supabase
2. Click **Google**
3. Enable the provider
4. Follow Supabase's instructions to create Google OAuth credentials
5. Add authorized redirect URL: `https://your-project.supabase.co/auth/v1/callback`

#### GitHub OAuth (Optional)

1. Go to **Authentication** > **Providers** in Supabase
2. Click **GitHub**
3. Enable the provider
4. Create a GitHub OAuth App at [https://github.com/settings/developers](https://github.com/settings/developers)
5. Set callback URL: `https://your-project.supabase.co/auth/v1/callback`
6. Copy Client ID and Client Secret to Supabase

### Step 5: Configure URL Configuration

1. Go to **Authentication** > **URL Configuration**
2. Add your site URL (for local dev): `http://localhost:3000`
3. Add redirect URLs:
   - `http://localhost:3000/auth/callback`
   - (Add production URL later when deployed)

## Local Development Setup

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd cloud-notes-hub
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Configure Environment Variables

1. Create a `.env.local` file:

```bash
cp .env.local.example .env.local
```

2. Edit `.env.local` with your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### Step 4: Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Step 5: Create Your First User

1. Navigate to [http://localhost:3000](http://localhost:3000)
2. You'll be redirected to the login page
3. Click "Sign up" (or use the Auth UI to create an account)
4. Use email/password or OAuth to create an account

### Step 6: Make Yourself an Admin

1. Go to your Supabase Dashboard
2. Click **Table Editor** > **profiles**
3. Find your user (by email)
4. Edit the row and set `is_admin` to `true`
5. Click **Save**
6. Refresh your app - you should now see "Admin Dashboard" link

## Azure Infrastructure Setup

### Step 1: Install and Login to Azure CLI

```bash
# Install Azure CLI (if not already installed)
# See: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Set your subscription (if you have multiple)
az account list
az account set --subscription "Your Subscription Name"
```

### Step 2: Configure Terraform Variables

1. Navigate to the terraform directory:

```bash
cd terraform
```

2. Create your variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars`:

```hcl
project_name = "cloud-notes-hub"
environment  = "prod"
location     = "East US"

supabase_url              = "https://your-project.supabase.co"
supabase_anon_key         = "your-anon-key"
supabase_service_role_key = "your-service-role-key"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will download the required Azure provider plugins.

### Step 4: Review the Terraform Plan

```bash
terraform plan
```

Review the resources that will be created:
- Resource Group
- Azure Key Vault
- Storage Account (with logs container)
- Azure Static Web App

### Step 5: Apply Terraform Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will take 2-3 minutes.

### Step 6: Save Important Outputs

After Terraform completes, save these outputs:

```bash
terraform output -json > outputs.json
```

You'll need:
- `static_web_app_api_key` (for deployment)
- `key_vault_name`
- `storage_account_name`

To view the API key:

```bash
terraform output static_web_app_api_key
```

## Azure DevOps Pipeline Setup

### Step 1: Create Azure DevOps Project

1. Go to [https://dev.azure.com](https://dev.azure.com)
2. Click **New Project**
3. Name it "Cloud Notes Hub"
4. Click **Create**

### Step 2: Import Your Repository

1. Go to **Repos** in the left sidebar
2. Click **Import** > **Import a Git repository**
3. Enter your repository URL
4. Click **Import**

### Step 3: Create Azure Service Connection

1. Go to **Project Settings** (bottom left)
2. Click **Service connections**
3. Click **New service connection**
4. Select **Azure Resource Manager**
5. Select **Service principal (automatic)**
6. Choose your subscription
7. Resource group: Select the one created by Terraform
8. Name it: `azure-cloud-notes-hub`
9. Check "Grant access permission to all pipelines"
10. Click **Save**

### Step 4: Create Variable Group

1. Go to **Pipelines** > **Library**
2. Click **+ Variable group**
3. Name it: `cloud-notes-hub-secrets`
4. Add these variables:

| Variable Name | Value | Secret? |
|--------------|-------|---------|
| azureSubscription | azure-cloud-notes-hub | No |
| keyVaultName | (from Terraform output) | No |
| storageAccountName | (from Terraform output) | No |
| staticWebAppApiToken | (from Terraform output) | Yes |

5. Click **Save**

### Step 5: Link Key Vault (Optional but Recommended)

1. In the same variable group, click **Link secrets from an Azure key vault as variables**
2. Select your Azure subscription
3. Select your Key Vault name
4. Click **Authorize**
5. Add these secrets:
   - `supabase-url`
   - `supabase-anon-key`
6. Click **Save**

### Step 6: Create the Pipeline

1. Go to **Pipelines** > **Pipelines**
2. Click **New Pipeline**
3. Select **Azure Repos Git**
4. Select your repository
5. Select **Existing Azure Pipelines YAML file**
6. Path: `/azure-pipelines.yml`
7. Click **Continue**
8. Review the pipeline YAML
9. Click **Run**

### Step 7: Grant Permissions

The first time the pipeline runs, you may need to grant permissions:
1. The pipeline will pause and ask for permissions
2. Click **View** > **Permit** for each resource
3. The pipeline will then continue

## Testing the Application

### Test Local Development

1. Start the dev server:
```bash
npm run dev
```

2. Test user flows:
   - Sign up a new user
   - Create a note
   - Edit the note
   - Delete the note
   - Toggle public/private
   - Sign out and back in

3. Test admin features:
   - Make a user admin in Supabase
   - Access `/admin` route
   - View all notes
   - Edit/delete other users' notes
   - Toggle visibility

### Test Production Deployment

1. After the pipeline completes, get your Static Web App URL:
```bash
cd terraform
terraform output static_web_app_url
```

2. Open the URL in your browser
3. Test the same flows as local
4. Verify environment variables are working

### Test Real-time Features

1. Open the app in two browser windows
2. Create a note in one window
3. Verify it appears in the other window
4. Test with admin dashboard - changes should appear instantly

## Troubleshooting

### Local Development Issues

**Problem**: "Module not found" errors

```bash
# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Problem**: TypeScript errors

```bash
# Regenerate types
npm run build
```

**Problem**: Can't connect to Supabase

1. Verify `.env.local` has correct values
2. Check Supabase project is running
3. Verify URL doesn't have trailing slash

### Terraform Issues

**Problem**: Authentication failed

```bash
# Re-login to Azure
az logout
az login
```

**Problem**: Resource already exists

```bash
# Import existing resource or destroy manually
az group delete --name cloud-notes-hub-prod-rg
```

**Problem**: Key Vault name taken

Edit `terraform/main.tf` and change the Key Vault naming:

```hcl
name = "${var.project_name}${var.environment}${random_string.suffix.result}kv"
```

### Pipeline Issues

**Problem**: Pipeline fails at "Get Secrets from Key Vault"

1. Verify service connection has access to Key Vault
2. Check variable group has correct Key Vault name
3. Add access policy in Azure:

```bash
az keyvault set-policy --name YOUR_VAULT_NAME \
  --spn YOUR_SERVICE_PRINCIPAL \
  --secret-permissions get list
```

**Problem**: Static Web App deployment fails

1. Verify API token is correct
2. Check it's marked as secret in variable group
3. Regenerate token if needed:

```bash
az staticwebapp secrets list --name YOUR_APP_NAME
```

### Authentication Issues

**Problem**: OAuth redirect fails

1. Check redirect URLs in Supabase match your domain
2. For local dev: `http://localhost:3000/auth/callback`
3. For prod: `https://your-app.azurestaticapps.net/auth/callback`

**Problem**: Users can't sign up

1. Check Supabase email settings
2. Verify email confirmation is disabled for development
3. Check browser console for errors

### Admin Access Issues

**Problem**: Can't access `/admin` route

1. Verify user has `is_admin = true` in profiles table
2. Check middleware is working:
   - Look for middleware logs
   - Verify session is valid
3. Clear cookies and sign in again

## Next Steps

After completing setup:

1. Customize the branding and styling
2. Add more authentication providers
3. Implement additional features (see README)
4. Set up monitoring and alerts
5. Configure custom domain for Static Web App
6. Set up staging environment

## Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Azure Static Web Apps Docs](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)

## Support

If you run into issues:
1. Check this guide's troubleshooting section
2. Review application logs in Azure
3. Check Supabase logs
4. Open an issue in the repository
