#pragma once

#include <vector>
#include <string>
#include <deque>
#include <chrono>
#include <utility>
#include <limits>

using LargeCounter = unsigned long long;
using Clock = std::chrono::system_clock;
using TimePoint = std::chrono::time_point<Clock>;

auto constexpr DEFAULT_MAX_MESSAGES = 13371337;
constexpr auto DEFAULT_ERROR_MESSAGE_MS = 10000;

/// One expiring message held by ``TimedMessageQueue``.
struct Message
{
	/// Creates a message that stays visible until `releaseTime`.
	///
	/// @param message     The text to display.
	/// @param releaseTime The point in time at which this message becomes stale.
	Message(std::string message, TimePoint releaseTime) 
	{
		this->message = std::move(message);
		this->_releaseTime = releaseTime;
	}

	friend class TimedMessageQueue;

	/// The display text of the message.
	std::string message;
private:
	TimePoint _releaseTime;
};

/// A bounded FIFO of auto-expiring messages (used for user-facing error toasts).
///
/// Not thread-safe; single-owner use only.
class TimedMessageQueue
{
public:
	/// Creates a queue with a fixed retention policy.
	///
	/// @param maxMessages Maximum number of live messages; the oldest is dropped when exceeded.
	/// @param durationMs  How long (milliseconds) each message stays visible after being added.
	TimedMessageQueue(unsigned int maxMessages = DEFAULT_MAX_MESSAGES, unsigned long long durationMs = DEFAULT_ERROR_MESSAGE_MS);

	//I: A message, and the length of time it should remain available
	/// Appends a message that will be dropped after the queue's configured duration.
	///
	/// @param message The text to display; moved into the queue.
	void addMessage(std::string message);

	//The iteators returned are guaranteed to stay valid only until the next `begin()` or `addMessage` call.
	/// Iterates the live messages, discarding every expired entry first.
	///
	/// Must be called before ``end`` so stale messages are pruned.
	/// @return Iterator to the oldest live message.
	std::deque<Message>::const_iterator begin();

	/// Sentinel iterator one past the last message.
	///
	/// @return `std::deque<Message>::cend()`.
	std::deque<Message>::const_iterator end() const;
private:
	std::deque<Message> _messages;
	unsigned int _maxMessages = DEFAULT_MAX_MESSAGES;
	unsigned long long _durationMs;
};
