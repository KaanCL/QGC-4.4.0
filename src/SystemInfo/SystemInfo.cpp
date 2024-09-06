#include "SystemInfo.h"

#ifdef Q_OS_ANDROID
#include "android/src/AndroidInterface.h"
#endif



SystemInfo::SystemInfo(){
#ifdef Q_OS_ANDROID
    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &SystemInfo::setAndroidInfo);
    timer->start(1000);
#endif

#ifdef Q_OS_WINDOWS
    if(GetSystemPowerStatus(&battery_state)){
        setSys_battary(battery_state.BatteryLifePercent);
    }
#endif

}

int SystemInfo::sys_Battery() const
{
    return m_sys_Battery;
}

void SystemInfo::set_Sys_Battery(int newSys_Battery)
{
    if (m_sys_Battery == newSys_Battery)
        return;
    m_sys_Battery = newSys_Battery;
    emit sys_BatteryChanged();
}

QString SystemInfo::sys_Time() const
{
    return m_sys_Time;
}

void SystemInfo::setSys_Time(const QString &newSys_Time)
{
    if (m_sys_Time == newSys_Time)
        return;
    m_sys_Time = newSys_Time;
    emit sys_TimeChanged();
}

#ifdef Q_OS_ANDROID
void SystemInfo::setAndroidInfo(){

    set_Sys_Battery(AndroidInterface::getBattery());
    setSys_Time(AndroidInterface::getTime());
}
#endif

