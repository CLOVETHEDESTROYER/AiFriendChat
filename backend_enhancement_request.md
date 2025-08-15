# Backend Enhancement Request: User Profile Management

## 🐛 Issue Found
**Problem**: iOS app is trying to call `/update-user-name` endpoint which returns 404 "Not Found"
**Error**: `{"detail":"Not Found"}` when attempting to update username

## 📱 Current Frontend Implementation Status
- ✅ **FIXED**: Frontend now handles username updates locally as a temporary solution
- ✅ Username is stored in UserDefaults and persists across app launches
- ✅ User experience is maintained with proper loading states
- ✅ No more crashes or 404 errors

## 🎯 Backend Enhancement Needed

### **New Endpoint Required: User Profile Management**

#### **POST /mobile/user/profile**
**Purpose**: Update user profile information (starting with display name)

**Headers Required**:
- `Authorization: Bearer <token>`
- `X-App-Type: mobile`
- `Content-Type: application/json`

**Request Body**:
```json
{
  "display_name": "John Smith",
  "preferences": {
    "voice_preference": "alloy",
    "default_scenario": "default"
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user_profile": {
    "display_name": "John Smith",
    "email": "user@example.com",
    "preferences": {
      "voice_preference": "alloy",
      "default_scenario": "default"
    },
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### **GET /mobile/user/profile**
**Purpose**: Retrieve user profile information

**Headers Required**:
- `Authorization: Bearer <token>`
- `X-App-Type: mobile`

**Response**:
```json
{
  "user_profile": {
    "display_name": "John Smith",
    "email": "user@example.com",
    "created_at": "2024-01-01T10:00:00Z",
    "preferences": {
      "voice_preference": "alloy",
      "default_scenario": "default"
    }
  }
}
```

### **Database Schema Enhancement**

Add to existing `mobile_users` table or create new `user_profiles` table:

```sql
-- Option 1: Add to existing mobile_users table
ALTER TABLE mobile_users ADD COLUMN display_name VARCHAR(100);
ALTER TABLE mobile_users ADD COLUMN voice_preference VARCHAR(20);
ALTER TABLE mobile_users ADD COLUMN default_scenario VARCHAR(50);
ALTER TABLE mobile_users ADD COLUMN profile_updated_at TIMESTAMP;

-- Option 2: Create separate user_profiles table
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES mobile_users(id),
    display_name VARCHAR(100),
    voice_preference VARCHAR(20) DEFAULT 'alloy',
    default_scenario VARCHAR(50) DEFAULT 'default',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🚀 Implementation Priority

### **Phase 1: Basic Profile Management (High Priority)**
1. Add `display_name` field to user management
2. Implement `/mobile/user/profile` GET/POST endpoints
3. Basic validation and error handling

### **Phase 2: Enhanced Preferences (Medium Priority)**
1. Voice preference storage
2. Default scenario preference
3. Enhanced user experience settings

### **Phase 3: Advanced Features (Low Priority)**
1. Profile pictures/avatars
2. Call history preferences
3. Notification settings

## 📱 Frontend Migration Plan

### **Current Status (Working)**
- Username updates work locally using UserDefaults
- No app crashes or errors
- User experience is maintained

### **When Backend is Ready**
- Frontend will detect if backend supports profile endpoints
- Gradually migrate from local storage to backend storage
- Maintain backward compatibility during transition

### **Code Changes Needed (Frontend)**
```swift
// Enhanced BackendService method
func updateUserProfile(displayName: String) async throws -> UserProfile {
    // Try new endpoint first
    do {
        return try await updateUserProfileOnBackend(displayName: displayName)
    } catch {
        // Fallback to local storage
        UserDefaults.standard.set(displayName, forKey: "userName")
        return UserProfile(displayName: displayName, isLocal: true)
    }
}
```

## ✅ Immediate Action Items for Backend Team

1. **High Priority**: Add basic profile endpoints to prevent 404 errors
2. **Medium Priority**: Implement user preferences storage
3. **Low Priority**: Add advanced profile features

## 📊 Benefits of This Enhancement

- **Better User Experience**: Persistent user profiles across devices
- **Feature Expansion**: Foundation for user customization
- **Data Analytics**: Better user behavior insights
- **App Store Readiness**: More complete user management system

---

**Note**: The iOS app is currently working perfectly with the local storage solution. This enhancement will improve the overall system architecture and prepare for future features, but it's not blocking the app from functioning or being submitted to the App Store.
