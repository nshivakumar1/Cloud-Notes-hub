# Docker & Ansible Deployment Guide

This guide covers containerization with Docker and automated deployment with Ansible for Cloud Notes Hub.

## Table of Contents
- [Docker Setup](#docker-setup)
- [Ansible Automation](#ansible-automation)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment Workflows](#deployment-workflows)
- [Troubleshooting](#troubleshooting)

---

## Docker Setup

### Prerequisites
- Docker 20.10 or higher
- Docker Compose v2.0 or higher
- Node.js 20.x (for local development)

### Building the Docker Image

#### Local Build
```bash
# Build with environment variables
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL="https://your-project.supabase.co" \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY="your-anon-key" \
  -t cloud-notes-hub:latest .
```

#### Multi-platform Build
```bash
# Build for ARM64 and AMD64
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg NEXT_PUBLIC_SUPABASE_URL="https://your-project.supabase.co" \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY="your-anon-key" \
  -t cloud-notes-hub:latest \
  --push .
```

### Running with Docker

#### Using Docker Run
```bash
docker run -d \
  --name cloud-notes-hub \
  -p 3000:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL="https://your-project.supabase.co" \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY="your-anon-key" \
  --restart unless-stopped \
  cloud-notes-hub:latest
```

#### Using Docker Compose
```bash
# Create .env file
cat > .env <<EOF
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
EOF

# Start the application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the application
docker-compose down
```

### Docker Image Optimization

The Dockerfile uses multi-stage builds for optimization:

1. **Stage 1 (deps)**: Installs production dependencies
2. **Stage 2 (builder)**: Builds the Next.js application
3. **Stage 3 (runner)**: Creates minimal runtime image

**Benefits:**
- Small image size (~150MB vs ~1GB)
- Fast build times with layer caching
- Production-optimized with standalone output
- Non-root user for security

### Health Checks

The container includes a health check that runs every 30 seconds:

```bash
# Check container health
docker ps

# Manual health check
docker exec cloud-notes-hub node -e "require('http').get('http://localhost:3000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
```

---

## Ansible Automation

### Prerequisites

```bash
# Install Ansible
pip install ansible

# Install required collections
ansible-galaxy collection install community.docker
ansible-galaxy collection install ansible.posix
```

### Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   └── hosts.yml              # Inventory file
├── group_vars/
│   └── all.yml                # Global variables
├── playbooks/
│   └── deploy.yml             # Main deployment playbook
├── roles/
│   ├── docker/                # Docker installation role
│   ├── nginx/                 # Nginx reverse proxy role
│   └── monitoring/            # Monitoring setup role
└── templates/
    ├── docker-compose.yml.j2  # Docker Compose template
    ├── .env.j2                # Environment file template
    └── nginx.conf.j2          # Nginx configuration template
```

### Configuration

#### 1. Update Inventory

Edit `ansible/inventory/hosts.yml`:

```yaml
production:
  hosts:
    cloud-notes-prod:
      ansible_host: YOUR_SERVER_IP
      ansible_user: azureuser
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

#### 2. Configure Variables

Edit `ansible/group_vars/all.yml`:

```yaml
# Application Configuration
app_name: "cloud-notes-hub"
app_version: "latest"
app_port: 3000

# Docker Registry (optional)
docker_registry: "your-registry.azurecr.io"

# Environment Variables
supabase_url: "https://your-project.supabase.co"
supabase_anon_key: "your-anon-key"

# Nginx Configuration
nginx_server_name: "your-domain.com"
nginx_ssl_enabled: false  # Set to true when you have SSL certs
```

### Deployment Playbooks

#### Deploy Application

```bash
# Deploy to production
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml

# Deploy to staging
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml -e "target=staging"

# Deploy specific version
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml -e "app_version=1.2.3"

# Dry run (check mode)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml --check
```

#### Common Tasks

```bash
# Check connectivity
ansible all -i ansible/inventory/hosts.yml -m ping

# Run health check
ansible all -i ansible/inventory/hosts.yml -a "/usr/local/bin/health-check"

# View application logs
ansible all -i ansible/inventory/hosts.yml -a "docker logs cloud-notes-hub-app --tail 50"

# Restart application
ansible all -i ansible/inventory/hosts.yml -a "docker-compose -f /opt/cloud-notes-hub/docker-compose.yml restart"
```

### Ansible Roles

#### Docker Role
- Installs Docker and Docker Compose
- Configures Docker daemon
- Sets up log rotation
- Adds user to docker group

#### Nginx Role
- Installs and configures Nginx
- Sets up reverse proxy
- Configures SSL/TLS (when enabled)
- Adds security headers
- Enables gzip compression

#### Monitoring Role
- Installs system monitoring tools
- Sets up log rotation
- Creates health check scripts
- Configures automated backups

---

## CI/CD Pipeline

The Azure DevOps pipeline includes a Docker build stage:

### Pipeline Stages

1. **Build**: Lint, test, and build Next.js application
2. **DockerBuild**: Build and save Docker image
3. **Deploy**: Deploy to Azure Static Web Apps
4. **LogDeployment**: Upload deployment logs

### Docker Build Stage

```yaml
- stage: DockerBuild
  displayName: 'Build and Push Docker Image'
  jobs:
    - job: BuildDockerImage
      steps:
        - task: Docker@2
          inputs:
            command: 'build'
            Dockerfile: 'Dockerfile'
            tags: '$(Build.BuildId),latest'
```

### Pipeline Variables

Required variables in Azure DevOps:
- `staticWebAppApiToken`: From Terraform output
- Key Vault secrets:
  - `supabase-url`
  - `supabase-anon-key`

---

## Deployment Workflows

### Workflow 1: Manual Docker Deployment

```bash
# 1. Build the image
docker build -t cloud-notes-hub:v1.0.0 .

# 2. Save the image
docker save cloud-notes-hub:v1.0.0 | gzip > cloud-notes-hub-v1.0.0.tar.gz

# 3. Transfer to server
scp cloud-notes-hub-v1.0.0.tar.gz user@server:/tmp/

# 4. Load on server
ssh user@server
docker load < /tmp/cloud-notes-hub-v1.0.0.tar.gz

# 5. Run the container
docker run -d --name cloud-notes-hub -p 3000:3000 cloud-notes-hub:v1.0.0
```

### Workflow 2: Ansible Automated Deployment

```bash
# 1. Update version in group_vars
vi ansible/group_vars/all.yml
# Set: app_version: "v1.0.0"

# 2. Run deployment playbook
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml

# 3. Verify deployment
ansible all -i ansible/inventory/hosts.yml -a "docker ps"
ansible all -i ansible/inventory/hosts.yml -a "curl -s http://localhost:3000/api/health"
```

### Workflow 3: CI/CD Pipeline Deployment

1. Push code to `main` branch
2. Pipeline automatically:
   - Runs tests and linting
   - Builds Next.js application
   - Creates Docker image
   - Deploys to Azure Static Web Apps
   - Uploads logs to Azure Storage

---

## Monitoring & Maintenance

### Container Logs

```bash
# View logs
docker logs cloud-notes-hub-app

# Follow logs
docker logs -f cloud-notes-hub-app

# Last 100 lines
docker logs --tail 100 cloud-notes-hub-app

# With timestamps
docker logs --timestamps cloud-notes-hub-app
```

### Container Stats

```bash
# Resource usage
docker stats cloud-notes-hub-app

# All containers
docker stats

# Container inspect
docker inspect cloud-notes-hub-app
```

### Backups

Ansible creates automatic daily backups at 2 AM:

```bash
# Manual backup
ssh user@server
/usr/local/bin/backup-app

# View backups
ls -lh /var/backups/cloud-notes-hub/
```

### Updates

```bash
# Pull latest image
docker pull cloud-notes-hub:latest

# Recreate container
docker-compose up -d --force-recreate

# Or use Ansible
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy.yml -e "app_version=latest"
```

---

## Troubleshooting

### Common Issues

#### Container Won't Start

```bash
# Check logs
docker logs cloud-notes-hub-app

# Check health
docker inspect --format='{{.State.Health.Status}}' cloud-notes-hub-app

# Verify environment variables
docker exec cloud-notes-hub-app env | grep NEXT_PUBLIC
```

#### High Memory Usage

```bash
# Check container stats
docker stats cloud-notes-hub-app

# Restart container
docker restart cloud-notes-hub-app

# Or limit memory
docker update --memory="512m" --memory-swap="1g" cloud-notes-hub-app
```

#### Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
docker run -p 3001:3000 cloud-notes-hub:latest
```

#### Ansible Connection Issues

```bash
# Test connectivity
ansible all -i ansible/inventory/hosts.yml -m ping

# Check SSH
ssh -vvv user@server

# Use different SSH key
ansible-playbook ... --private-key=~/.ssh/other_key
```

#### Docker Build Fails

```bash
# Clear build cache
docker builder prune

# Build without cache
docker build --no-cache -t cloud-notes-hub:latest .

# Check Dockerfile syntax
docker build --check .
```

### Performance Optimization

#### Enable BuildKit

```bash
# In ~/.bashrc or ~/.zshrc
export DOCKER_BUILDKIT=1

# Or per-build
DOCKER_BUILDKIT=1 docker build -t cloud-notes-hub:latest .
```

#### Multi-stage Build Caching

```bash
# Cache dependencies layer
docker build --target deps --tag cloud-notes-hub:deps .

# Use cached deps
docker build --cache-from cloud-notes-hub:deps -t cloud-notes-hub:latest .
```

### Security Best Practices

1. **Use non-root user** ✓ (Already implemented)
2. **Scan images for vulnerabilities**:
   ```bash
   docker scan cloud-notes-hub:latest
   ```
3. **Keep base images updated**:
   ```bash
   docker pull node:20-alpine
   docker build --pull -t cloud-notes-hub:latest .
   ```
4. **Use secrets management**:
   - Store secrets in Azure Key Vault
   - Retrieve at runtime via Ansible
   - Never commit secrets to Git

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Next.js Docker Deployment](https://nextjs.org/docs/deployment#docker-image)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Need Help?**
- Check container logs: `docker logs cloud-notes-hub-app`
- Run health check: `curl http://localhost:3000/api/health`
- Review Ansible output for deployment issues
- Check [MONITORING.md](MONITORING.md) for application insights
