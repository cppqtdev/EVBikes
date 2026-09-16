#include "../src/core/alerts/AlertEvaluator.h"
#include "../src/core/can/CanIds.h"
#include "../src/core/can/VehicleCanDecoder.h"
#include "../src/core/nav/PhoneLinkProtocol.h"
#include "../src/core/util/Filters.h"
#include "../src/core/util/RingBuffer.h"

#include <cstdio>
#include <cstring>
#include <vector>

static int g_failures = 0;
#define CHECK(cond) do { if (!(cond)) { std::printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #cond); ++g_failures; } } while (0)

using namespace evb;

static void collect(const VehicleSignal &s, void *ctx)
{
    static_cast<std::vector<VehicleSignal> *>(ctx)->push_back(s);
}

static int32_t find(const std::vector<VehicleSignal> &v, SignalId id, int32_t fallback = -9999)
{
    for (auto it = v.rbegin(); it != v.rend(); ++it)
        if (it->id == id) return it->value;
    return fallback;
}

static void testCanDecoder()
{
    std::vector<VehicleSignal> out;
    VehicleCanDecoder dec(collect, &out);

    CanFrame vcu;
    vcu.id = canid::VcuStatus;
    vcu.dlc = 4;
    vcu.timestampMs = 10;
    canSetBitsLE(vcu.data, 0, 16, 573);
    canSetBitsLE(vcu.data, 16, 3, 2);
    canSetBitsLE(vcu.data, 19, 2, 3);
    canSetBitsLE(vcu.data, 21, 1, 1);
    canSetBitsLE(vcu.data, 24, 8, 27 + 40);
    CHECK(dec.decode(vcu));
    CHECK(find(out, SignalId::AmbientTempC) == 27);
    CHECK(find(out, SignalId::SpeedKmhX10) == 573);
    CHECK(find(out, SignalId::RideMode) == 2);
    CHECK(find(out, SignalId::DriveState) == 3);
    CHECK(find(out, SignalId::ReadyToRide) == 1);

    const std::size_t before = out.size();
    CHECK(dec.decode(vcu));
    CHECK(out.size() == before);

    CanFrame motor;
    motor.id = canid::MotorStatus;
    motor.dlc = 6;
    canSetBitsLE(motor.data, 0, 16, 4200);
    canSetBitsLE(motor.data, 16, 16, static_cast<uint32_t>(-125) & 0xFFFF);
    canSetBitsLE(motor.data, 32, 8, 60 + 40);
    CHECK(dec.decode(motor));
    CHECK(find(out, SignalId::PhaseCurrentAx10) == -125);
    CHECK(find(out, SignalId::MotorTempC) == 60);

    CanFrame bad;
    bad.id = canid::BmsStatus;
    bad.dlc = 3;
    CHECK(!dec.decode(bad));
    bad.id = 0x55;
    CHECK(!dec.decode(bad));

    const uint32_t later = 10 + VehicleCanDecoder::kTimeoutMs + 100;
    CanFrame others[4];
    others[0].id = canid::MotorStatus; others[0].dlc = 6;
    others[1].id = canid::BmsStatus; others[1].dlc = 8;
    others[2].id = canid::BodyLamps; others[2].dlc = 1;
    others[3].id = canid::AbsStatus; others[3].dlc = 1;
    for (CanFrame &o : others) {
        o.timestampMs = later;
        CHECK(dec.decode(o));
    }
    out.clear();
    dec.checkTimeouts(later);
    CHECK(find(out, SignalId::ReadyToRide) == 0);
    CHECK(find(out, SignalId::FaultCode) == 0x0101);

    out.clear();
    vcu.timestampMs = 2000;
    CHECK(dec.decode(vcu));
    CHECK(find(out, SignalId::FaultCode) == 0);
}

struct Capture : link::Handler
{
    int navCount = 0;
    int errors = 0;
    link::NavUpdate last;
    link::CallState call;
    void onNavUpdate(const link::NavUpdate &n) override { ++navCount; last = n; }
    void onCallState(const link::CallState &c) override { call = c; }
    void onFrameError() override { ++errors; }
};

static void testPhoneLink()
{
    link::NavUpdate nav;
    nav.maneuver = link::Maneuver::Right;
    nav.distanceToManeuverM = 250;
    nav.distanceRemainingM = 12400;
    nav.etaMinutes = 23;
    std::strcpy(nav.roadName, "MG Road");

    uint8_t frame[link::kMaxFrame];
    const std::size_t n = link::encodeNavUpdate(nav, frame, sizeof(frame));
    CHECK(n > 0);

    Capture cap;
    link::Parser parser(cap);
    const uint8_t noise[] = {0x00, 0x13, 0xA5, 0x09};
    parser.feed(noise, sizeof(noise));
    for (std::size_t i = 0; i < n; ++i)
        parser.feed(frame + i, 1);
    CHECK(cap.navCount == 1);
    CHECK(cap.last.maneuver == link::Maneuver::Right);
    CHECK(cap.last.distanceToManeuverM == 250);
    CHECK(cap.last.etaMinutes == 23);
    CHECK(std::strcmp(cap.last.roadName, "MG Road") == 0);

    frame[n - 3] ^= 0xFF;
    parser.feed(frame, n);
    CHECK(cap.navCount == 1);
    CHECK(parser.badFrames() >= 1);

    uint8_t payload[] = {1, 5, 'A', 'n', 'i', 't', 'a'};
    const std::size_t m = link::buildFrame(link::MsgType::CallState, payload, sizeof(payload), frame, sizeof(frame));
    parser.feed(frame, m);
    CHECK(cap.call.status == link::CallStatus::Ringing);
    CHECK(std::strcmp(cap.call.caller, "Anita") == 0);

    uint8_t shortPayload[] = {1, 40, 'x'};
    const std::size_t k = link::buildFrame(link::MsgType::CallState, shortPayload, sizeof(shortPayload), frame, sizeof(frame));
    const int errBefore = cap.errors;
    parser.feed(frame, k);
    CHECK(cap.errors == errBefore + 1);
}

static void testAlerts()
{
    AlertEvaluator ev;
    AlertInputs in;
    CHECK(ev.evaluate(in).kind == AlertKind::None);

    in.tyreRearPsiX10 = 275;
    CHECK(ev.evaluate(in).kind == AlertKind::LowTyreRear);
    in.tyreRearPsiX10 = 285;
    CHECK(ev.evaluate(in).kind == AlertKind::LowTyreRear);
    in.tyreRearPsiX10 = 295;
    CHECK(ev.evaluate(in).kind == AlertKind::None);

    in.packTempC = 61;
    in.crashDetected = true;
    AlertResult r = ev.evaluate(in);
    CHECK(r.kind == AlertKind::CrashDetected && r.level == AlertLevel::Critical);
    in.crashDetected = false;
    CHECK(ev.evaluate(in).kind == AlertKind::BatteryOverheat);
}

static void testUtils()
{
    RingBuffer<int, 4> rb;
    CHECK(rb.push(1) && rb.push(2) && rb.push(3));
    CHECK(!rb.push(4));
    int v = 0;
    CHECK(rb.pop(v) && v == 1);

    EmaFilter f(2);
    CHECK(f.update(100) == 100);
    CHECK(f.update(0) == 75);

    Debouncer d(3);
    CHECK(!d.update(true) && !d.update(true) && d.update(true));
}

int main()
{
    testCanDecoder();
    testPhoneLink();
    testAlerts();
    testUtils();
    std::printf(g_failures ? "%d FAILURE(S)\n" : "ALL TESTS PASSED\n", g_failures);
    return g_failures ? 1 : 0;
}
