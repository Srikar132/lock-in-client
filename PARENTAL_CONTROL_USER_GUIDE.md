# Parental Control - User Guide

## How to Use Parental Control

### Setting Up for the First Time

1. **Navigate to Profile**
   - Tap the Profile tab in the bottom navigation bar

2. **Enable Parental Mode**
   - Find the "Parental Control" section
   - Toggle "Parental Mode" switch to ON
   - A dialog will appear: "New Password"

3. **Create Your Password**
   - Enter a password (minimum 4 characters)
   - Re-enter the same password to confirm
   - Tap "Setup"
   - Your parental mode is now active! 🎉

### Disabling Parental Mode

1. **Toggle Off**
   - Go to Profile → Parental Control
   - Toggle "Parental Mode" switch to OFF

2. **Verify Your Identity**
   - Enter your parental control password
   - Tap "Verify"
   - Parental mode will be disabled

### Changing Your Password

1. **Open Change Password**
   - Go to Profile → Parental Control
   - Tap "Change Password"

2. **Verify Current Password**
   - Enter your current password
   - Tap "Verify"

3. **Create New Password**
   - Enter your new password
   - Confirm the new password
   - Tap "Setup"
   - Password updated! ✅

### Managing Blocked Apps

1. **Access the Feature**
   - Go to Profile → Parental Control
   - Tap "Manage Blocked Apps"

2. **Note**: This feature is coming soon!
   - The infrastructure is ready
   - App selection UI will be added in future updates

## Tips & Best Practices

### Password Security
- ✅ Choose a password that's easy to remember but hard for others to guess
- ✅ Don't share your password with anyone
- ✅ Use at least 4 characters for better security
- ❌ Don't use obvious passwords like "1234" or "password"

### When to Use Parental Mode
- 📚 During study sessions to prevent distractions
- 🎯 When you want to limit social media access
- 👨‍👩‍👧‍👦 For parents managing their children's device usage
- 🧘 During mindfulness or focus time

### Troubleshooting

**Forgot Your Password?**
- Currently, password reset requires Firebase console access
- Contact support or check the database directly
- Future updates will include password recovery

**Can't Toggle Parental Mode?**
- Make sure you have an internet connection
- Firebase must be reachable
- Check that you're logged in

**Password Not Working?**
- Ensure you're entering the correct password
- Password is case-sensitive
- Try typing it again carefully

## Technical Notes

### Data Storage
- All settings are stored in Firebase Firestore
- Passwords are hashed using SHA-256
- Settings sync across devices (if same account)

### Privacy & Security
- Passwords are never stored in plain text
- Only the hash is saved to the database
- No one can see your actual password

### Firebase Security Rules (Recommended)

Add these rules to your Firestore:

```javascript
match /parental_controls/{userId} {
  // Only the user can read/write their own parental controls
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Feature Roadmap

### Current (v0.1.0)
- ✅ Password protection
- ✅ Enable/disable parental mode
- ✅ Change password
- ✅ Firebase integration

### Coming Soon
- 🔜 Block specific apps
- 🔜 Block YouTube Shorts
- 🔜 Block Instagram Reels
- 🔜 Website blocking
- 🔜 Educational app allowlist
- 🔜 Time-based restrictions
- 🔜 Password recovery via email

## Support

For issues or questions:
- Check [PARENTAL_CONTROL_IMPLEMENTATION.md](PARENTAL_CONTROL_IMPLEMENTATION.md) for technical details
- Review Firebase console for data verification
- Ensure all dependencies are installed (`flutter pub get`)

---

**Remember**: Parental control is a tool to help with focus and productivity. Use it wisely! 🎯
