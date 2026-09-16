#include "PhoneData.h"

#include "Backend.h"

namespace {

enum class MediaCommand : uint8_t { PlayPause = 1, Next = 2, Previous = 3 };
enum class CallCommand : uint8_t { Answer = 1, Reject = 2 };

void sendMedia(MediaCommand cmd)
{
    const uint8_t payload[] = {static_cast<uint8_t>(cmd)};
    Backend::sendToPhone(evb::link::MsgType::MediaCommand, payload, sizeof(payload));
}

void sendCall(CallCommand cmd)
{
    const uint8_t payload[] = {static_cast<uint8_t>(cmd)};
    Backend::sendToPhone(evb::link::MsgType::CallCommand, payload, sizeof(payload));
}

} // namespace

void PhoneData::mediaPlayPause()
{
    sendMedia(MediaCommand::PlayPause);
}

void PhoneData::mediaNext()
{
    sendMedia(MediaCommand::Next);
}

void PhoneData::mediaPrevious()
{
    sendMedia(MediaCommand::Previous);
}

void PhoneData::answerCall()
{
    sendCall(CallCommand::Answer);
}

void PhoneData::rejectCall()
{
    sendCall(CallCommand::Reject);
    callStatus.setValue(Idle);
}
