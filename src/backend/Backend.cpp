#include "Backend.h"

#include <cstdio>

#include "../core/alerts/AlertEvaluator.h"
#include "../core/can/VehicleCanDecoder.h"
#include "../platform/PlatformIo.h"

#include "AlertData.h"
#include "NavigationData.h"
#include "PhoneData.h"
#include "PhoneListData.h"
#include "SystemData.h"
#include "TripData.h"
#include "VehicleData.h"

#include <qul/eventqueue.h>

#include <cstring>

namespace {

constexpr uint32_t kPhoneLinkTimeoutMs = 5000;

struct PhoneChunk
{
    uint8_t len = 0;
    uint8_t data[32] = {};
};

void onVehicleSignal(const evb::VehicleSignal &signal, void *)
{
    VehicleData::instance().applySignal(static_cast<uint8_t>(signal.id), signal.value);
}

evb::VehicleCanDecoder g_decoder(onVehicleSignal, nullptr);
evb::AlertEvaluator g_alerts;
uint32_t g_lastPhoneRxMs = 0;

class PhoneHandler : public evb::link::Handler
{
public:
    void onNavUpdate(const evb::link::NavUpdate &n) override
    {
        NavigationData &nav = NavigationData::instance();
        nav.maneuver.setValue(static_cast<uint8_t>(n.maneuver));
        nav.roundaboutExit.setValue(n.roundaboutExit);
        nav.distanceToManeuverM.setValue(n.distanceToManeuverM);
        nav.distanceRemainingM.setValue(n.distanceRemainingM);
        nav.etaMinutes.setValue(n.etaMinutes);
        nav.laneMask.setValue(n.laneMask);
        nav.recommendedLaneMask.setValue(n.recommendedLaneMask);
        nav.roadName.setValue(std::string(n.roadName));
        nav.active.setValue(n.maneuver != evb::link::Maneuver::None);
    }

    void onNavStop() override { NavigationData::instance().clear(); }

    void onCallState(const evb::link::CallState &c) override
    {
        PhoneData &p = PhoneData::instance();
        p.callStatus.setValue(static_cast<uint8_t>(c.status));
        p.callerName.setValue(std::string(c.caller));
    }

    void onMediaState(const evb::link::MediaState &m) override
    {
        PhoneData &p = PhoneData::instance();
        p.mediaPlaying.setValue(m.playing);
        p.volume.setValue(m.volume);
        p.trackPositionS.setValue(m.positionS);
        p.trackDurationS.setValue(m.durationS);
        p.trackTitle.setValue(std::string(m.title));
        p.trackArtist.setValue(std::string(m.artist));
    }

    void onNotification(const evb::link::Notification &n) override
    {
        PhoneData &p = PhoneData::instance();
        p.notificationSender.setValue(std::string(n.sender));
        p.notificationText.setValue(std::string(n.text));
        p.notificationSeq.setValue(p.notificationSeq.value() + 1);
    }

    void onListEntry(const evb::link::ListEntry &e) override
    {
        PhoneListData::instance().setEntry(static_cast<uint8_t>(e.list), e.slot, std::string(e.title), std::string(e.text));
    }

    void onTimeSync(const evb::link::TimeSync &t) override
    {
        SystemData::instance().setClock(t.unixSeconds, t.utcOffsetMinutes);
    }

    void onPhoneStatus(const evb::link::PhoneStatus &s) override
    {
        PhoneData &p = PhoneData::instance();
        p.batteryPercent.setValue(s.batteryPercent);
        p.signalBars.setValue(s.signalBars);
        p.internet.setValue(s.internet);
    }
};

PhoneHandler g_phoneHandler;
evb::link::Parser g_phoneParser(g_phoneHandler);

//  TEMPORARY. On the real runtime these arrive from the event loop after the
//  tick has returned, which is outside the tick trace and is where the
//  desktop shim differs most: it delivers them inside step() instead.
uint32_t g_traceEvents = 0;

class CanQueue : public Qul::EventQueue<evb::CanFrame>
{
public:
    void onEvent(const evb::CanFrame &frame) override
    {
        ++g_traceEvents;
        const bool trace = g_traceEvents <= 60;
        if (trace) {
            std::printf("[can %u] decode id=0x%X\n",
                        static_cast<unsigned>(g_traceEvents),
                        static_cast<unsigned>(frame.id));
            std::fflush(stdout);
        }
        g_decoder.decode(frame);
        if (trace) {
            std::printf("[can %u] decoded\n", static_cast<unsigned>(g_traceEvents));
            std::fflush(stdout);
        }
    }
};

class PhoneQueue : public Qul::EventQueue<PhoneChunk>
{
public:
    void onEvent(const PhoneChunk &chunk) override
    {
        g_lastPhoneRxMs = evb::platform::millis();
        PhoneData::instance().connected.setValue(true);
        g_phoneParser.feed(chunk.data, chunk.len);
    }
};

CanQueue &canQueue()
{
    static CanQueue q;
    return q;
}

PhoneQueue &phoneQueue()
{
    static PhoneQueue q;
    return q;
}

void setIfChanged(Qul::Property<bool> &property, bool value)
{
    if (property.value() != value)
        property.setValue(value);
}

void evaluateAlerts()
{
    const VehicleData &v = VehicleData::instance();
    evb::AlertInputs in;
    in.speedKmhX10 = v.speedKmh.value() * 10;
    in.socPercentX10 = v.batteryPercent.value() * 10;
    in.packTempC = v.packTempC.value();
    in.motorTempC = v.motorTempC.value();
    in.tyreFrontPsiX10 = v.tyreFrontPsiX10.value();
    in.tyreRearPsiX10 = v.tyreRearPsiX10.value();
    in.sideStandDown = v.sideStandDown.value();
    in.absFault = v.absFault.value();
    in.crashDetected = v.crashDetected.value();
    in.faultCode = v.faultCode.value();
    const evb::AlertResult r = g_alerts.evaluate(in);
    AlertData::instance().update(static_cast<uint8_t>(r.kind), static_cast<uint8_t>(r.level));
}

template <typename PostFn>
void splitAndPost(const uint8_t *data, std::size_t len, PostFn post)
{
    while (len > 0) {
        PhoneChunk chunk;
        const std::size_t n = len < sizeof(chunk.data) ? len : sizeof(chunk.data);
        std::memcpy(chunk.data, data, n);
        chunk.len = static_cast<uint8_t>(n);
        post(chunk);
        data += n;
        len -= n;
    }
}

} // namespace

namespace Backend {

void init()
{
    canQueue();
    phoneQueue();
    evb::platform::init();

    // Push the stored brightness to the panel, so the first frame is at the
    // level the rider left it rather than whatever the driver came up at.
    SystemData &system = SystemData::instance();
    system.setBrightnessLevel(system.brightness.value());

}

void postCanFrame(const evb::CanFrame &frame)
{
    static uint32_t posted = 0;
    ++posted;
    if (posted <= 60) {
        std::printf("[can] post %u id=0x%X\n", static_cast<unsigned>(posted),
                    static_cast<unsigned>(frame.id));
        std::fflush(stdout);
    }
    //  Decoded here and not queued. This is the caller that is already on the
    //  UI thread -- the simulator, and a driver that polls -- so the queue
    //  bought nothing, and it cost: it holds a fixed number of events, the
    //  eight frames a tick posts did not fit, and the last three of every
    //  tick were dropped before anything read them. An interrupt still has
    //  postCanFrameFromIsr, which is what the queue is for.
    g_decoder.decode(frame);
}

void postCanFrameFromIsr(const evb::CanFrame &frame)
{
    canQueue().postEventFromInterrupt(frame);
}

void receiveCanFrameFromIsr(uint32_t id, const uint8_t *data, uint8_t dlc)
{
    if ((!data && dlc != 0) || id > 0x1FFFFFFFu)
        return;

    evb::CanFrame frame;
    frame.id = id;
    frame.dlc = dlc > sizeof(frame.data) ? sizeof(frame.data) : dlc;
    frame.timestampMs = evb::platform::millis();
    for (uint8_t i = 0; i < frame.dlc; ++i)
        frame.data[i] = data[i];
    canQueue().postEventFromInterrupt(frame);
}

void postPhoneBytes(const uint8_t *data, std::size_t len)
{
    splitAndPost(data, len, [](const PhoneChunk &c) { phoneQueue().postEvent(c); });
}

void postPhoneBytesFromIsr(const uint8_t *data, std::size_t len)
{
    splitAndPost(data, len, [](const PhoneChunk &c) { phoneQueue().postEventFromInterrupt(c); });
}

void periodic(uint32_t nowMs)
{
    g_decoder.checkTimeouts(nowMs);

    VehicleData &vehicle = VehicleData::instance();
    setIfChanged(vehicle.driveStale, g_decoder.driveStale());
    setIfChanged(vehicle.batteryStale, g_decoder.batteryStale());
    setIfChanged(vehicle.lampsStale, g_decoder.lampsStale());

    TripData::instance().update(nowMs);
    evaluateAlerts();

    PhoneData &phone = PhoneData::instance();
    if (phone.connected.value() && nowMs - g_lastPhoneRxMs > kPhoneLinkTimeoutMs) {
        phone.connected.setValue(false);
        phone.callStatus.setValue(PhoneData::Idle);
        NavigationData::instance().clear();
        PhoneListData::instance().clear();
        g_phoneParser.reset();
    }
}

bool sendToPhone(evb::link::MsgType type, const uint8_t *payload, std::size_t len)
{
    uint8_t frame[evb::link::kMaxFrame];
    const std::size_t n = evb::link::buildFrame(type, payload, len, frame, sizeof(frame));
    return n > 0 && evb::platform::sendPhoneBytes(frame, n);
}

} // namespace Backend
