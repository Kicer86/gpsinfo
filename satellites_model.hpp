
#ifndef SATELLITES_MODEL_HPP_INCLUDED
#define SATELLITES_MODEL_HPP_INCLUDED

#include <QObject>
#include <QtQmlIntegration>

class QGeoSatelliteInfo;


class SatellitesModel: public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int inViewSatellites READ inViewSatellites NOTIFY inViewSatellitesChanged)
    Q_PROPERTY(int inUseSatellites READ inUseSatellites NOTIFY inUseSatellitesChanged)

public:
    SatellitesModel();

    int inViewSatellites() const;
    int inUseSatellites() const;

private:
    int m_inViewSatellites = 0;
    int m_inUseSatellites = 0;

    void satellitesInViewUpdated(const QList<QGeoSatelliteInfo> &);
    void satellitesInUseUpdated(const QList<QGeoSatelliteInfo> &);

signals:
    void inViewSatellitesChanged(int) const;
    void inUseSatellitesChanged(int) const;
};

#endif
