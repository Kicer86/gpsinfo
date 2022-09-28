
#include <QGeoSatelliteInfoSource>

#include "satellites_model.hpp"


SatellitesModel::SatellitesModel()
{
    QGeoSatelliteInfoSource *satelliteSource = QGeoSatelliteInfoSource::createDefaultSource(this);
    if (satelliteSource)
    {
        const int updateInterval = std::max(satelliteSource->minimumUpdateInterval(), 10000);
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
