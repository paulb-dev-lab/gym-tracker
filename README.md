# Lift Log

A small, mobile-first gym tracker for a private group. Anyone can make an account; routines are shared and copyable, while workout data remains private to the user who logged it.

## What is included

- Email/password accounts and display names
- Global exercise catalog: every member can add; only the admin can retire entries
- Correction-suggestion queue for the admin
- Private live workout logging: exercise setup, set type, weight, reps, and notes
- Shared routines, with one-click copy-to-my-routines and start-workout flows
- Private workout history and simple top-weight/volume progression view
- Installable web-app manifest and phone-first layout

## Run locally

1. Create a free Supabase project.
2. Run the database migration in the Supabase dashboard (detailed below).
3. Create your own account in the running app, then make that account the admin (detailed below).
4. Copy `.env.example` to `.env.local` and set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` from Supabase Project Settings → API.
5. Run:

```powershell
npm install
npm run dev
```

Open `http://localhost:3000`.

### Run the migration in Supabase

1. Open your project in the [Supabase Dashboard](https://supabase.com/dashboard/projects).
2. In the left navigation, choose **SQL Editor**.
3. Click **New query**.
4. Open [`supabase/migrations/001_initial.sql`](supabase/migrations/001_initial.sql) in this project, copy its complete contents, and paste it into the editor.
5. Click **Run** (or press `Ctrl` + `Enter`). Supabase should show a success message.

The migration creates the tables, automatic profile creation, security policies, and access rules the app needs. It is safe to run once on a new Supabase project. Do not run it a second time on the same database: PostgreSQL will correctly report that objects such as tables already exist.

To verify the migration, open **Table Editor** in the left navigation. You should see tables including `profiles`, `exercises`, `routines`, `workout_sessions`, `session_exercises`, and `sets`.

### Make your account the admin

The `profiles` row is created automatically when a user signs up. Because the app needs Supabase configured before sign-up works, first complete the `.env.local` step above and run `npm run dev`. Then:

1. Open `http://localhost:3000`, create your account, and confirm your email if Supabase asks you to.
2. In Supabase Dashboard, choose **Authentication** → **Users**.
3. Find your email address and copy the value in the **User UID** column.
4. Return to **SQL Editor** → **New query**, replace `YOUR-USER-UUID` below with that UID, and run it:

```sql
update public.profiles
set role = 'admin'
where id = 'YOUR-USER-UUID';
```

5. Sign out and sign back in to refresh the app. You will now see admin controls in the Exercise catalog: edit/retire exercises and review correction suggestions.

### Set the required environment variables

In Supabase, open **Project Settings** → **API** and copy:

- **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
- **Publishable key** (or legacy **anon public** key) → `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Create `.env.local` next to `package.json` with those values:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-publishable-or-anon-key
```

Do not use the `service_role` key here. It bypasses the database security rules and must never be exposed in a browser application.

## Deploy free on Vercel

1. Put this repository in a private GitHub repository.
2. Import it in Vercel as a Next.js project.
3. Add the same two environment variables in Vercel’s Project Settings → Environment Variables.
4. Deploy. In Supabase Authentication → URL Configuration, set the Site URL to the Vercel URL and add it as a redirect URL.

Keep email confirmation enabled for a simple protection against mistyped addresses. Supabase’s free project can pause after a week without use, so opening the app periodically will wake it back up.

## Important security rule

Never put a Supabase `service_role` key in this project or Vercel’s browser-facing variables. The app relies on the public anon key plus the Row-Level Security policies in the migration.
