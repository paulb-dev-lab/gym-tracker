# Lift Log

A small, mobile-first gym tracker for a private group. Anyone can make an account; routines are shared and copyable, while workout data remains private to the user who logged it.

## What is included

- Email/password accounts and display names
- Global exercise catalog: every member can add; only the admin can retire entries
- Correction-suggestion queue for the admin
- Shared muscle catalogue with primary/secondary exercise targets and member suggestions
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

If you had already run the initial migration before the default-set-count feature was added, also open and run [`supabase/migrations/002_default_set_count.sql`](supabase/migrations/002_default_set_count.sql) in a new SQL Editor query. New projects only need `001_initial.sql`.

The follow-up migration is required before starting a routine with pre-added blank sets. Without it, Supabase rejects draft sets whose reps are still `0`.

For an existing project, also run [`supabase/migrations/003_finish_workout_server_time.sql`](supabase/migrations/003_finish_workout_server_time.sql). It makes workout completion use the database clock so a device clock difference cannot prevent a workout from finishing.

For exercises where the displayed weight is assistance rather than resistance, run [`supabase/migrations/004_exercise_weight_direction.sql`](supabase/migrations/004_exercise_weight_direction.sql). Afterward, edit each relevant exercise in the admin catalog and set **Weight meaning** to **Assistance — lower is better**.

For routine archiving, run [`supabase/migrations/005_archive_routines.sql`](supabase/migrations/005_archive_routines.sql). Archived routines are private to their creator and remain available in a read-only archived-routines view.

For the muscle catalogue and exercise target mapping, run [`supabase/migrations/006_muscle_catalog.sql`](supabase/migrations/006_muscle_catalog.sql), followed by [`supabase/migrations/007_exercise_creator_targets.sql`](supabase/migrations/007_exercise_creator_targets.sql) and [`supabase/migrations/008_group_exercise_targets.sql`](supabase/migrations/008_group_exercise_targets.sql). The catalogue structure is admin-only, while the person who adds an exercise can select either a muscle group or a nested individual muscle as its target, then revise those targets later. Admins can also revise targets for every exercise.

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
