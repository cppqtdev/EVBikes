#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>

struct VehicleData : public Qul::Singleton<VehicleData>
{
    enum RideMode : uint8_t { Eco = 0, Normal = 1, Sport = 2 };
    enum DriveState : uint8_t { Park = 0, Reverse = 1, Neutral = 2, Drive = 3 };
    enum ChargeState : uint8_t { NotCharging = 0, Charging = 1, ChargeComplete = 2, ChargeFault = 3 };

    enum Powertrain : uint8_t { Electric = 0, Petrol = 1 };
    // Bits 0..4: ICE; bits 6..10 and 15: EV; remaining bits: common.
    Qul::Property<uint8_t> powertrain;
    Qul::Property<uint8_t> fuelPercent;
    Qul::Property<uint16_t> telltaleFlags;
    Qul::Property<uint16_t> speedKmh;
    Qul::Property<uint16_t> motorRpm;
    Qul::Property<int8_t> powerPercent;
    Qul::Property<uint8_t> rideMode;
    Qul::Property<uint8_t> driveState;
    Qul::Property<bool> readyToRide;
    Qul::Property<bool> sideStandDown;

    Qul::Property<uint8_t> batteryPercent;
    Qul::Property<uint16_t> packVoltageX10;
    Qul::Property<int16_t> packCurrentAx10;
    Qul::Property<int16_t> packTempC;
    Qul::Property<int16_t> motorTempC;
    Qul::Property<int16_t> controllerTempC;
    Qul::Property<int16_t> ambientTempC;
    Qul::Property<uint8_t> chargeState;
    Qul::Property<uint16_t> rangeKm;

    Qul::Property<bool> indicatorLeft;
    Qul::Property<bool> indicatorRight;
    Qul::Property<bool> highBeam;
    Qul::Property<bool> lowBeam;
    Qul::Property<bool> hazard;
    Qul::Property<bool> absFault;
    Qul::Property<bool> absActive;

    Qul::Property<uint16_t> tyreFrontPsiX10;
    Qul::Property<uint16_t> tyreRearPsiX10;
    Qul::Property<uint32_t> odometerKm;
    Qul::Property<uint32_t> tripKmX10;
    Qul::Property<uint16_t> faultCode;
    Qul::Property<bool> crashDetected;

    // Set while the readings in that group are not arriving. The values above
    // keep their last figure, so anything bound to them must show the stale
    // look instead of the figure.
    Qul::Property<bool> driveStale;
    Qul::Property<bool> batteryStale;
    Qul::Property<bool> lampsStale;
    Qul::Property<bool> powertrainStale;

    VehicleData();

    void applySignal(uint8_t signalId, int32_t value);
};
