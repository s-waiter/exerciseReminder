#include "UpdaterWindow.h"
#include <QVBoxLayout>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QThread>
#include <QTimer>
#include <QDebug>
#include <QMessageBox>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QTextStream>
#include <QCloseEvent>
#include <QApplication>

UpdaterWindow::UpdaterWindow(const QString &zipPath, const QString &installDir, const QString &appName) 
    : m_zipPath(zipPath), m_installDir(installDir), m_appName(appName) 
{
    setWindowTitle("DeskCare 正在更新");
    setFixedSize(400, 150);
    // Remove Close Button to prevent accidental closing
    setWindowFlags(Qt::Window | Qt::CustomizeWindowHint | Qt::WindowTitleHint);
    
    // Setup UI
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(20, 20, 20, 20);
    
    m_statusLabel = new QLabel("正在准备更新...", this);
    m_statusLabel->setStyleSheet("font-size: 14px; color: #333;");
    layout->addWidget(m_statusLabel);
    
    layout->addSpacing(10);
    
    m_progressBar = new QProgressBar(this);
    m_progressBar->setRange(0, 100);
    m_progressBar->setValue(0);
    layout->addWidget(m_progressBar);
    
    // Start update process
    QTimer::singleShot(500, this, &UpdaterWindow::startUpdate);
}

void UpdaterWindow::closeEvent(QCloseEvent *event) {
    if (m_isUpdating) {
        event->ignore();
    } else {
        event->accept();
    }
}

void UpdaterWindow::startUpdate() {
    m_isUpdating = true;

    // 1. Wait for main app to exit
    updateStatus("正在关闭主程序...", 5);
    QThread::msleep(500);
    
    // Force kill DeskCare.exe
    QProcess::execute("taskkill", QStringList() << "/F" << "/IM" << m_appName);
    
    updateStatus("正在准备更新环境...", 10);
    
    // 2. Unzip to Temp Directory
    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QString extractPath = tempDir + "/DeskCare_Update_Extract";
    
    // Clean up previous extract
    QDir(extractPath).removeRecursively();
    
    updateStatus("正在解压更新包...", 20);

    // Escape single quotes for PowerShell
    QString safeZipPath = m_zipPath;
    safeZipPath.replace("'", "''");
    QString safeExtractPath = extractPath;
    safeExtractPath.replace("'", "''");

    QString psCommand = QString("Expand-Archive -Path '%1' -DestinationPath '%2' -Force")
                          .arg(safeZipPath, safeExtractPath);
                  
    QProcess process;
    process.start("powershell", QStringList() << "-command" << psCommand);
    
    // Wait for finish while keeping UI responsive (manual event loop)
    while (!process.waitForFinished(100)) {
        qApp->processEvents();
    }
    
    if (process.exitCode() != 0) {
        QString error = process.readAllStandardError();
        if (error.isEmpty()) error = "未知错误 (PowerShell exit code: " + QString::number(process.exitCode()) + ")";
        QMessageBox::critical(this, "更新失败", "解压文件失败:\n" + error);
        m_isUpdating = false;
        QApplication::quit();
        return;
    }
    
    updateStatus("正在解析版本信息...", 60);

    // 3. Determine New Folder Name
    QString finalDirName = "";
    QFile versionFile(extractPath + "/version_info.json");
    if (versionFile.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(versionFile.readAll());
        QJsonObject obj = doc.object();
        int major = obj["major"].toInt();
        int minor = obj["minor"].toInt();
        int patch = obj["patch"].toInt();
        QString versionStr = QString("v%1.%2.%3").arg(major).arg(minor).arg(patch);
        finalDirName = "DeskCare_" + versionStr;
        versionFile.close();
    }
    
    // 4. Create Batch Script to Finish Update
    updateStatus("正在生成更新脚本...", 80);
    
    QString logPath = tempDir + "/finish_update.log";
    QString batPath = tempDir + "/finish_update.bat";
    qint64 currentPid = QCoreApplication::applicationPid();

    QFile batFile(batPath);
    if (batFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&batFile);
        out << "@echo off\n";
        out << "chcp 65001 >nul\n"; // UTF-8
        out << "echo [INFO] Starting update process... > \"" << logPath << "\"\n";
        out << "echo [INFO] Waiting for Updater (PID: " << currentPid << ") to close... >> \"" << logPath << "\"\n";
        
        // Robust Wait for THIS process ID
        out << ":loop\n";
        out << "tasklist /FI \"PID eq " << currentPid << "\" 2>NUL | find /I \"" << currentPid << "\">NUL\n";
        out << "if \"%ERRORLEVEL%\"==\"0\" (\n";
        out << "    echo [WAIT] Updater is still running... >> \"" << logPath << "\"\n";
        out << "    timeout /t 1 >nul\n";
        out << "    goto loop\n";
        out << ")\n";
        out << "echo [INFO] Updater closed. >> \"" << logPath << "\"\n";
        
        // Small safety buffer
        out << "timeout /t 1 >nul\n";

        // Kill DeskCare again just in case (belt and suspenders)
        out << "taskkill /F /IM " << m_appName << " >> \"" << logPath << "\" 2>&1\n";

        // Copy files
        QString nativeSource = QDir::toNativeSeparators(extractPath);
        QString nativeDest = QDir::toNativeSeparators(m_installDir);
        
        // Define TARGET_DIR variable in batch to track the actual path (pre/post rename)
        out << "set \"TARGET_DIR=" << nativeDest << "\"\n";

        out << "echo [INFO] Copying files from " << nativeSource << " to %TARGET_DIR%... >> \"" << logPath << "\"\n";
        // xcopy /s /e /y /i
        out << "xcopy /s /e /y /i \"" << nativeSource << "\" \"%TARGET_DIR%\" >> \"" << logPath << "\" 2>&1\n";
        
        out << "if errorlevel 1 (\n";
        out << "    echo [ERROR] XCOPY FAILED! >> \"" << logPath << "\"\n";
        out << "    exit /b 1\n";
        out << ")\n";

        // Rename Directory if needed
        if (!finalDirName.isEmpty()) {
            QDir installDirObj(m_installDir);
            QString oldDirName = installDirObj.dirName();
            if (oldDirName != finalDirName && oldDirName.startsWith("DeskCare_v")) {
                installDirObj.cdUp();
                QString parentPath = QDir::toNativeSeparators(installDirObj.absolutePath());
                QString nativeFinalName = finalDirName;
                
                out << "echo [INFO] Renaming directory from " << oldDirName << " to " << finalDirName << "... >> \"" << logPath << "\"\n";
                // Ensure we are in the parent directory to execute rename
                out << "cd /d \"" << parentPath << "\"\n";
                
                // Safety: if target dir exists (e.g. from failed run), delete it first
                out << "if exist \"" << nativeFinalName << "\" (\n";
                out << "    echo [WARN] Target directory exists, removing... >> \"" << logPath << "\"\n";
                out << "    rd /s /q \"" << nativeFinalName << "\"\n";
                out << ")\n";

                out << "ren \"" << oldDirName << "\" \"" << finalDirName << "\" >> \"" << logPath << "\" 2>&1\n";
                
                // Only update TARGET_DIR if rename succeeded
                out << "if %ERRORLEVEL%==0 set \"TARGET_DIR=" << parentPath << "\\" << finalDirName << "\"\n";
            }
        }
        
        // Launch App
        out << "echo [INFO] Starting application at %TARGET_DIR%\\" << m_appName << "... >> \"" << logPath << "\"\n";
        out << "start \"\" \"%TARGET_DIR%\\" << m_appName << "\"\n";
        
        // Clean up temp files (self-delete batch file is tricky, let's leave it or delete on next run)
        // out << "del \"%~f0\" & exit\n"; 
    }
    batFile.close();
    
    updateStatus("即将重启...", 100);
    QThread::msleep(500);
    
    // 5. Execute Batch and Quit
    // Use cmd /c to run bat, set working directory to tempDir to avoid locking the app folder
    QProcess::startDetached("cmd.exe", QStringList() << "/c" << batPath, tempDir);
    m_isUpdating = false;
    QTimer::singleShot(100, qApp, &QApplication::quit);
}

void UpdaterWindow::updateStatus(const QString &text, int progress) {
    m_statusLabel->setText(text);
    m_progressBar->setValue(progress);
    qApp->processEvents(); // Ensure UI updates
}
