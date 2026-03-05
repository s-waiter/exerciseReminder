# Chat Log: Prevent Sleep Fix for Exercise & Nap Mode

**Date:** 2026-02-08
**User Request:**
- User reported that the computer still automatically locks when the Exercise Reminder screen is displayed for a long time (e.g., during a 1-hour workout).
- User requested that both "Exercise Reminder" and "Nap Mode" screens should prevent the computer from automatically locking.

**Analysis:**
- **Root Cause**: The previous implementation of `WindowUtils::setPreventSleep` was a simple boolean toggle. In a complex application with multiple windows (e.g., multi-monitor support) or interacting modes (Nap vs Reminder), one component disabling sleep prevention (e.g., upon closing) would globally re-enable sleep, inadvertently canceling the prevention request from another active component.
- **Nap Mode Issue**: The `NapWindow.qml` front-end completely lacked the sleep prevention logic, relying solely on a backend signal which might be overridden by other UI events.
- **Exercise Reminder Issue**: `OverlayWindow` instances on secondary screens (or during reload) might have triggered the "allow sleep" logic, causing the system to lock even if the main reminder was visible.

**Solution Implementation:**
1.  **Refactored `WindowUtils`**:
    -   Changed `setPreventSleep` to support a `reason` identifier (Reference Counting pattern).
    -   Used `QSet<QString>` to track all active blockers.
    -   System sleep is only restored when *all* blockers are removed (Set is empty).
    -   Updated `setPreventSleep` signature to `void setPreventSleep(bool prevent, const QString &reason = "")`.

2.  **Updated `OverlayWindow.qml` (Exercise Reminder)**:
    -   Passed a unique identifier (`"OverlayWindow_" + overlayWin.toString()`) when requesting sleep prevention.
    -   Added `Component.onDestruction` to ensure the blocker is removed when the window is destroyed.

3.  **Updated `NapWindow.qml` (Nap Mode)**:
    -   Added `setPreventSleep(true, ...)` when the window becomes visible.
    -   Added corresponding cleanup on hide and destruction.
    -   Used unique identifier `"NapWindow_" + napWin.toString()`.

4.  **Updated `main.cpp`**:
    -   Updated the backend Nap Mode connection to use a distinct reason `"TimerEngine_NapMode"`. This acts as a safety net, ensuring Nap Mode prevents sleep even if the UI hasn't fully loaded.

**Files Modified:**
-   `src/utils/WindowUtils.h`
-   `src/utils/WindowUtils.cpp`
-   `assets/qml/OverlayWindow.qml`
-   `assets/qml/NapWindow.qml`
-   `src/main.cpp`

**Outcome:**
-   The system will now stay awake (display on, no lock) as long as *any* blocking component (Exercise Reminder OR Nap Mode) is active.
-   Robustness against race conditions and multi-window lifecycle events.
