# Chat Log: Workout Timer Implementation

**Date:** 2026-02-08
**User Request:**
- User requested a "low-key but exquisite" workout timer in the exercise reminder screen.
- The timer should help users control their workout duration (e.g., aiming for 10, 15, 20 minutes) since the current UI only shows duration *after* finishing.
- Position: Bottom-right corner or other unobtrusive location.

**Analysis:**
- **Current State**: `OverlayWindow.qml` is a full-screen reminder with a feedback layer that appears after completion. The actual exercise duration is tracked internally but not displayed in real-time.
- **Requirements**:
  - Real-time update (MM:SS format).
  - Unobtrusive ("Low-key") yet beautiful ("Exquisite").
  - Should not overlap with the "Feedback Layer" (which covers the screen after finishing).

**Solution Implementation:**
1.  **Component Design**:
    -   Created a "Glassmorphism" capsule style using a semi-transparent background (`#15FFFFFF`) with a subtle border and shadow.
    -   Used a breathing dot indicator (color matched to the active theme) instead of a generic clock icon for a more modern, "exquisite" look.
    -   Used `Segoe UI` font with a thin weight and slight outline to ensure readability against dynamic backgrounds without being heavy.
2.  **Placement**:
    -   Anchored to the bottom-right (`anchors.right`, `anchors.bottom`) with `40px` margins to keep it unobtrusive.
    -   Z-index set to `999` to sit above the background/content but below the mouse tracker and feedback layer.
3.  **Logic**:
    -   Added a dedicated `Timer` updating every 1 second.
    -   Calculates duration based on `new Date() - showTime` to ensure accuracy even if the UI lags.
    -   Visibility logic: `overlayWin.visible && !feedbackLayer.visible`. This ensures it automatically hides when the user clicks "Finish" and the feedback summary appears.

**Files Modified:**
-   `assets/qml/OverlayWindow.qml`

**Outcome:**
-   Users can now see their workout duration in real-time in the bottom-right corner.
-   The design integrates seamlessly with the existing Sci-Fi/Dark theme.
