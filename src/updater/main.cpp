#include <QApplication>
#include <QWidget>
#include <QVBoxLayout>
#include <QLabel>
#include <QProgressBar>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QThread>
#include <QTimer>
#include <QDebug>
#include <QMessageBox>
#include <QJsonDocument>
#include <QJsonObject>
#include <windows.h>

class UpdaterWindow : public QWidget {
    Q_OBJECT
public:
    UpdaterWindow(const QString &zipPath, const QString &installDir, const QString &appName) 
        : m_zipPath(zipPath), m_installDir(installDir), m_appName(appName) 
    {
        setWindowTitle("DeskCare 正在更新");
        setFixedSize(400, 150);
        setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
        
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
        QTimer::singleShot(1000, this, &UpdaterWindow::startUpdate);
    }

private slots:
    void startUpdate() {
        // 1. Wait for main app to exit
        m_statusLabel->setText("等待主程序关闭...");
        QThread::sleep(1);
        
        // Kill if still running (simple check)
        QProcess::execute("taskkill", QStringList() << "/F" << "/IM" << m_appName);
        
        m_statusLabel->setText("正在解压文件...");
        m_progressBar->setValue(30);
        
        // 2. Unzip (Use 7z or simple file copy if zip lib not avail? 
        // For this demo, assuming we just replace the exe if it was a direct file, 
        // but since it is a zip, we need unzip. 
        // NOTE: In real prod, use KArchive or calls to 7z.exe/powershell)
        
        // Using PowerShell to unzip (Native on Windows 10+)
        QString psCommand = QString("Expand-Archive -Path '%1' -DestinationPath '%2' -Force")
                              .arg(m_zipPath, m_installDir);
                      
        QProcess process;
        process.start("powershell", QStringList() << "-command" << psCommand);
        process.waitForFinished();
        
        if (process.exitCode() != 0) {
            QMessageBox::critical(this, "更新失败", "解压文件失败:\n" + process.readAllStandardError());
            QApplication::quit();
            return;
        }

        // 2.5 Rename Directory based on version
        QFile versionFile(m_installDir + "/version_info.json");
        if (versionFile.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(versionFile.readAll());
            QJsonObject obj = doc.object();
            int major = obj["major"].toInt();
            int minor = obj["minor"].toInt();
            int patch = obj["patch"].toInt();
            QString versionStr = QString("v%1.%2.%3").arg(major).arg(minor).arg(patch);
            
            versionFile.close(); // Close file before renaming directory
            
            QDir installDir(m_installDir);
            QString oldDirName = installDir.dirName();
            QString newDirName = "DeskCare_" + versionStr;
            
            // Only rename if current dir follows naming convention and is different
            if (oldDirName != newDirName && oldDirName.startsWith("DeskCare_v")) {
                m_statusLabel->setText("正在更新目录名称...");
                
                // Navigate to parent to perform rename
                if (installDir.cdUp()) {
                    if (installDir.rename(oldDirName, newDirName)) {
                        // Update m_installDir to new path
                        m_installDir = installDir.absoluteFilePath(newDirName);
                        qDebug() << "Renamed directory to" << m_installDir;
                    } else {
                         qDebug() << "Failed to rename directory";
                    }
                }
            }
        }
        
        m_progressBar->setValue(90);
        m_statusLabel->setText("更新完成，正在重启...");
        
        // 3. Restart App
        QString appPath = m_installDir + "/" + m_appName;
        QProcess::startDetached(appPath, QStringList());
        
        m_progressBar->setValue(100);
        QTimer::singleShot(1000, qApp, &QApplication::quit);
    }

private:
    QString m_zipPath;
    QString m_installDir;
    QString m_appName;
    QLabel *m_statusLabel;
    QProgressBar *m_progressBar;
};

#include "main.moc"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    
    // Args: Updater.exe <zip_path> <install_dir> <app_name>
    QStringList args = a.arguments();
    if (args.count() < 4) {
        // Debug mode or error
        // QMessageBox::information(nullptr, "Updater", "Usage: Updater.exe <zip> <dir> <app>");
        // return 0;
    }
    
    QString zipPath = args.value(1);
    QString installDir = args.value(2);
    QString appName = args.value(3);
    
    UpdaterWindow w(zipPath, installDir, appName);
    w.show();
    
    return a.exec();
}
