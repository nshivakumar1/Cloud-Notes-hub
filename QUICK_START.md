# Quick Start Guide

Get Cloud Notes Hub 2.0 running locally in 5 minutes.

## Prerequisites

- Node.js 20.x or later
- npm
- A Supabase account

## Steps

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the migration from `supabase/migrations/00001_initial_schema.sql`
3. Get your Project URL and API keys from Settings > API

### 3. Configure Environment

```bash
cp .env.local.example .env.local
```

Edit `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 4. Run the App

```bash
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000)

### 5. Create an Admin User

1. Sign up through the app
2. In Supabase Dashboard > Table Editor > profiles
3. Set `is_admin = true` for your user

## What's Included

- **User Dashboard** (`/dashboard`) - Create, edit, delete notes
- **Admin Dashboard** (`/admin`) - Manage all notes and users
- **Authentication** (`/login`) - Email/password, Google, GitHub OAuth
- **Real-time Sync** - Notes update automatically across clients

## File Structure

```
app/
├── page.tsx          # Redirects to /login
├── login/            # Auth page
├── dashboard/        # User notes
└── admin/            # Admin panel

components/
├── notes/            # Note components
└── admin/            # Admin components

lib/
└── supabase/         # Supabase clients

supabase/
└── migrations/       # Database schema

terraform/            # Azure infrastructure
azure-pipelines.yml   # CI/CD pipeline
```

## Common Tasks

### Add OAuth Providers

1. Go to Supabase > Authentication > Providers
2. Enable Google/GitHub
3. Follow the setup instructions
4. Update redirect URLs

### Make a User Admin

```sql
-- In Supabase SQL Editor
UPDATE profiles SET is_admin = true WHERE email = 'user@example.com';
```

### View Database

Supabase Dashboard > Table Editor

Tables:
- `profiles` - User information
- `notes` - All notes

### Deploy to Production

See `SETUP_GUIDE.md` for complete Azure deployment instructions.

## Key Features

### User Features
- Create/edit/delete notes
- Make notes public or private
- Real-time synchronization
- OAuth login

### Admin Features
- View all notes in real-time
- Edit/delete any note
- Filter and search notes
- Toggle note visibility
- View user information

### Security
- Row-Level Security (RLS) on all tables
- Protected admin routes
- Secure credential storage

## Troubleshooting

**App won't start?**
- Check Node.js version: `node --version` (should be 20.x+)
- Delete `node_modules` and run `npm install` again

**Can't sign in?**
- Verify `.env.local` has correct Supabase credentials
- Check Supabase project is active

**Database errors?**
- Ensure you ran the migration in Supabase SQL Editor
- Check tables exist in Table Editor

**Can't access admin?**
- Set `is_admin = true` in profiles table for your user
- Clear cookies and sign in again

## Next Steps

- Read the full [README.md](README.md) for detailed features
- See [SETUP_GUIDE.md](SETUP_GUIDE.md) for production deployment
- Check `supabase/migrations/` for database schema details

## Support

- Check documentation files
- Review [Supabase Docs](https://supabase.com/docs)
- Review [Next.js Docs](https://nextjs.org/docs)
- Open an issue in the repository
