# Ansible Semaphore - Web UI Portal

This guide covers setting up and using Ansible Semaphore, a modern web interface for managing Ansible playbooks and monitoring deployments.

## 📋 Table of Contents
- [What is Ansible Semaphore?](#what-is-ansible-semaphore)
- [Quick Start](#quick-start)
- [Initial Setup](#initial-setup)
- [Configuration](#configuration)
- [Using the Web UI](#using-the-web-ui)
- [Monitoring Deployments](#monitoring-deployments)
- [Troubleshooting](#troubleshooting)

---

## What is Ansible Semaphore?

Ansible Semaphore is a modern, open-source web UI for Ansible that provides:

- 🎯 **Visual Playbook Execution** - Run playbooks from a web interface
- 📊 **Real-time Monitoring** - Watch deployment progress live
- 📜 **Execution History** - Review past deployments and logs
- 🔐 **Access Control** - Manage user permissions
- 📅 **Scheduled Jobs** - Automate recurring tasks
- 🔔 **Notifications** - Get alerts on deployment status
- 📱 **Mobile Friendly** - Monitor from anywhere

**Why use it?**
- No need to SSH into servers
- Team members can deploy without Ansible knowledge
- Audit trail of all deployments
- Easier troubleshooting with visual logs

---

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Ansible playbooks configured (already done ✓)
- 2GB RAM minimum
- Port 3001 available

### Start Semaphore

```bash
cd ansible
./start-semaphore.sh
```

This script will:
1. Generate secure passwords
2. Create `.env.semaphore` file
3. Start PostgreSQL and Semaphore containers
4. Display access credentials

**Access:** http://localhost:3001

**Default Credentials:**
- Username: `admin`
- Password: [Check `.env.semaphore` file]

---

## Initial Setup

### Step 1: First Login

1. Open http://localhost:3001
2. Login with admin credentials
3. You'll see the dashboard

### Step 2: Create a Project

1. Click **"New Project"** (top right)
2. Fill in details:
   - **Name:** `Cloud Notes Hub`
   - **Max Parallel Tasks:** `3`
3. Click **"Create"**

### Step 3: Create Key Store (SSH Keys)

1. Go to **Key Store** tab
2. Click **"New Key"**
3. Configure:
   - **Name:** `Production SSH Key`
   - **Type:** `SSH Key`
   - **Username:** `azureuser` (your SSH user)
   - **Private Key:** Paste your SSH private key content
     ```bash
     cat ~/.ssh/id_rsa  # Copy this content
     ```
4. Click **"Create"**

### Step 4: Add Inventory

1. Go to **Inventory** tab
2. Click **"New Inventory"**
3. Configure:
   - **Name:** `Production Servers`
   - **User Credentials:** Select your SSH key
   - **Type:** `Static`
   - **Inventory:** Paste content from `inventory/hosts.yml`
     ```bash
     cat inventory/hosts.yml  # Copy this content
     ```
4. Click **"Create"**

### Step 5: Add Git Repository

1. Go to **Repositories** tab
2. Click **"New Repository"**
3. Configure:
   - **Name:** `Cloud Notes Hub Playbooks`
   - **URL:** `file:///ansible` (local mount)
   - Or use Git: `https://github.com/nshivakumar1/Cloud-Notes-hub.git`
   - **Branch:** `main`
   - **Access Key:** (Leave empty for public repo or local)
4. Click **"Create"**

### Step 6: Create Environment

1. Go to **Environment** tab
2. Click **"New Environment"**
3. Configure:
   - **Name:** `Production`
   - **Variables (JSON):**
     ```json
     {
       "ansible_python_interpreter": "/usr/bin/python3",
       "supabase_url": "{{ lookup('env', 'SUPABASE_URL') }}",
       "supabase_anon_key": "{{ lookup('env', 'SUPABASE_ANON_KEY') }}"
     }
     ```
   - **Environment variables (KEY=VALUE):**
     ```
     SUPABASE_URL=https://your-project.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     ```
4. Click **"Create"**

### Step 7: Add Task Template

1. Go to **Task Templates** tab
2. Click **"New Template"**
3. Configure:
   - **Name:** `Deploy Application`
   - **Playbook Filename:** `playbooks/deploy.yml`
   - **Inventory:** Select `Production Servers`
   - **Repository:** Select `Cloud Notes Hub Playbooks`
   - **Environment:** Select `Production`
   - **Allow CLI Args:** ✓ (checked)
4. Click **"Create"**

---

## Configuration

### Environment Variables

Edit `ansible/.env.semaphore`:

```bash
# Database
POSTGRES_PASSWORD=your_secure_password

# Admin Access
SEMAPHORE_ADMIN_PASSWORD=your_admin_password
ADMIN_EMAIL=your-email@example.com

# Security
ACCESS_KEY_ENCRYPTION=32-character-secret-key
```

### Port Configuration

To change the port (default 3001):

Edit `ansible/semaphore-docker-compose.yml`:
```yaml
ports:
  - "8080:3000"  # Change 8080 to your desired port
```

### External Access

To access from other machines:

1. Update docker-compose to bind to all interfaces:
   ```yaml
   ports:
     - "0.0.0.0:3001:3000"
   ```

2. Configure firewall:
   ```bash
   sudo ufw allow 3001/tcp
   ```

3. Access via: `http://YOUR_SERVER_IP:3001`

---

## Using the Web UI

### Dashboard Overview

The dashboard shows:
- **Recent Tasks** - Last deployment runs
- **Project Statistics** - Success/failure rates
- **Active Tasks** - Currently running jobs
- **Quick Actions** - Run common playbooks

### Running a Deployment

1. Click **Task Templates** tab
2. Find your template (e.g., "Deploy Application")
3. Click **"Run"** button (▶️)
4. Optional: Add CLI arguments:
   ```
   -e "app_version=v1.0.0"
   ```
5. Click **"Run"**

### Monitoring Live Deployment

When a task runs:
1. You'll see real-time output
2. Color-coded stages:
   - 🔵 Blue = Running
   - ✅ Green = Success
   - ❌ Red = Failed
   - ⏸️ Gray = Skipped
3. Expand tasks to see detailed output
4. Download logs using download button

### Viewing History

1. Go to **History** tab
2. View all past deployments
3. Filter by:
   - Template
   - Status (Success/Failed)
   - Date range
4. Click any task to view full logs

### Scheduled Deployments

1. Go to **Task Templates**
2. Click your template
3. Enable **"Schedule"**
4. Set cron expression:
   ```
   0 2 * * *    # Daily at 2 AM
   0 */4 * * *  # Every 4 hours
   0 0 * * 0    # Weekly on Sunday
   ```
5. Save

---

## Monitoring Deployments

### Dashboard Widgets

**Task Status Overview:**
- Total runs
- Success rate
- Average duration
- Failed tasks

**Resource Usage:**
- Server connections
- Active deployments
- Queue length

### Notifications

Configure alerts:

1. Go to **Settings** → **Notifications**
2. Add integrations:
   - **Email** - Send to your email
   - **Slack** - Post to Slack channel
   - **Telegram** - Send Telegram messages
   - **Webhooks** - Custom integrations

Example Email Setup:
```yaml
Type: Email
Recipients: ops-team@company.com
Events:
  - Task Failed
  - Task Success (optional)
```

### Real-Time Monitoring

**Live Task View:**
1. Navigate to running task
2. Watch output stream live
3. See:
   - Current play/task
   - Hosts being configured
   - Task duration
   - Variables being applied

**Multi-Task View:**
- See all running tasks
- Compare parallel deployments
- Identify bottlenecks

---

## Advanced Features

### Role-Based Access Control

Create team members:

1. Go to **Team** tab
2. Click **"New User"**
3. Configure:
   - Username
   - Email
   - Password
   - Admin privileges (yes/no)
4. Assign project access

### CLI Integration

Semaphore also works via API:

```bash
# Get task status
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3001/api/project/1/tasks

# Run playbook
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:3001/api/project/1/tasks \
  -d '{"template_id": 1}'
```

### Backup Configuration

Backup Semaphore data:

```bash
# Backup database
docker exec semaphore-postgres pg_dump -U semaphore semaphore > semaphore-backup.sql

# Backup Docker volumes
docker run --rm \
  -v semaphore-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/semaphore-data-backup.tar.gz /data
```

Restore:

```bash
# Restore database
cat semaphore-backup.sql | docker exec -i semaphore-postgres psql -U semaphore semaphore

# Restore volumes
docker run --rm \
  -v semaphore-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd / && tar xzf /backup/semaphore-data-backup.tar.gz"
```

---

## Troubleshooting

### Semaphore Won't Start

```bash
# Check Docker status
docker ps -a

# View logs
cd ansible
docker-compose -f semaphore-docker-compose.yml logs

# Restart services
docker-compose -f semaphore-docker-compose.yml restart
```

### Cannot Connect to Database

```bash
# Check PostgreSQL
docker exec semaphore-postgres pg_isready -U semaphore

# Reset database (⚠️ destroys data)
docker-compose -f semaphore-docker-compose.yml down -v
./start-semaphore.sh
```

### Playbook Fails to Run

**Check:**
1. SSH key is correct in Key Store
2. Inventory is properly formatted
3. Server is reachable:
   ```bash
   docker exec semaphore-ui ansible all -i /ansible/inventory/hosts.yml -m ping
   ```

### Port Already in Use

```bash
# Find process using port 3001
lsof -i :3001

# Change port in docker-compose.yml
# Then restart
docker-compose -f semaphore-docker-compose.yml up -d --force-recreate
```

### Forgot Admin Password

```bash
# Stop Semaphore
docker-compose -f semaphore-docker-compose.yml down

# Update password in .env.semaphore
vi .env.semaphore

# Restart
docker-compose -f semaphore-docker-compose.yml up -d
```

---

## Management Commands

### Start/Stop/Restart

```bash
cd ansible

# Start
docker-compose -f semaphore-docker-compose.yml up -d

# Stop
docker-compose -f semaphore-docker-compose.yml down

# Restart
docker-compose -f semaphore-docker-compose.yml restart

# View logs
docker-compose -f semaphore-docker-compose.yml logs -f
```

### Update Semaphore

```bash
# Pull latest image
docker-compose -f semaphore-docker-compose.yml pull

# Recreate containers
docker-compose -f semaphore-docker-compose.yml up -d --force-recreate
```

### Clean Up

```bash
# Remove containers and volumes (⚠️ destroys data)
docker-compose -f semaphore-docker-compose.yml down -v

# Remove images
docker rmi semaphoreui/semaphore:latest
docker rmi postgres:15-alpine
```

---

## Security Best Practices

1. **Change Default Passwords**
   - Update admin password immediately
   - Use strong, unique passwords

2. **Restrict Network Access**
   - Don't expose to public internet
   - Use firewall rules
   - Consider VPN access

3. **Enable HTTPS**
   - Use reverse proxy (Nginx)
   - Add SSL certificate
   - Redirect HTTP to HTTPS

4. **Regular Backups**
   - Backup database daily
   - Store backups securely
   - Test restoration process

5. **Audit Logs**
   - Review deployment history
   - Monitor failed attempts
   - Track user actions

---

## Integration with Cloud Notes Hub

### Deployment Workflow

1. **Code Push** → GitHub
2. **Pipeline** → Builds Docker image
3. **Semaphore** → Deploys to servers
4. **Monitoring** → Application Insights

### Common Templates to Create

1. **Deploy Application** - Full deployment
2. **Update Configuration** - Change settings
3. **Restart Services** - Quick restart
4. **Run Health Check** - Verify system
5. **View Logs** - Collect logs
6. **Backup Database** - Manual backup

### Environment Variables Needed

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_VERSION=latest
DOCKER_REGISTRY=your-registry.azurecr.io
```

---

## Screenshots Guide

### Dashboard
- Overview of all deployments
- Quick access to common tasks
- Real-time status

### Task Execution
- Live output streaming
- Task progress indicators
- Downloadable logs

### History
- Filterable deployment history
- Success/failure analytics
- Detailed logs for each run

---

## Additional Resources

- **Semaphore Docs:** https://docs.ansible-semaphore.com/
- **GitHub:** https://github.com/ansible-semaphore/semaphore
- **Community:** https://github.com/ansible-semaphore/semaphore/discussions

---

## Quick Reference

### URLs
- **Web UI:** http://localhost:3001
- **API:** http://localhost:3001/api
- **Health:** http://localhost:3001/api/ping

### Default Credentials
- **Username:** admin
- **Password:** Check `.env.semaphore`

### Important Files
- **Config:** `ansible/.env.semaphore`
- **Compose:** `ansible/semaphore-docker-compose.yml`
- **Startup:** `ansible/start-semaphore.sh`

### Common Tasks
```bash
# Start
./ansible/start-semaphore.sh

# Stop
docker-compose -f ansible/semaphore-docker-compose.yml down

# Logs
docker-compose -f ansible/semaphore-docker-compose.yml logs -f

# Backup
docker exec semaphore-postgres pg_dump -U semaphore > backup.sql
```

---

**Ready to manage your infrastructure with a modern UI! 🚀**
