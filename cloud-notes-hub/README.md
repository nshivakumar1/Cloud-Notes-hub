# Cloud Notes Hub 2.0

A full-stack cloud notes application built with Next.js, Supabase, and Azure infrastructure. Features include user authentication, CRUD operations for notes, admin dashboard with real-time updates, and complete Infrastructure as Code (IaC) deployment.

## Features

### Frontend App (User Side)
- **React/Next.js** hosted on Azure Static Web Apps
- Create, edit, and delete notes stored in Supabase Postgres
- Supabase Auth for user login (Email/Password, Google, GitHub)
- Real-time note synchronization
- Public/Private note visibility toggle

### Frontend Admin Panel
- Admin dashboard with real-time table view
- Full CRUD operations on all notes
- User management and filtering
- Role-based access control (RLS) permissions
- Real-time data updates using Supabase subscriptions

### Infrastructure as Code (Terraform)
- Azure Static Web App for hosting
- Azure Storage for deployment logs
- Azure Key Vault for secure credential management
- Automated resource provisioning

### CI/CD (Azure DevOps)
- Automated build and test pipeline
- Environment variable injection from Key Vault
- Deployment to Azure Static Web Apps
- Triggered on main branch commits
- Deployment logging to Azure Storage

## Tech Stack

- **Frontend**: Next.js 15, React, TypeScript, Tailwind CSS
- **Backend**: Supabase (PostgreSQL, Authentication, Real-time)
- **Infrastructure**: Terraform, Azure (Static Web Apps, Key Vault, Storage)
- **CI/CD**: Azure DevOps Pipelines
- **Security**: Row-Level Security (RLS), Azure Key Vault

## Project Structure

```
cloud-notes-hub/
├── app/
│   ├── page.tsx                 # Home page (redirects to login)
│   ├── login/                   # Authentication page
│   ├── dashboard/               # User dashboard
│   ├── admin/                   # Admin dashboard
│   └── auth/callback/           # OAuth callback handler
├── components/
│   ├── auth/                    # Authentication components
│   ├── notes/                   # Note-related components
│   │   ├── NoteCard.tsx        # Individual note display
│   │   └── NewNoteForm.tsx     # Note creation form
│   └── admin/
│       └── AdminNotesTable.tsx # Admin table component
├── lib/
│   ├── supabase/
│   │   ├── client.ts           # Client-side Supabase client
│   │   ├── server.ts           # Server-side Supabase client
│   │   └── middleware.ts       # Auth middleware
│   └── database.types.ts       # TypeScript database types
├── supabase/
│   └── migrations/
│       └── 00001_initial_schema.sql  # Database schema
├── terraform/
│   ├── main.tf                 # Infrastructure configuration
│   └── terraform.tfvars.example
├── azure-pipelines.yml         # CI/CD pipeline
└── middleware.ts               # Next.js middleware
```

## Getting Started

### Prerequisites

- Node.js 20.x or later
- npm or yarn
- Supabase account
- Azure account (for production deployment)
- Terraform (for infrastructure provisioning)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd cloud-notes-hub
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Navigate to Project Settings > API
3. Copy your project URL and anon key
4. Run the migration script in the Supabase SQL editor:

```bash
# Copy the contents of supabase/migrations/00001_initial_schema.sql
# and run it in your Supabase SQL editor
```

### 4. Configure Environment Variables

Create a `.env.local` file:

```bash
cp .env.local.example .env.local
```

Fill in your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=your-supabase-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application.

### 6. Create Admin User

After signing up, you need to manually set your user as an admin in Supabase:

1. Go to Supabase Dashboard > Table Editor > profiles
2. Find your user record
3. Set `is_admin` to `true`

## Database Schema

### Tables

#### `profiles`
- `id` (UUID, Primary Key) - References auth.users
- `created_at` (Timestamp)
- `email` (Text)
- `full_name` (Text, Nullable)
- `avatar_url` (Text, Nullable)
- `is_admin` (Boolean, Default: false)

#### `notes`
- `id` (UUID, Primary Key)
- `created_at` (Timestamp)
- `updated_at` (Timestamp)
- `title` (Text)
- `content` (Text)
- `user_id` (UUID, Foreign Key to auth.users)
- `is_public` (Boolean, Default: false)

### Row Level Security (RLS) Policies

**Profiles:**
- Public profiles viewable by everyone
- Users can insert/update their own profile

**Notes:**
- Users can view their own notes
- Users can view public notes
- Users can CRUD their own notes
- Admins can view/update/delete all notes

## Infrastructure Deployment

### Terraform Setup

1. Navigate to the terraform directory:

```bash
cd terraform
```

2. Create your variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Fill in your values in `terraform.tfvars`

4. Initialize Terraform:

```bash
terraform init
```

5. Review the plan:

```bash
terraform plan
```

6. Apply the infrastructure:

```bash
terraform apply
```

### Resources Created

- **Resource Group**: Container for all resources
- **Azure Key Vault**: Secure storage for Supabase credentials
- **Azure Storage Account**: Storage for deployment logs
- **Azure Static Web App**: Hosting for the Next.js application

## Azure DevOps Pipeline Setup

### 1. Create Variable Group

In Azure DevOps:
1. Go to Pipelines > Library
2. Create a variable group named `cloud-notes-hub-secrets`
3. Add these variables:
   - `azureSubscription` - Your Azure service connection name
   - `keyVaultName` - Name of your Key Vault
   - `storageAccountName` - Name of your Storage Account
   - `staticWebAppApiToken` - Static Web App deployment token

### 2. Create Pipeline

1. Go to Pipelines > Create Pipeline
2. Select your repository
3. Choose "Existing Azure Pipelines YAML file"
4. Select `azure-pipelines.yml`
5. Save and run

### 3. Pipeline Stages

The pipeline has three stages:

1. **Build**: Install dependencies, lint, type-check, build
2. **Deploy**: Deploy to Azure Static Web Apps with environment variables
3. **LogDeployment**: Upload deployment logs to Azure Storage

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## Authentication Providers

The application supports:
- Email/Password authentication
- Google OAuth
- GitHub OAuth

Configure providers in your Supabase Dashboard under Authentication > Providers.

## Admin Dashboard

Access the admin dashboard at `/admin` (requires admin privileges).

Features:
- View all notes in real-time
- Filter by search term or public/private status
- Edit any note inline
- Delete any note
- Toggle note visibility (public/private)
- View note authors

## Security Features

- Row-Level Security (RLS) policies on all tables
- Secure credential storage in Azure Key Vault
- Environment variable injection during build
- Protected admin routes via middleware
- HTTPS enforced on Azure Static Web Apps

## Real-time Features

- Notes automatically sync across all connected clients
- Admin dashboard shows live updates as users create/edit notes
- Uses Supabase real-time subscriptions

## Deployment Flow

1. Push code to main branch
2. Azure DevOps pipeline triggers
3. Build and test application
4. Fetch secrets from Key Vault
5. Deploy to Azure Static Web Apps
6. Log deployment to Azure Storage

## Troubleshooting

### Build Errors

If you encounter build errors:
1. Ensure all environment variables are set correctly
2. Check that Supabase migrations have been run
3. Verify Node.js version matches requirement (20.x)

### Authentication Issues

1. Verify Supabase URL and keys are correct
2. Check that auth providers are enabled in Supabase
3. Ensure redirect URLs are configured correctly

### Admin Access Issues

1. Verify your user has `is_admin = true` in the profiles table
2. Check middleware is properly configured
3. Clear browser cache and cookies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - feel free to use this project for learning or production purposes.

## Support

For issues and questions:
- Check the documentation above
- Review Supabase documentation
- Review Azure Static Web Apps documentation
- Open an issue in the repository

## Next Steps

- Add note categories/tags
- Implement search functionality
- Add markdown support for notes
- Implement note sharing
- Add export functionality (PDF, Markdown)
- Implement note versioning
- Add collaborative editing
