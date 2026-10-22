#pragma once

#include <stdexcept>
#include <string>

//An exception that should be shown in the UI, and that doesn't make any state invalid.
class RecoverableException : public std::runtime_error {
public:
	/// Constructs a user-visible, recoverable error.
	///
	/// @param what            The message. This string WILL BE SHOWN TO THE USER, so it must read as
	///                        plain-language UI copy rather than as a developer log line.
	/// @param shouldDisconnect Whether the caller should tear the Bluetooth connection down after
	///                        catching this (e.g. a framing/checksum error that means the socket is
	///                        out of sync). Defaults to `false`, i.e. the session can continue.
	RecoverableException(const std::string& what, bool shouldDisconnect = false) : std::runtime_error(what), shouldDisconnect(shouldDisconnect) {}
	/// True when the connection must be dropped because the transport state is unusable.
	bool shouldDisconnect = false;
};
