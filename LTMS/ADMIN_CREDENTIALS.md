# System Admin Credentials

## 🔐 Fixed Admin Account

There is **ONE** system admin account with fixed credentials:

```
Email: Admin@ltms.test
Password: test1234
```

### Important Notes:

- ✅ This is the **ONLY** admin account
- ✅ Credentials are **FIXED** and cannot be changed
- ✅ Use this account to manage all users
- ✅ Case-sensitive email: `Admin@ltms.test` (capital A)

## 👥 User Roles

### System Admin (1 account)
- **Email**: `Admin@ltms.test`
- **Password**: `test1234`
- **Capabilities**:
  - Create educators
  - Change user roles
  - Activate/Deactivate users
  - Delete users
  - View all users
  - Manage courses

### Educators (Created by Admin)
- Created by admin using "Create Educator Account"
- Can create and manage courses
- Can view enrolled learners
- Cannot create other educators

### Learners (Self-Signup)
- Anyone can sign up as a learner
- Can browse and enroll in courses
- Can view their progress
- Cannot create courses

## 🎯 Quick Start

### Step 1: Login as Admin
```
1. Open app
2. Enter:
   Email: Admin@ltms.test
   Password: test1234
3. Click "Sign In"
4. ✅ Access Admin Dashboard
```

### Step 2: Create an Educator
```
1. Dashboard → "Create Educator Account"
2. Fill in educator details
3. Set password for educator
4. Click "Create Educator Account"
5. ✅ Share credentials with educator
```

### Step 3: Promote Learner to Educator
```
1. Go to "Users" tab
2. Find learner
3. Tap ••• → "Change Role" → "Educator"
4. ✅ User is now an educator
```

## 📋 Common Tasks

### Create New Educator
```
Admin Dashboard → Create Educator Account
- Name: John Smith
- Email: john@test.com
- Password: secure123
→ Share credentials with John
```

### Change User Role
```
Users Tab → Find User → ••• Menu
→ Change Role → Select New Role
→ ✅ Role updated
```

### Deactivate User
```
Users Tab → Find User → ••• Menu
→ Deactivate
→ ✅ User cannot login
```

### Reactivate User
```
Users Tab → Find User → ••• Menu
→ Activate
→ ✅ User can login again
```

## ⚠️ Important

- **DO NOT** share admin credentials with regular users
- **DO NOT** try to change admin email or password (it's fixed)
- **DO** create separate educator accounts for staff
- **DO** use learner accounts for students

## 🔒 Security

The admin account is:
- Fixed in the system
- Cannot be deleted
- Cannot be deactivated
- Cannot have role changed
- Always accessible with the same credentials

This ensures there's always a way to access the admin panel!
