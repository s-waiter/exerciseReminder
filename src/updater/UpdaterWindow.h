#ifndef UPDATERWINDOW_H
#define UPDATERWINDOW_H

#include <QWidget>
#include <QLabel>
#include <QProgressBar>

class UpdaterWindow : public QWidget {
    Q_OBJECT
public:
    UpdaterWindow(const QString &zipPath, const QString &installDir, const QString &appName);

protected:
    void closeEvent(QCloseEvent *event) override;

private slots:
    void startUpdate();

private:
    void updateStatus(const QString &text, int progress);

    QString m_zipPath;
    QString m_installDir;
    QString m_appName;
    QLabel *m_statusLabel;
    QProgressBar *m_progressBar;
    bool m_isUpdating = false;
};

#endif // UPDATERWINDOW_H
