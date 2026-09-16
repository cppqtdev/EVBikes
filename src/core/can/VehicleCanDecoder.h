#pragma once

#include "CanFrame.h"
#include "VehicleSignals.h"

#include <array>

namespace evb {

class VehicleCanDecoder
{
public:
    using Sink = void (*)(const VehicleSignal &signal, void *ctx);

    VehicleCanDecoder(Sink sink, void *ctx) : m_sink(sink), m_ctx(ctx) {}

    // Returns false when the frame id is unknown or DLC is too short.
    bool decode(const CanFrame &frame);

    // Call periodically; emits safe defaults when a node stops talking.
    void checkTimeouts(uint32_t nowMs);

    static constexpr uint32_t kTimeoutMs = 500;

private:
    enum Node : uint8_t { Vcu, Motor, Bms, Body, Abs, NodeCount };

    void markSeen(Node node, uint32_t timestampMs);
    static int32_t timeoutFault(Node node);
    void emit(SignalId id, int32_t value);
    void emitIfChanged(SignalId id, int32_t value);

    Sink m_sink;
    void *m_ctx;
    std::array<int32_t, static_cast<std::size_t>(SignalId::Count)> m_last{};
    std::array<bool, static_cast<std::size_t>(SignalId::Count)> m_known{};
    std::array<uint32_t, NodeCount> m_lastSeen{};
    std::array<bool, NodeCount> m_timedOut{};
};

} // namespace evb
