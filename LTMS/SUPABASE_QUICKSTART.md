# 🚀 Quick Start: Linking Supabase to LTMS

Follow these steps to get your new Supabase project connected to the LTMS iOS app.

## ⏱️ Estimated Time: 15-20 minutes

---

## Step 1: Create Supabase Project (5 min)

1. Go to **[app.supabase.com](https://app.supabase.com)**
2. Click **"New Project"**
3. Fill in:
   - Name: `LTMS`
   - Database Password: *(save this somewhere safe!)*
   - Region: Choose closest to you
4. Click **"Create new project"**
5. ⏳ Wait 2-3 minutes for provisioning

---

## Step 2: Set Up Database (3 min)

1. In Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Open the file `supabase_schema.sql` from this project
4. Copy ALL the SQL and paste into the query editor
5. Click **"Run"** (or press Cmd+Enter)
6. ✅ You should see success messages

---

## Step 3: Set Up Security (2 min)

1. Still in **SQL Editor**, click **"New Query"**
2. Open the file `supabase_rls_policies.sql`
3. Copy ALL the SQL and paste into the query editor
4. Click **"Run"**
5. ✅ You should see "RLS Policies Created Successfully!"

---

## Step 4: Get Your Credentials (1 min)

1. In Supabase dashboard, go to **Settings** → **API**
2. Copy these two values:
   
   **Project URL:**
   ```
   https://xxxxxxxxxxxxx.supabase.co
   ```
   
   **Anon/Public Key:**
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS...
   ```

---

## Step 5: Add Supabase SDK to Xcode (3 min)

1. Open `LTMS.xcodeproj` in Xcode
2. Select the project in the navigator (top-left)
3. Select your app target (`LTMS`)
4. Go to **"Package Dependencies"** tab
5. Click the **"+"** button (bottom-left)
6. Paste this URL:
   ```
   https://github.com/supabase/supabase-swift
   ```
7. Click **"Add Package"**
8. Select these products:
   - ✅ Supabase
   - ✅ Auth
   - ✅ PostgREST
   - ✅ Realtime (optional)
   - ✅ Storage (optional)
9. Click **"Add Package"**

---

## Step 6: Configure Credentials in App (2 min)

### Option A: Using Xcode (Recommended)

1. In Xcode, right-click on the `LTMS` folder (yellow folder icon)
2. Select **"New File..."**
3. Choose **"Property List"**
4. Name it exactly: `Supabase-Info.plist`
5. Click **"Create"**
6. In the plist file, add these keys:
   - Right-click → **"Add Row"**
   - Key: `SUPABASE_URL`, Type: String, Value: *(paste your Project URL)*
   - Right-click → **"Add Row"**
   - Key: `SUPABASE_ANON_KEY`, Type: String, Value: *(paste your Anon Key)*
7. Save the file (Cmd+S)

### Option B: Copy Template

1. Copy `Supabase-Info.plist.template` to `LTMS/LTMS/Supabase-Info.plist`
2. Open it and replace the placeholder values
3. Add it to your Xcode project

---

## Step 7: Update .gitignore (1 min)

**IMPORTANT:** Don't commit your credentials!

1. Open `.gitignore` in the project root
2. Add this line:
   ```
   Supabase-Info.plist
   ```
3. Save the file

---

## Step 8: Test the Connection (3 min)

1. In Xcode, press **Cmd+R** to build and run
2. The app should compile successfully
3. Check the Xcode console for:
   ```
   ✅ Supabase configured successfully
   📍 URL: https://xxxxx.supabase.co
   ```

---

## Step 9: Create Test User (2 min)

### Option A: Via Supabase Dashboard

1. Go to **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**
3. Enter:
   - Email: `admin@test.com`
   - Password: `test123456`
   - Auto Confirm User: ✅ ON
4. Click **"Create user"**

### Option B: Via App Signup

1. Run the app
2. Click **"Sign Up"**
3. Fill in the form with your details
4. Select role: **Admin**
5. Click **"Create Account"**

---

## Step 10: Test Authentication (1 min)

1. In the app, try signing in with:
   - Email: `admin@test.com`
   - Password: `test123456`
2. ✅ You should be logged in successfully!
3. Check the Xcode console for:
   ```
   ✅ Signed in successfully: admin@test.com
   ✅ User data loaded: [Name] (Admin)
   ```

---

## ✅ You're Done!

Your LTMS app is now connected to Supabase! 🎉

### What's Working:
- ✅ User authentication (sign up, sign in, sign out)
- ✅ User profiles with roles (Admin, Educator, Learner)
- ✅ Row-level security (users can only see what they're allowed to)
- ✅ Database ready for courses, enrollments, and more

### Next Steps:
1. Create some courses in the admin dashboard
2. Add educators and learners
3. Test course enrollment
4. Explore the admin features

---

## 🐛 Troubleshooting

### "Supabase not configured" warning
- Make sure `Supabase-Info.plist` is in the correct location
- Verify the file is added to your Xcode target
- Check that the keys are spelled exactly: `SUPABASE_URL` and `SUPABASE_ANON_KEY`

### Build errors about missing modules
- Make sure you added the Supabase Swift package
- Try cleaning the build folder: **Product** → **Clean Build Folder**
- Restart Xcode

### "Invalid API key" error
- Double-check your `SUPABASE_ANON_KEY` in the plist
- Make sure there are no extra spaces or line breaks
- Copy the key again from Supabase dashboard

### Can't sign in
- Make sure you created the user in Supabase dashboard
- Check that "Auto Confirm User" was enabled
- Verify the email and password are correct
- Look at Xcode console for detailed error messages

---

## 📚 Additional Resources

- **Full Setup Guide**: See `SUPABASE_SETUP.md` for detailed information
- **Database Schema**: See `supabase_schema.sql` for all tables
- **Security Policies**: See `supabase_rls_policies.sql` for RLS setup
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Swift SDK Docs**: [github.com/supabase/supabase-swift](https://github.com/supabase/supabase-swift)

---

## 🆘 Need Help?

If you run into issues:
1. Check the Xcode console for error messages
2. Review the troubleshooting section above
3. Check Supabase dashboard logs: **Logs** → **Auth Logs**
4. Ask for help with the specific error message

---

**Happy coding! 🚀**
