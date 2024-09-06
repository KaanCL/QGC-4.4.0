#ifndef SYSTEMINFO_H
#define SYSTEMINFO_H
#include "qtimer.h"
#include <QObject>
#include "QDebug"

#ifdef Q_OS_WIN
#include <Windows.h>
#endif


class SystemInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int sys_Battery READ sys_Battery WRITE set_Sys_Battery NOTIFY sys_BatteryChanged FINAL)
    Q_PROPERTY(QString sys_Time READ sys_Time WRITE setSys_Time NOTIFY sys_TimeChanged FINAL)


    #ifdef Q_OS_ANDROID
    void setAndroidInfo();
    #endif

public:
    SystemInfo();

    int sys_Battery() const;
    void set_Sys_Battery(int newSys_Battery);

    QTimer *timer;



    QString sys_Time() const;
    void setSys_Time(const QString &newSys_Time);

signals:
    void sys_BatteryChanged();
    void sys_TimeChanged();

private:
    int m_sys_Battery;
    QString m_sys_Time;
};

#endif // SYSTEMINFO_H
