# End of Day Reflection Feature

## Overview
This feature provides a compassionate reflection guide for users who haven't completed any daily activities by the end of the day. Instead of showing a regular progress reminder, the app shows a thoughtful reflection dialog that helps users understand what happened and provides appropriate next steps.

## Trigger Conditions
The reflection dialog appears when:
1. User taps on the daily progress widget ("0 of 3 completed")
2. Current time is between 7 PM and 2 AM (evening/night)
3. No activities have been completed (0/3 completed)

## User Flow

### Step 1: Reflection Question
The dialog asks "Why weren't you able to complete your activities today?" with three options:

1. **"Busy - things came up"** (Orange color)
   - Leads to journaling with pre-filled template about busy day
   - Template includes sections for what happened, feelings, learnings, and tomorrow's plan

2. **"Emergency"** (Red color)  
   - Leads to journaling with pre-filled template about emergency situation
   - Template includes sections for what happened, processing, needs, and future steps

3. **"I completed some, just didn't check in"** (Green color)
   - Shows activity selection dialog
   - User can check which activities they actually completed
   - Awards appropriate integrity points (3 for virtue, 4 for habit, 5 for energy action)
   - Shows success message with awarded points

### Step 2: Based on Selection

**For Busy/Emergency:**
- Navigates to journal screen with pre-filled content
- User can journal their thoughts and feelings
- Provides structured reflection with bullet points

**For Completed Some:**
- Shows checkboxes for each activity type
- Calculates and displays total points to be awarded
- Marks selected activities as completed in the system
- Shows success confirmation

## Design Principles

1. **Compassionate Language**: Uses gentle, non-judgmental wording like "It's okay that today didn't go as planned"

2. **Visual Hierarchy**: 
   - Color-coded options (orange for busy, red for emergency, green for completed)
   - Clear icons for each option
   - Visual feedback for selections

3. **Flexible Options**: 
   - "Maybe Later" button allows users to defer reflection
   - No forced completion - user can close dialog anytime

4. **Constructive Outcomes**: 
   - Journaling for reflection and processing
   - Point recovery for actual completed work
   - Maintains user motivation and engagement

## Technical Implementation

### Files Modified:
- `lib/features/today/presentation/today_screen.dart` - Modified `_showProgressReminder()` method
- `lib/features/today/presentation/widgets/end_of_day_reflection_dialog.dart` - New dialog component

### Key Components:
- `EndOfDayReflectionDialog` - Main reflection dialog
- `ActivitySelectionDialog` - Dialog for selecting completed activities
- `ReflectionReason` enum - Defines the three response options

### Integration:
- Integrates with existing journal system via GoRouter navigation
- Uses existing daily anchors provider for state management
- Maintains existing point awarding system

## Time Logic
Evening is defined as 7 PM (19:00) to 2 AM (02:00) to capture:
- End of typical workday
- Before bedtime routine
- Late night check-ins

This timing ensures the reflection appears when the day is naturally concluding, making it more relevant and timely for users.
