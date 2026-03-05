# Chat Log: Prevent Sleep During Exercise Reminder

**Date:** 2026-02-07
**User Request:**
- Prevent the computer from locking screen/sleeping when the exercise reminder interface is shown (user mentioned they exercise for 1 hour and find the PC locked upon return).

**Analysis:**
- The OS (Windows) automatically locks or sleeps after a period of inactivity.
- The reminder window (`OverlayWindow`) is a full-screen overlay, but without explicit "keep awake" signals, the OS considers the system idle if there's no mouse/keyboard input.
- We need to call the Windows API `SetThreadExecutionState` with `ES_DISPLAY_REQUIRED` to prevent this.

**Implementation:**
1.  **Backend (`WindowUtils.cpp`)**: Verified that `setPreventSleep(bool)` is already implemented and uses `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED)`. This ensures the system stays running and the display stays on.
2.  **Frontend (`OverlayWindow.qml`)**: 
    -   Added a call to `windowUtils.setPreventSleep(true)` in the `onVisibleChanged` handler when the window becomes visible.
    -   Added a call to `windowUtils.setPreventSleep(false)` when the window becomes hidden to restore normal power saving settings.

**Key Files Modified:**
-   [OverlayWindow.qml](file:///c:/Users/admin/Desktop/trae/DeskCare/assets/qml/OverlayWindow.qml)

**Verification:**
-   The logic hooks into the existing visibility change event of the overlay window.
-   `windowUtils` is already exposed to QML context in `main.cpp`.
-   The solution directly addresses the user's pain point by keeping the screen alive during the entire reminder duration.

**Status:**
-   Completed.
