## Test Cases for End of Day Reflection Feature

### Test Case 1: Evening with Zero Activities
**Conditions:**
- Time: 8:00 PM (20:00)
- Activities completed: 0/3
- User taps daily progress widget

**Expected Result:**
- Shows EndOfDayReflectionDialog instead of ProgressReminderDialog
- Dialog title: "Gentle Reflection"
- Shows three reflection options with appropriate colors and icons

### Test Case 2: Afternoon with Zero Activities  
**Conditions:**
- Time: 3:00 PM (15:00)
- Activities completed: 0/3
- User taps daily progress widget

**Expected Result:**
- Shows regular ProgressReminderDialog
- No reflection dialog appears

### Test Case 3: Evening with Some Activities
**Conditions:**
- Time: 9:00 PM (21:00)
- Activities completed: 1/3 or 2/3
- User taps daily progress widget

**Expected Result:**
- Shows regular ProgressReminderDialog
- No reflection dialog appears

### Test Case 4: Reflection Flow - Busy Option
**Actions:**
1. Select "Busy - things came up"
2. Tap "Journal About Today"

**Expected Result:**
- Navigates to journal screen
- Pre-filled title: "A Busy Day"
- Pre-filled content with structured template

### Test Case 5: Reflection Flow - Emergency Option
**Actions:**
1. Select "Emergency"
2. Tap "Journal About Today"

**Expected Result:**
- Navigates to journal screen
- Pre-filled title: "An Emergency Day"
- Pre-filled content with emergency-specific template

### Test Case 6: Reflection Flow - Completed Some Option
**Actions:**
1. Select "I completed some, just didn't check in"
2. Tap "Mark What I Completed"
3. Check "Morning Virtue" and "Evening Energy"
4. Tap "Award Points (8 pts)"

**Expected Result:**
- Shows ActivitySelectionDialog
- Points calculation: 3 (virtue) + 5 (energy) = 8 points
- Success message: "Great work! 8 integrity points awarded!"
- Activities marked as completed in system

### Test Case 7: Cancel Flow
**Actions:**
1. Open reflection dialog
2. Tap "Maybe Later"

**Expected Result:**
- Dialog closes
- No activities marked as completed
- No navigation to journal

### Test Case 8: Late Night (1 AM)
**Conditions:**
- Time: 1:00 AM (01:00)
- Activities completed: 0/3
- User taps daily progress widget

**Expected Result:**
- Shows EndOfDayReflectionDialog (1 AM is within evening window)

### Manual Testing Steps

1. **Set up test environment:**
   ```bash
   flutter run
   ```

2. **Test time-based logic:**
   - Change device time to 8 PM to test evening behavior
   - Change device time to 3 PM to test afternoon behavior
   - Change device time to 1 AM to test late night behavior

3. **Test activity completion states:**
   - Ensure all activities show 0/3 completed
   - Complete 1 activity and verify regular dialog appears
   - Complete 2 activities and verify regular dialog appears

4. **Test reflection options:**
   - Test each of the three reflection options
   - Verify journal navigation works correctly
   - Verify activity selection and point awarding works

5. **Test edge cases:**
   - Close dialog without selecting option
   - Select option then cancel
   - Rapid tap on progress widget

### Success Criteria

✅ Reflection dialog appears only during evening (7 PM - 2 AM) with 0 activities
✅ Regular progress dialog appears at other times or with completed activities  
✅ All three reflection options work correctly
✅ Journal navigation with pre-filled content works
✅ Activity selection and point awarding works
✅ Dialog can be cancelled without side effects
✅ Success messages appear appropriately
✅ No crashes or errors in flow
