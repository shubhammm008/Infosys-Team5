# Testing Guide - LTMS App

## ⚠️ Firebase Configuration Issue

Your app currently has placeholder Firebase credentials in `GoogleService-Info.plist`. This means real Firebase authentication won't work until you configure it properly.

## ✅ Testing Solution

I've added a **testing mode** that allows you to test the app without Firebase. Here's how:

### Creating Test Accounts

When signing up, use an email that ends with **@test.com** or **@ltms.test**

**Examples:**
- Learner: `john@test.com`
- Educator: `teacher@test.com` or `educator@test.com`
- Admin: `admin@test.com`

**Password:** Any password (minimum 6 characters)

### Logging In with Test Accounts

Use the same test email addresses to log in. The system will automatically:
- Create a mock user
- Detect the role based on the email (admin/educator/learner)
- Grant access to the appropriate dashboard

### How It Works

The app now includes smart detection:
1. If your email ends with `@test.com` or `@ltms.test`, it bypasses Firebase
2. It creates a local mock user for testing
3. All features work normally without needing Firebase

## 🔧 To Fix Firebase (For Production)

When you're ready to use real Firebase:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add an iOS app
4. Download the real `GoogleService-Info.plist`
5. Replace the placeholder file at `/LTMS/GoogleService-Info.plist`
6. Enable Authentication and Firestore in Firebase Console

## 📝 Test Account Examples

### Learner Account
- Email: `student@test.com`
- Password: `test123`

### Educator Account  
- Email: `teacher@test.com`
- Password: `test123`

### Admin Account
- Email: `admin@test.com`
- Password: `test123`

## ✨ What's New

- ✅ Testing mode with @test.com emails
- ✅ Automatic role detection from email
- ✅ No Firebase needed for testing
- ✅ Helpful info banner in signup screen
- ✅ Better error messages
- ✅ Debug logging in console

## 🐛 Debugging

If you see errors in Xcode console, look for:
- 🔵 Blue circles = Success messages
- 🔴 Red circles = Error messages

This will help identify any issues!
