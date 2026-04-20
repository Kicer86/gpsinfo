
#include <QGeoSatelliteInfoSource>

#include "satellites_model.hpp"


SatellitesModel::SatellitesModel()
{
    // Throttle satellite updates to no faster than once every 10 seconds.
    // Polling satellites is cheap, but the model is used only to display
    // counters on screen and there is no value in refreshing more often.
    constexpr int kMinUpdateIntervalMs = 10'000;

    QGeoSatelliteInfoSource *satelliteSource = QGeoSatelliteInfoSource::createDefaultSource(this);
    if (satelliteSource)
    {
        const int updateInterval = std::max(satelliteSource->minimumUpdateInterval(), kMinUpdateIntervalMs);
        connect(satelliteSource, &QGeoSatelliteInfoSource::satellitesInViewUpdated, this, &SatellitesModel::satellitesInViewUpdated);
        connect(satelliteSource, &QGeoSatelliteInfoSource::satellitesInUseUpdated, this, &SatellitesModel::satellitesInUseUpdated);

        satelliteSource->setUpdateInterval(updateInterval);
        satelliteSource->startUpdates();
    }
}


void SatellitesModel::satellitesInViewUpdated(const QList<QGeoSatelliteInfo>& inView)
{
    m_inViewSatellites = inView.size();

    emit inViewSatellitesChanged(m_inViewSatellites);
}


void SatellitesModel::satellitesInUseUpdated(const QList<QGeoSatelliteInfo>& inUse)
{
    m_inUseSatellites = inUse.size();

    emit inUseSatellitesChanged(m_inUseSatellites);
}


int SatellitesModel::inViewSatellites() const
{
    return m_inViewSatellites;
}


int SatellitesModel::inUseSatellites() const
{
    return m_inUseSatellites;
}
