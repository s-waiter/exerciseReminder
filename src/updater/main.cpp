#include <QApplication>
#if defined(_MSC_VER) && (_MSC_VER >= 1600)
# pragma execution_character_set("utf-8")
#endif
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
#include <windows.h>

class UpdaterWindow : public QWidget {
    Q_OBJECT
public:
    UpdaterWindow(QString zipPath, QString installDir, QString exeName) 
        : m_zipPath(zipPath), m_installDir(installDir), m_exeName(exeName) {
        
        setWindowTitle("DeskCare Updater");
        setFixedSize(400, 150);
        setWindowFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
        setStyleSheet("background-color: #2d2d2d; color: white; border: 1px solid #444; border-radius: 8px;");

        QVBoxLayout *layout = new QVBoxLayout(this);
        
        QLabel *title = new QLabel(QStringLiteral("\u6b63\u5728\u66f4\u65b0 DeskCare..."), this);
        title->setStyleSheet("font-size: 16px; font-weight: bold; margin-bottom: 10px; border: none;");
        title->setAlignment(Qt::AlignCenter);
        layout->addWidget(title);

        m_statusLabel = new QLabel(QStringLiteral("\u6b63\u5728\u7b49\u5f85\u4e3b\u7a0b\u5e8f\u9000\u51fa..."), this);
        m_statusLabel->setStyleSheet("color: #aaa; margin-bottom: 5px; border: none;");
        m_statusLabel->setAlignment(Qt::AlignCenter);
        layout->addWidget(m_statusLabel);

        m_progressBar = new QProgressBar(this);
        m_progressBar->setRange(0, 100);
        m_progressBar->setValue(0);
        m_progressBar->setStyleSheet(
            "QProgressBar { border: 1px solid #555; border-radius: 4px; background-color: #222; height: 10px; }"
            "QProgressBar::chunk { background-color: #3b82f6; border-radius: 4px; }"
        );
        layout->addWidget(m_progressBar);

        // Start update process
        QTimer::singleShot(1000, this, &UpdaterWindow::startUpdate);
    }

private slots:
    void startUpdate() {
        // 1. Wait for process to exit
        m_progressBar->setValue(10);
        QThread::sleep(2); // Give it a bit more time

        // 2. Unzip
        m_statusLabel->setText(QStringLiteral("\u6b63\u5728\u5b89\u88c5\u66f4\u65b0..."));
        m_progressBar->setValue(30);
        
        // Use PowerShell to unzip (Reliable & Built-in)
        // Expand-Archive -Path 'zip' -DestinationPath 'dir' -Force
        QString cmd = QString("powershell -Command \"Expand-Archive -Path '%1' -DestinationPath '%2' -Force\"")
                          .arg(m_zipPath)
                          .arg(m_installDir);
        
        int exitCode = QProcess::execute(cmd);
        
        if (exitCode != 0) {
            m_statusLabel->setText(QStringLiteral("\u66f4\u65b0\u5931\u8d25\uff1a\u89e3\u538b\u9519\u8bef"));
            QMessageBox::critical(this, QStringLiteral("\u66f4\u65b0\u5931\u8d25"), QStringLiteral("\u65e0\u6cd5\u89e3\u538b\u66f4\u65b0\u5305\uff0c\u8bf7\u91cd\u8bd5\u6216\u624b\u52a8\u4e0b\u8f7d\u3002"));
            QApplication::quit();
            return;
        }

        // Clean up zip file
        QFile::remove(m_zipPath);

        m_progressBar->setValue(90);
        m_statusLabel->setText(QStringLiteral("\u66f4\u65b0\u5b8c\u6210\uff0c\u6b63\u5728\u91cd\u542f..."));

        // 3. Restart
        QThread::sleep(1);
        QString exePath = m_installDir + "/" + m_exeName;
        
        // Use QProcess::startDetached to run without parent
        if (QProcess::startDetached(exePath, QStringList())) {
            m_progressBar->setValue(100);
            QTimer::singleShot(500, qApp, &QCoreApplication::quit);
        } else {
            m_statusLabel->setText(QStringLiteral("\u65e0\u6cd5\u542f\u52a8\u7a0b\u5e8f"));
            QMessageBox::critical(this, QStringLiteral("\u9519\u8bef"), QStringLiteral("\u65e0\u6cd5\u542f\u52a8\u7a0b\u5e8f: ") + exePath);
            QApplication::quit();
        }
    }

private:
    QString m_zipPath;
    QString m_installDir;
    QString m_exeName;
    QLabel *m_statusLabel;
    QProgressBar *m_progressBar;
};

#include "main.moc"

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);

    // Args: updater.exe <zip_path> <install_dir> <exe_name>
    if (argc < 4) {
        // Test mode or error
        // QMessageBox::information(nullptr, "Updater", "Usage: Updater.exe <zip_path> <install_dir> <exe_name>");
        // return 0;
        
        // For dev testing
        // UpdaterWindow w("C:/temp/update.zip", "C:/App", "DeskCare.exe");
        // w.show();
        return 0;
    }

    QString zipPath = QString::fromLocal8Bit(argv[1]);
    QString installDir = QString::fromLocal8Bit(argv[2]);
    QString exeName = QString::fromLocal8Bit(argv[3]);

    UpdaterWindow w(zipPath, installDir, exeName);
    w.show();

    return a.exec();
}
