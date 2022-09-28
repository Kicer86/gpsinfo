
#include <QGeoSatelliteInfoSource>

#include "satellites_model.hpp"


SatellitesModel::SatellitesModel()
{
    QGeoSatelliteInfoSource *satelliteSource = QGeoSatelliteInfoSource::createDefaultSource(this);
    if (satelliteSource)
    {
        const int updateInterval = std::max(satelliteSource->minimumUpdateInterval(), 10000);
        satelliteSource->setUpdateInterval(updateInterval);
        satelliteSource->startUpdates();
    }
}

