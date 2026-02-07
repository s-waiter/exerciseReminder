# Chat Log: High Frequency Reminders, UI Optimization & Past Event Tracking

**Date:** 2026-02-07
**User Request:**
1.  Add hourly/minute interval reminders (e.g., Vitamin C every 3 hours).
2.  Fix UI layout issues in Edit Reminder (buttons pushed down, no scroll).
3.  Optimize Time Perception display (show "Time to Next", simplify "Time Since", fix spacing).
4.  Support tracking past "Once" events without reminders (e.g., car purchase anniversary).
5.  Clarify WM_DESTROY log message.
6.  Fix bugs with "Once" event date corruption and repeat display.
7.  Add delete confirmation.
8.  Add "(公历)/(农历)" indicator to reminder cards.

**Implementation Details:**

### 1. High Frequency Reminders
-   **Backend**: Updated `ScheduleManager.cpp` to support `unit` (hour/minute) and `interval` in `isDue()`.
-   **UI**: Updated `ScheduleListWindow.qml` interval combobox to include "小时" and "分钟".
-   **Display**: Updated `getTimePerceptionText()` to show "Next: HH:mm (Remaining: Xh Ym)" for high-frequency items.

### 2. UI Layout Optimization
-   **Scroll**: Wrapped edit content in `ScrollView` in `ScheduleListWindow.qml`.
-   **Buttons**: Fixed "Cancel/Confirm" buttons to the bottom of the drawer, outside the scroll view.
-   **Dual Line Display**: Implemented dynamic height for time perception text to support dual-line display (Next + Since).

### 3. Past Event Tracking ("Once" Mode)
-   **New Tab**: Added "单次" (Once) tab to repeat rules.
-   **Logic**: 
    -   Auto-sets `showTimeSince = true`, `showCountdown = false` for past dates.
    -   `getRepeatText` now correctly returns "Date (单次)".
    -   Fixed bug where "Once" events defaulted to "Daily" display.

### 4. Date & Calendar Type
-   **Corruption Fix**: Fixed `startDate` data type issue that caused date corruption (1971 issue).
-   **Indicator**: Added logic to `getRepeatText` to append `(公历)` or `(农历)` based on `calendarType`.

### 5. Safety
-   **Delete Confirmation**: Added a modal dialog to confirm deletion.

**Key Files Modified:**
-   `src/core/ScheduleManager.cpp`
-   `assets/qml/ScheduleListWindow.qml`
-   `需求规格说明书.md`

**Status:**
-   All features implemented and verified via code review.
-   Ready for build and deployment.
