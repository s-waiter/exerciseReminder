# Update Implementation Log (2026-01-31)

## Implemented Features
1. **Low-Disturbance Update Workflow**
   - **Silent Check**: Background checks do not interrupt the user unless explicitly requested.
   - **Visual Cue**: "Refresh" icon breathes (opacity animation) when an update is available.
   - **No Intrusion**: No popups or notifications for found updates until user interaction.

2. **User Interaction**
   - **Manual Check**: Clicking the refresh icon when no update is known triggers a visible check (with "Checking..." toast).
   - **Update Confirmation**: Clicking the breathing icon (or manual check finding update) opens a modal dialog.
   - **Dialog Content**: Shows new version number.

3. **Update Process**
   - **In-Dialog Progress**: Progress bar and status text displayed within the confirmation dialog (no separate window).
   - **Download Logic**: `UpdateManager` handles download with progress tracking.
   - **Install Trigger**: Automatically launches `Updater.exe` upon download completion.

## Technical Details

### C++ Backend (`src/core/UpdateManager`)
- **Properties**: Added `Q_PROPERTY` for `hasUpdate`, `updateStatus`, `downloadProgress` for QML binding.
- **Signals/Slots**:
  - `onDownloadProgress`: Updates progress property.
  - `startInstall`: Launches independent updater process.
  - `onVersionCheckFinished`: Updates state properties instead of direct UI calls.

### QML Frontend (`assets/qml/Main.qml`)
- **Refresh Icon**:
  - Added `SequentialAnimation` for breathing effect.
  - Logic to handle Manual Check vs. Open Dialog.
- **Update Dialog**:
  - Custom `Item` overlay with `z: 2000`.
  - Consistent UI style (Dark theme, Rounded corners).
  - Uses `mainWindow.themeColor` for buttons and progress bar.
- **Connections**:
  - Smart logic to auto-open dialog only if user initiated the check (`isChecking` flag).

## Next Steps
- Verify `Updater.exe` build configuration.
- Test update flow with actual server response.
