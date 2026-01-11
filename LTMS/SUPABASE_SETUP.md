# 🔗 Supabase Integration Guide for LTMS

This guide will walk you through setting up a new Supabase project and integrating it with your LTMS iOS app.

## 📋 Prerequisites

- A Supabase account (sign up at [supabase.com](https://supabase.com))
- Xcode installed
- Swift Package Manager (comes with Xcode)

---

## Step 1: Create New Supabase Project

1. Go to [app.supabase.com](https://app.supabase.com)
2. Click **"New Project"**
3. Fill in the details:
   - **Name**: `LTMS` (or your preferred name)
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is fine for development
4. Click **"Create new project"**
5. Wait 2-3 minutes for the project to be provisioned

---

## Step 2: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Copy and paste the SQL from `supabase_schema.sql` (see file in this directory)
4. Click **"Run"** to execute the schema
5. You should see success messages for all tables created

---

## Step 3: Enable Authentication

### Enable Email/Password Auth
1. Go to **Authentication** → **Providers** in your Supabase dashboard
2. Make sure **Email** is enabled (it should be by default)
3. Configure email settings:
   - **Enable email confirmations**: OFF (for development, turn ON for production)
   - **Enable email change confirmations**: ON
   - **Secure email change**: ON

### Enable 2FA (Optional but Recommended)
1. Go to **Authentication** → **Policies**
2. 2FA is available at the user level - users can enable it from their account settings
3. For admin enforcement, you can set up custom policies

---

## Step 4: Set Up Row Level Security (RLS)

1. In your Supabase dashboard, go to **SQL Editor**
2. Copy and paste the SQL from `supabase_rls_policies.sql`
3. Click **"Run"** to create all security policies
4. This ensures users can only access data they're authorized to see

---

## Step 5: Get Your Supabase Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. You'll need two values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon/Public Key**: `eyJhbGc...` (long string)
3. **IMPORTANT**: Keep these safe! We'll add them to the app next

---

## Step 6: Add Supabase SDK to Xcode Project

1. Open your Xcode project (`LTMS.xcodeproj`)
2. Select your project in the navigator
3. Select your app target
4. Go to **"Package Dependencies"** tab
5. Click the **"+"** button
6. Enter this URL: `https://github.com/supabase/supabase-swift`
7. Click **"Add Package"**
8. Select the following products:
   - ✅ **Supabase**
   - ✅ **Auth**
   - ✅ **PostgREST**
   - ✅ **Realtime** (optional, for real-time features)
   - ✅ **Storage** (optional, for file uploads)
9. Click **"Add Package"**

---

## Step 7: Configure Supabase in Your App

### Create Configuration File

1. In Xcode, right-click on the `LTMS` folder
2. Select **New File** → **Property List**
3. Name it `Supabase-Info.plist`
4. Add the following keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>YOUR_PROJECT_URL_HERE</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR_ANON_KEY_HERE</string>
</dict>
</plist>
```

5. Replace `YOUR_PROJECT_URL_HERE` and `YOUR_ANON_KEY_HERE` with your actual credentials from Step 5

---

## Step 8: Update App Code

The following files have been created/updated for you:

1. ✅ **`SupabaseService.swift`** - New service to handle Supabase operations
2. ✅ **`SupabaseAuthService.swift`** - Updated authentication service
3. ✅ **`SupabaseConfig.swift`** - Configuration helper

### What Changed:

- **Authentication**: Now uses Supabase Auth instead of Firebase Auth
- **Database**: Uses Supabase PostgreSQL instead of Firestore
- **Real-time**: Can use Supabase Realtime for live updates (optional)

---

## Step 9: Update App Entry Point

Update your `LTMSApp.swift` to initialize Supabase instead of Firebase.

The file has been updated for you - just review the changes.

---

## Step 10: Test the Integration

### Create a Test User

1. Go to your Supabase dashboard → **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**
3. Enter:
   - **Email**: `admin@test.com`
   - **Password**: `test123456`
4. Click **"Create user"**
5. The user will appear in the users table

### Test in the App

1. Run the app in Xcode
2. Try signing in with `admin@test.com` / `test123456`
3. You should be authenticated successfully!

---

## Step 11: Migrate Existing Data (Optional)

If you have existing data in Firebase that you want to migrate:

1. Export data from Firebase (Firestore → Export)
2. Transform the data to match Supabase schema
3. Use Supabase SQL Editor to insert data

**Note**: This is optional for a fresh start!

---

## 🔒 Security Best Practices

1. **Never commit** `Supabase-Info.plist` with real credentials to Git
2. Add it to `.gitignore`:
   ```
   Supabase-Info.plist
   ```
3. For production, use environment variables or secure storage
4. Enable RLS policies (already done in Step 4)
5. Enable email confirmations in production
6. Set up proper CORS policies if using web clients

---

## 🐛 Troubleshooting

### "Invalid API key" error
- Double-check your `SUPABASE_ANON_KEY` in `Supabase-Info.plist`
- Make sure there are no extra spaces or line breaks

### "Failed to connect" error
- Check your `SUPABASE_URL` is correct
- Ensure your internet connection is working
- Check Supabase dashboard status

### "Row Level Security" errors
- Make sure you ran the RLS policies SQL script
- Check that policies are enabled for your tables

### Authentication not working
- Verify email/password provider is enabled in Supabase dashboard
- Check that the user exists in Authentication → Users
- Look at Xcode console for detailed error messages

---

## 📚 Next Steps

1. ✅ Set up Supabase project
2. ✅ Run database schema
3. ✅ Configure RLS policies
4. ✅ Add Supabase SDK to Xcode
5. ✅ Update configuration
6. ✅ Test authentication
7. 🔄 Migrate existing features (courses, users, etc.)
8. 🚀 Deploy to production

---

## 🆘 Need Help?

- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Supabase Swift SDK**: [github.com/supabase/supabase-swift](https://github.com/supabase/supabase-swift)
- **Discord**: [discord.supabase.com](https://discord.supabase.com)

---

**Created**: January 10, 2026  
**For**: LTMS iOS App  
**Backend**: Supabase PostgreSQL + Auth
