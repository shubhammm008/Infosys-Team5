# Educator Login Debug Guide

## 🔍 Debug Steps

I've added logging to help diagnose why educators are seeing the learner dashboard.

### How to Test:

**Step 1: Create Educator (Admin)**
```
1. Login as: Admin@ltms.test / test1234
2. Dashboard → "Create Educator Account"
3. Fill in:
   - Name: Test Educator
   - Email: testedu@test.com
   - Password: test123
4. Click "Create Educator Account"
5. Check Xcode console for:
   📝 Adding user to MockDataService:
      Email: testedu@test.com
      Role: Educator  ← Should say "Educator"
      Name: Test Educator
   ✅ User added. Total users: X
```

**Step 2: Verify in User List**
```
1. Go to "Users" tab
2. Find "Test Educator"
3. Badge should show: [Educator]
4. If it shows [Learner], there's a problem in CreateUserView
```

**Step 3: Login as Educator**
```
1. Logout from admin
2. Login as: testedu@test.com / test123
3. Check Xcode console for:
   🔍 Login Debug:
      Email: testedu@test.com
      User found: Test Educator
      Role in storage: educator  ← Should say "educator"
      Role display: Educator
   ✅ Set currentUser with role: Educator
4. Check which dashboard opens:
   ✅ Should be: Educator Dashboard
   ❌ If Learner Dashboard: Role is wrong
```

## 🐛 Possible Issues:

### Issue 1: Role Not Saved Correctly
**Symptom:** User list shows [Learner] instead of [Educator]
**Cause:** CreateUserView creating user with wrong role
**Check:** CreateUserView.swift line where User is created

### Issue 2: Role Not Loaded Correctly
**Symptom:** Console shows "Role: Learner" when loading
**Cause:** UserDefaults not saving/loading role correctly
**Check:** MockDataService saveData/loadData

### Issue 3: Wrong Dashboard Routing
**Symptom:** Console shows "Role: Educator" but Learner Dashboard opens
**Cause:** LTMSApp.swift routing issue
**Check:** LTMSApp.swift switch statement

## 📋 What to Share:

Please share the console output when you:
1. Create the educator
2. Login as the educator

Look for these lines:
```
📝 Adding user to MockDataService:
   Role: ???  ← What does this say?

🔍 Login Debug:
   Role in storage: ???  ← What does this say?
   Role display: ???  ← What does this say?
```

This will tell us exactly where the problem is!
