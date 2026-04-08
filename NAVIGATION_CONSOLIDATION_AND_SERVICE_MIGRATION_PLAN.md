# Navigation Consolidation & Service Migration Plan

**Date:** April 7, 2026  
**Purpose:** Consolidate redundant navigation and complete backend service migration

---

## Part 1: Navigation Consolidation

### Current Navigation Analysis

**Redundant Entry Points Identified:**

| Feature | Entry Point 1 | Entry Point 2 | Entry Point 3 | Recommendation |
|---------|--------------|--------------|--------------|----------------|
| **Bible** | Bottom Nav "Bible" tab | Spiritual Tools "Bible Library" | Daily Verse tile | Keep bottom nav, keep Daily Verse (contextual), remove from Spiritual Tools |
| **Journal** | Bottom Nav "Journal" tab | Spiritual Tools "Journal" (new entry) | - | Keep bottom nav, remove from Spiritual Tools |
| **Meditation** | Bottom Nav "Meditation" tab | Spiritual Tools "Meditation" | - | Keep bottom nav, remove from Spiritual Tools |
| **Spiritual Aid** | Spiritual Tools "Soul Care" | Top-level route `/spiritual-aid` | - | Keep both (different contexts) |
| **Alignment** | Top-level route `/alignment` | - | - | Keep as-is (specialized hub) |
| **Faith Questions** | Top-level route `/faith-questions` | - | - | Keep as-is (specialized hub) |
| **Games** | Bottom Nav "Games" tab | Top-level game routes | - | Keep bottom nav, keep top-level for deep links |

### Proposed Navigation Structure

**Bottom Navigation (4 tabs + Center FAB):**
1. **Discover** → Assessment (spiritual discovery)
2. **Today** → Daily hub with anchors
3. **Act** → Mission hub (kingdom action)
4. **Together** → Community/accountability
5. **Center FAB** → Spiritual Tools Menu (quick actions only)

**Spiritual Tools Menu (Consolidated):**
- **Daily Verse** (contextual - shows today's verse, navigates to Bible reader)
- **Quick Prayer** (navigates to Spiritual Aid → Prayers)
- **Faith Discuss** (navigates to Spiritual Aid → Discuss)
- **Speak to Me** (navigates to Spiritual Aid → Speak)
- **Evangelism Helper** (navigates to Spiritual Aid → Evangelism)
- **Alignment Hub** (navigates to Alignment)
- **Faith Questions** (navigates to Faith Questions)

**Changes:**
- ✅ Remove "Bible Library" from Spiritual Tools (use bottom nav instead)
- ✅ Remove "Journal" from Spiritual Tools (use bottom nav instead)
- ✅ Remove "Meditation" from Spiritual Tools (use bottom nav instead)
- ✅ Keep "Soul Care" renamed to "Quick Help" (navigates to Spiritual Aid hub)
- ✅ Add quick access to Alignment and Faith Questions

### Files to Modify

1. **lib/shared/widgets/spiritual_tools_menu.dart**
   - Remove Bible Library tile
   - Remove Journal tile
   - Remove Meditation tile
   - Rename "Soul Care" to "Quick Help"
   - Add Alignment tile
   - Add Faith Questions tile

2. **lib/core/router/app_router.dart**
   - No changes needed (routes remain for deep linking)

3. **lib/core/constants/app_routes.dart**
   - No changes needed

---

## Part 2: Service Migration Completion

### Current State

**Backend Integration Status:**
- ✅ `ServiceOpportunityRepository` exists with API methods
- ✅ `getServiceOpportunities()` calls `/api/service-opportunities`
- ✅ `getMatchedOpportunities()` calls `/api/service-opportunities/generate-matches`
- ✅ `commitToOpportunity()` calls `/api/service-opportunities/{id}/commit`
- ❌ `MissionNotifier.generateServiceMatches()` still uses hardcoded local data (lines 769-861)

### Migration Tasks

**Task 1: Update MissionNotifier to use Backend API**
- Replace hardcoded `generateServiceMatches()` method
- Call `ServiceOpportunityRepository.getMatchedOpportunities()`
- Handle offline fallback gracefully
- Update error handling

**Task 2: Update ServiceMatchesWidget**
- Ensure it uses backend data
- Add loading states
- Add error handling with retry
- Show "no matches" state when appropriate

**Task 3: Update ServiceOpportunitiesScreen**
- Ensure it uses backend data
- Add category/location filters
- Add pull-to-refresh
- Add empty states

### Files to Modify

1. **lib/features/mission/application/mission_notifier.dart**
   - Replace `generateServiceMatches()` implementation
   - Add backend call with fallback

2. **lib/features/mission/presentation/widgets/service_matches_widget.dart**
   - Update to use backend data
   - Add loading/error states

3. **lib/features/mission/presentation/screens/service_opportunities_screen.dart**
   - Ensure proper backend integration
   - Add filters and refresh

---

## Implementation Steps

### Step 1: Update Spiritual Tools Menu

**File:** `lib/shared/widgets/spiritual_tools_menu.dart`

**Changes:**
- Remove Bible Library tile (lines 111-125)
- Remove Journal tile (lines 128-142)
- Remove Meditation tile (lines 148-162)
- Rename Soul Care to "Quick Help"
- Add Alignment tile
- Add Faith Questions tile

**New Menu Structure:**
1. Daily Verse (large tile - contextual)
2. Quick Help (Soul Care hub)
3. Quick Prayer
4. Faith Discuss
5. Speak to Me
6. Evangelism Helper
7. Alignment Hub
8. Faith Questions

### Step 2: Update MissionNotifier for Backend Service Matching

**File:** `lib/features/mission/application/mission_notifier.dart`

**Changes:**
- Import `ServiceOpportunityRepository`
- Inject repository via constructor
- Replace `generateServiceMatches()` (lines 769-861) with:
  ```dart
  Future<List<ServiceMatch>> generateServiceMatches() async {
    final profile = _settingsNotifier.state.callingProfile;
    if (profile == null) return [];

    try {
      // Try backend first
      final matches = await _serviceOpportunityRepository.getMatchedOpportunities();
      return matches;
    } catch (e) {
      // Fallback to local generation if offline
      _logger.w('Backend match failed, using local fallback: $e');
      return _generateLocalServiceMatches(profile);
    }
  }

  List<ServiceMatch> _generateLocalServiceMatches(CallingProfile profile) {
    // Move existing hardcoded logic here as fallback
    // ...
  }
  ```

### Step 3: Update ServiceMatchesWidget

**File:** `lib/features/mission/presentation/widgets/service_matches_widget.dart`

**Changes:**
- Watch `serviceOpportunityProvider` instead of local generation
- Add loading state
- Add error state with retry
- Add empty state

### Step 4: Update ServiceOpportunitiesScreen

**File:** `lib/features/mission/presentation/screens/service_opportunities_screen.dart`

**Changes:**
- Ensure it uses `serviceOpportunityProvider`
- Add category filter chips
- Add location type filter
- Add pull-to-refresh
- Add empty state illustration

### Step 5: Update Dependency Injection

**File:** `lib/core/di/app_providers.dart`

**Changes:**
- Inject `ServiceOpportunityRepository` into `MissionNotifier`
- Update `missionProvider` to pass repository

---

## Testing Checklist

### Navigation Consolidation
- [ ] Spiritual Tools Menu opens correctly
- [ ] Daily Verse tile navigates to Bible reader with correct verse
- [ ] Quick Help navigates to Spiritual Aid hub
- [ ] Quick Prayer navigates to Spiritual Aid → Prayers
- [ ] Faith Discuss navigates to Spiritual Aid → Discuss
- [ ] Speak to Me navigates to Spiritual Aid → Speak
- [ ] Evangelism Helper navigates to Spiritual Aid → Evangelism
- [ ] Alignment Hub navigates to Alignment hub
- [ ] Faith Questions navigates to Faith Questions hub
- [ ] Bible accessible from bottom nav only
- [ ] Journal accessible from bottom nav only
- [ ] Meditation accessible from bottom nav only

### Service Migration
- [ ] Service matches load from backend when online
- [ ] Service matches use local fallback when offline
- [ ] Service opportunities screen loads from backend
- [ ] Category filter works
- [ ] Location type filter works
- [ ] Pull-to-refresh works
- [ ] Commit to opportunity works
- [ ] Error states display correctly
- [ ] Loading states display correctly
- [ ] Empty states display correctly

---

## Rollback Plan

If issues arise:

**Navigation:**
- Revert `spiritual_tools_menu.dart` to previous version
- No router changes needed (routes remain)

**Service Migration:**
- Revert `mission_notifier.dart` to use local generation only
- Revert `service_matches_widget.dart` to local state
- Backend repository remains unchanged (can be used later)

---

## Estimated Time

- Navigation consolidation: 30 minutes
- Service migration: 1 hour
- Testing: 30 minutes
- **Total: 2 hours**

---

**Next Steps:**
1. Implement navigation consolidation
2. Implement service migration
3. Test all changes
4. Document any edge cases
