# Supabase Migrations

This directory contains SQL migration files to set up the Alpha ERP database in Supabase.

## Running Migrations

### Option 1: Via Supabase Dashboard (Recommended for first-time setup)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **+ New Query**
4. Run each migration in order:

   **Step 1:** Copy and paste contents of `001_create_core_tables.sql`
   - Click **Run** to create all tables, enums, and indexes

   **Step 2:** Copy and paste contents of `002_create_triggers.sql`
   - Click **Run** to create triggers for business logic

   **Step 3:** Copy and paste contents of `003_enable_rls.sql`
   - Click **Run** to enable Row Level Security policies

   **Step 4:** Copy and paste contents of `004_create_functions.sql`
   - Click **Run** to create database functions for metrics

### Option 2: Via Supabase CLI

```bash
# Install Supabase CLI if you haven't
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

## Verification

After running all migrations, verify in the Supabase dashboard:

1. **Tables** → Should see 10 tables:
   - organizations
   - users
   - clients
   - projects
   - tasks
   - time_entries
   - expenses
   - expense_line_items
   - invoices
   - invoice_line_items

2. **Authentication** → **Policies** → Verify RLS is enabled on all tables

3. **SQL Editor** → Test functions:
   ```sql
   -- Should return sample metrics (will be empty initially)
   SELECT get_dashboard_metrics('your-user-uuid');
   ```

## Next Steps

After running migrations:

1. **Configure Authentication:**
   - Go to **Authentication** → **Providers**
   - Enable **Email** provider
   - Configure email templates (optional for development)

2. **Create First User:**
   - Go to **Authentication** → **Users**
   - Click **Add user** → **Create new user**
   - Enter email and password
   - Note the user UUID for testing

3. **Create First Organization:**
   ```sql
   -- Run in SQL Editor
   INSERT INTO organizations (name, email)
   VALUES ('My Company', 'company@example.com')
   RETURNING id;
   ```

4. **Link User to Organization:**
   ```sql
   -- Replace with actual UUIDs from steps 2 & 3
   INSERT INTO users (id, organization_id, email, name, role)
   VALUES (
     'auth-user-uuid',
     'organization-uuid',
     'user@example.com',
     'John Doe',
     'OWNER'
   );
   ```

## Migration Files

- `001_create_core_tables.sql` - Core database schema
- `002_create_triggers.sql` - Automated business logic
- `003_enable_rls.sql` - Row Level Security policies
- `004_create_functions.sql` - Dashboard metrics functions

## Rollback

If you need to rollback, run in SQL Editor:

```sql
-- WARNING: This will delete all data
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Then re-run migrations from step 1.
