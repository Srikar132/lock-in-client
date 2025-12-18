# Groups Feature Documentation

## Overview

The Groups feature allows users to connect with friends or unknown people, form study/productivity groups, set collective goals, track progress together, and compete on leaderboards. Groups can be public (discoverable by anyone) or private (invite-only).

## Features Implemented

### 1. **Data Models**
- **GroupModel** - Core group information including privacy settings, stats, and invite codes
- **GroupMemberModel** - Member information with roles (Admin, Moderator, Member), stats, and permissions
- **GroupGoalModel** - Shared or competitive goals with progress tracking

### 2. **Group Types**
- **Public Groups**: Discoverable by all users, anyone can join
- **Private Groups**: Only accessible via invite code
- **Approval Mode**: Optional setting to manually approve new members

### 3. **Group Features**

#### Group Creation & Management
- Create new groups with customizable settings
- Set group privacy (public/private)
- Add categories (Study, Productivity, Fitness, etc.)
- Configure member approval requirements
- Generate unique 8-character invite codes

#### Member Management
- Three role levels: Admin, Moderator, Member
- Member statistics tracking:
  - Goals completed
  - Study time
  - Current streak
  - Longest streak
- Admin controls for role assignment
- Member approval system for private groups

#### Goals & Progress Tracking
- **Goal Types**:
  - Daily goals
  - Weekly goals
  - Monthly goals
  - Custom duration goals

- **Goal Settings**:
  - Shared goals (everyone works together)
  - Competitive goals (members compete)
  - Time-based targets (study minutes)
  - Session-based targets (number of sessions)

- **Progress Tracking**:
  - Real-time progress updates
  - Completion percentage
  - Individual member contributions
  - Group-wide statistics

#### Dashboard & Leaderboards
- **Group Dashboard**:
  - Active goals summary
  - Progress visualization
  - Top contributors leaderboard
  - Group statistics (members, goals, study time)

- **Leaderboard Features**:
  - Ranked by study time and goals completed
  - Gold/Silver/Bronze highlighting for top 3
  - Individual member stats display
  - Real-time updates

#### Social Features
- **Invite System**:
  - Share group via invite code
  - Direct sharing via share_plus package
  - Copy invite code to clipboard

- **Discovery**:
  - Browse public groups
  - Search by name or category
  - Filter groups by category tags

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   ├── group_model.dart
│   │   ├── group_member_model.dart
│   │   └── group_goal_model.dart
│   └── repositories/
│       └── group_repository.dart
├── presentation/
│   └── screens/
│       ├── group_screen.dart (main entry point)
│       └── group/
│           ├── groups_list_screen.dart
│           ├── group_detail_screen.dart
│           └── create_join_group_screen.dart
```

## Database Structure (Firestore)

### Collections

#### `groups` (Top-level collection)
```
groups/{groupId}
  - id: string
  - name: string
  - description: string
  - photoURL: string?
  - creatorId: string
  - createdAt: timestamp
  - updatedAt: timestamp
  - privacy: "public" | "private"
  - requiresApproval: boolean
  - maxMembers: number
  - memberCount: number
  - totalGoalsCompleted: number
  - totalStudyTime: number (minutes)
  - inviteCode: string (8 chars)
  - categories: string[]
```

#### `groups/{groupId}/members` (Subcollection)
```
members/{userId}
  - userId: string
  - groupId: string
  - displayName: string
  - photoURL: string?
  - email: string
  - role: "admin" | "moderator" | "member"
  - status: "active" | "pending" | "banned"
  - joinedAt: timestamp
  - approvedAt: timestamp?
  - goalsCompleted: number
  - studyTime: number (minutes)
  - currentStreak: number
  - longestStreak: number
  - lastActiveDate: timestamp?
  - canInvite: boolean
  - canPostGoals: boolean
```

#### `groups/{groupId}/goals` (Subcollection)
```
goals/{goalId}
  - id: string
  - groupId: string
  - title: string
  - description: string
  - createdBy: string (userId)
  - createdByName: string
  - type: "daily" | "weekly" | "monthly" | "custom"
  - status: "pending" | "inProgress" | "completed" | "failed"
  - createdAt: timestamp
  - startDate: timestamp
  - endDate: timestamp
  - targetMinutes: number
  - targetSessions: number
  - completedMinutes: number
  - completedSessions: number
  - completedByUserIds: string[]
  - isShared: boolean
  - isCompetitive: boolean
```

## API Methods (GroupRepository)

### Group Management
- `createGroup()` - Create a new group
- `getGroup(groupId)` - Get group details
- `updateGroup(groupId, updates)` - Update group information
- `deleteGroup(groupId)` - Delete group and all subcollections
- `getPublicGroups()` - Stream of public groups
- `searchGroups(query)` - Search groups by name/category
- `getUserGroups(userId)` - Stream of user's groups

### Member Management
- `joinGroup()` - Join a group
- `joinGroupByInviteCode()` - Join using invite code
- `leaveGroup()` - Leave a group
- `getGroupMembers()` - Stream of group members
- `updateMemberRole()` - Change member role
- `approveMember()` - Approve pending member
- `getMemberInfo()` - Get specific member info
- `updateMemberStats()` - Update member statistics

### Goal Management
- `createGroupGoal()` - Create a new group goal
- `getGroupGoals()` - Stream of group goals
- `updateGoalProgress()` - Update goal progress

## Usage Examples

### Creating a Group
```dart
final groupId = await ref.read(groupRepositoryProvider).createGroup(
  name: 'Study Squad',
  description: 'Daily study group for computer science',
  creatorId: currentUserId,
  privacy: GroupPrivacy.public,
  requiresApproval: false,
  categories: ['Study', 'Programming'],
);
```

### Joining by Invite Code
```dart
final groupId = await ref.read(groupRepositoryProvider).joinGroupByInviteCode(
  inviteCode: 'ABC12345',
  userId: currentUserId,
  displayName: 'John Doe',
  email: 'john@example.com',
);
```

### Creating a Goal
```dart
final goalId = await ref.read(groupRepositoryProvider).createGroupGoal(
  groupId: groupId,
  title: 'Daily Study Challenge',
  description: 'Study for at least 2 hours today',
  createdBy: userId,
  createdByName: 'John Doe',
  type: GoalType.daily,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 1)),
  targetMinutes: 120,
  isShared: true,
);
```

### Updating Progress
```dart
await ref.read(groupRepositoryProvider).updateGoalProgress(
  groupId: groupId,
  goalId: goalId,
  userId: userId,
  minutesToAdd: 30,
  sessionsToAdd: 1,
);
```

## UI Components

### GroupsListScreen
- Tabbed interface (My Groups / Discover)
- Search functionality
- Group cards with stats
- Navigate to group details or create/join

### GroupDetailScreen
- Group header with stats
- 3 tabs: Dashboard, Members, Goals
- Real-time updates via StreamProviders
- Share and settings options
- Floating action button to create goals

### CreateJoinGroupScreen
- Tabbed interface (Create / Join)
- Form validation
- Category selection chips
- Privacy and approval settings
- Invite code input

## Riverpod Providers

```dart
// Repository
final groupRepositoryProvider = Provider((ref) => GroupRepository());

// Streams
final userGroupsProvider = StreamProvider.autoDispose<List<GroupModel>>(...)
final publicGroupsProvider = StreamProvider.autoDispose<List<GroupModel>>(...)
final groupProvider = StreamProvider.family<GroupModel?, String>(...)
final groupMembersProvider = StreamProvider.family<List<GroupMemberModel>, String>(...)
final groupGoalsProvider = StreamProvider.family<List<GroupGoalModel>, String>(...)
```

## Future Enhancements

### Planned Features
1. **Group Chat** - Real-time messaging within groups
2. **Activity Feed** - Timeline of group activities
3. **Achievements** - Group-wide and individual achievements
4. **Study Sessions** - Synchronized group study sessions
5. **Notifications** - Push notifications for goals and activities
6. **Group Photos** - Upload and manage group profile pictures
7. **Member Search** - Find and invite specific users
8. **Advanced Stats** - Detailed analytics and insights
9. **Goal Templates** - Preset goal templates
10. **Export Data** - Export group statistics and reports

### Potential Integrations
- Calendar integration for scheduled study sessions
- Video call integration for virtual study rooms
- Focus mode synchronization across group members
- Rewards/points system for gamification

## Security Considerations

### Current Implementation
- Users must be authenticated (Firebase Auth)
- Group creators are automatically admins
- Admins can manage members and settings
- Private groups only accessible via invite code

### Recommended Additions
- Firestore Security Rules to:
  - Restrict group creation rate
  - Prevent unauthorized member role changes
  - Validate invite code access
  - Limit goal creation based on permissions
  - Prevent stat manipulation

### Example Security Rules
```javascript
// Firestore Security Rules (to be added)
match /groups/{groupId} {
  allow read: if request.auth != null && 
    (resource.data.privacy == 'public' || 
     exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)));
  
  allow create: if request.auth != null;
  
  allow update: if request.auth != null && 
    exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role == 'admin';
  
  allow delete: if request.auth != null &&
    resource.data.creatorId == request.auth.uid;
  
  match /members/{userId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null;
    allow update, delete: if request.auth != null &&
      (get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role in ['admin', 'moderator']);
  }
  
  match /goals/{goalId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null &&
      get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.canPostGoals == true;
    allow update, delete: if request.auth != null &&
      (resource.data.createdBy == request.auth.uid ||
       get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role == 'admin');
  }
}
```

## Testing Checklist

- [ ] Create public group
- [ ] Create private group
- [ ] Join public group
- [ ] Join group via invite code
- [ ] Create daily goal
- [ ] Create weekly goal
- [ ] Update goal progress
- [ ] View leaderboard
- [ ] Search for groups
- [ ] Share invite code
- [ ] Leave group
- [ ] Admin: Change member role
- [ ] Admin: Approve pending member
- [ ] Admin: Delete group

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^3.0.3
  cloud_firestore: ^6.1.1
  firebase_auth: ^6.1.3
  share_plus: ^10.1.3
```

## Notes

- All timestamps are stored as Firestore Timestamps
- Invite codes are 8 characters (uppercase alphanumeric)
- Study time is tracked in minutes
- Member stats update via Firebase FieldValue.increment
- Real-time updates via Firestore streams and StreamProviders
- UI follows app theme (dark mode with green accent)

## Support & Troubleshooting

### Common Issues

1. **Groups not loading**: Check internet connection and Firebase configuration
2. **Can't join group**: Verify invite code is correct (8 characters)
3. **Stats not updating**: Ensure proper repository method calls after focus sessions
4. **Search not working**: Search is case-insensitive and matches name/categories

### Debug Tips
- Enable Firestore debug logging
- Check console for repository error messages
- Verify user authentication status
- Inspect Firestore console for data structure

---

**Last Updated**: December 2025  
**Version**: 1.0.0  
**Status**: Beta - Core features implemented, enhancements planned
