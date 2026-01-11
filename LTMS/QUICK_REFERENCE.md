# 🚀 QUICK REFERENCE - Add Files to Xcode

## Files to Add (All exist and ready!)

### 1️⃣ Services Folder (3 files)
```
LTMS/LTMS/Services/
├── SupabaseConfig.swift ✅
├── SupabaseService.swift ✅
└── SupabaseAuthService.swift ✅
```

### 2️⃣ Models Folder (1 file)
```
LTMS/LTMS/Models/
└── User+Supabase.swift ✅
```

### 3️⃣ Main LTMS Folder (1 file)
```
LTMS/LTMS/
└── Supabase-Info.plist ✅ (with YOUR credentials!)
```

---

## How to Add (Super Simple!)

### Method 1: Drag & Drop (Easiest!)
1. Open Finder
2. Navigate to `/Users/akshatsingh/Desktop/INFOSYS/LMTS/LTMS/LTMS/Services/`
3. Drag the 3 Supabase*.swift files into Xcode's Services folder
4. When dialog appears, check ✅ "Add to targets: LTMS"
5. Click "Finish"

Repeat for Models and main LTMS folder!

### Method 2: Right-Click (More Control)
1. Right-click folder in Xcode
2. "Add Files to LTMS..."
3. Select files
4. Check ✅ "Add to targets: LTMS"
5. Click "Add"

---

## After Adding Files

```bash
# In Xcode:
Cmd+B  # Build (should succeed!)
Cmd+R  # Run the app

# Check console for:
✅ Supabase configured successfully
📍 URL: https://digypbytkohndsubnuhb.supabase.co
```

---

## Test User

Create in Supabase dashboard:
- Email: `admin@test.com`
- Password: `test123456`
- Auto Confirm: ✅ ON

Then login in the app!

---

**That's it! You're done! 🎉**
