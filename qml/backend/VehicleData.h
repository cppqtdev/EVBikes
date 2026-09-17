#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

struct VehicleData : public Qul::Singleton<VehicleData>
{
    enum RideMode { Eco = 0, Normal = 1, Sport = 2 };
    enum DriveState { Park = 0, Reverse = 1, Neutral = 2, Drive = 3 };
    enum ChargeState { NotCharging = 0, Charging = 1, ChargeComplete = 2, ChargeFault = 3 };

    Qul::Property<int> speedKmh;
    Qul::Property<int> motorRpm;
    Qul::Property<int> powerPercent;
    Qul::Property<int> rideMode;
    Qul::Property<int> driveState;
    Qul::Property<bool> readyToRide;
    Qul::Property<bool> sideStandDown;

    Qul::Property<int> batteryPercent;
    Qul::Property<int> packVoltageX10;
    Qul::Property<int> packCurrentAx10;
    Qul::Property<int> packTempC;
    Qul::Property<int> motorTempC;
    Qul::Property<int> controllerTempC;
    Qul::Property<int> ambientTempC;
    Qul::Property<int> chargeState;
    Qul::Property<int> rangeKm;

    Qul::Property<bool> indicatorLeft;
    Qul::Property<bool> indicatorRight;
    Qul::Property<bool> highBeam;
    Qul::Property<bool> lowBeam;
    Qul::Property<bool> hazard;
    Qul::Property<bool> absFault;
    Qul::Property<bool> absActive;

    Qul::Property<int> tyreFrontPsiX10;
    Qul::Property<int> tyreRearPsiX10;
    Qul::Property<int> odometerKm;
    Qul::Property<int> tripKmX10;
    Qul::Property<int> faultCode;
    Qul::Property<bool> crashDetected;

    // Set while the readings in that group are not arriving. The values above
    // keep their last figure, so anything bound to them must show the stale
    // look instead of the figure.
    Qul::Property<bool> driveStale;
    Qul::Property<bool> batteryStale;
    Qul::Property<bool> lampsStale;

    VehicleData();

    void applySignal(int signalId, int value);
};
