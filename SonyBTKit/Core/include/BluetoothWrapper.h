#pragma once

#include "IBluetoothConnector.h"
#include "CommandSerializer.h"
#include "Constants.h"
#include <memory>
#include <vector>
#include <string>
#include <mutex>


//Thread-safety: This class is thread-safe.
/// Owns the Bluetooth transport and the framing/ACK state machine on top of it.
///
/// Every call is serialized by an internal mutex, so the same instance can be shared between the
/// serial command queue and the background read queue used by `HeadphonesBridge`.
class BluetoothWrapper
{
public:
	/// Takes ownership of a platform transport.
	///
	/// @param connector The transport to wrap; ownership is transferred (typically a
	///                  `MacOSBluetoothConnector`).
	BluetoothWrapper(std::unique_ptr<IBluetoothConnector> connector);

	BluetoothWrapper(const BluetoothWrapper&) = delete;
	BluetoothWrapper& operator=(const BluetoothWrapper&) = delete;

	/// Moves the connection, sequence counter and leftover-byte buffer to `other`.
	///
	/// @param other The wrapper to steal from; left without a transport.
	BluetoothWrapper(BluetoothWrapper&& other) noexcept;

	/// Replaces this wrapper's contents with `other`'s, dropping the current connection state.
	///
	/// @param other The wrapper to steal from.
	/// @return A reference to this wrapper (self-assignment is a no-op).
	BluetoothWrapper& operator=(BluetoothWrapper&& other) noexcept;

	/// Sends a fire-and-forget command and waits for the device's ACK.
	///
	/// Used for commands whose reply we don't read back (e.g. EQ/DSEE/NCASM SET).
	///
	/// @param bytes The raw command payload (first byte = command id), unframed.
	/// @return The number of bytes written to the socket.
	/// @throws RecoverableException If the framing is invalid or the checksum doesn't match.
	int sendCommand(const std::vector<char>& bytes);

	// Sends an inquiry command and returns the payload of the first DATA_MDR response whose command id
	// (payload[0]) matches retCommandId, skipping the ACK and any unrelated notifications. When retSubType
	// is >= 0, payload[1] must also match it (for multiplexed command families that share one opcode).
	/// Sends an inquiry (GET) command and blocks until the matching reply arrives.
	///
	/// @param bytes         The raw command payload (first byte = command id), unframed.
	/// @param retCommandId  The command id expected in `payload[0]` of the reply (e.g. `EQ_RET` for `EQ_GET`).
	/// @param retSubType    Optional sub-type that `payload[1]` must equal, for multiplexed families
	///                      such as the battery (0x00/0x09/0x0a) or button-mode (0x0a/0x0c) queries.
	///                      Pass -1 (the default) to ignore the second byte.
	/// @return The unescaped reply payload, including its command id.
	/// @throws RecoverableException If no matching response arrives within 16 frames - this is also how
	///         probing an unsupported feature reports "not supported" (the caller treats it as a timeout).
	Buffer sendCommandAndReadResponse(const std::vector<char>& bytes, unsigned char retCommandId, int retSubType = -1);

	/// Cheap liveness check forwarded to the transport.
	///
	/// @return True while the RFCOMM channel is open.
	bool isConnected() noexcept;

	//Try to connect to the headphones
	/// Opens the RFCOMM connection to the given device (blocking).
	///
	/// @param addr The colon-separated lowercase hex MAC address, e.g. "94:65:2d:1a:7c:01".
	/// @throws RecoverableException If no supported Sony service record was found; the message is
	///         meant to be shown in the UI.
	void connect(const std::string& addr);

	/// Closes the connection and resets the sequence counter and leftover-byte buffer. Never throws.
	void disconnect() noexcept;

	/// Lists the devices the platform offers for connecting.
	///
	/// @return Paired devices with name and MAC address; possibly empty.
	std::vector<BluetoothDevice> getConnectedDevices();

	//Only valid after a successful connect().
	/// Protocol generation selected while connecting (which Sony service UUID was found).
	///
	/// @return `SonyProtocolVersion::V1` or `::V2`; callers use it to pick opcode layouts.
	SonyProtocolVersion getProtocolVersion() noexcept;

private:
	/// Blocks until the next frame arrives and adopts its sequence number.
	/// @throws RecoverableException On a malformed frame or a checksum mismatch.
	void _waitForAck();

	//Reads and parses exactly one framed message from the connector (replaying buffered leftover bytes first).
	/// Reads one complete framed message from the socket and ACKs it if it carries device data.
	///
	/// Bytes past the END marker are kept in `_leftoverBytes` for the next call, because a single
	/// `recv()` can deliver several frames at once. Incoming `DATA_MDR` frames are acknowledged with
	/// the toggled sequence number so the device stops retransmitting them.
	///
	/// @return The parsed message (type, sequence number and unescaped payload).
	/// @throws RecoverableException On a framing or checksum error.
	CommandSerializer::Message _readMessage();

	std::unique_ptr<IBluetoothConnector> _connector;
	std::mutex _connectorMtx;
	unsigned int _seqNumber = 0;
	//Bytes read past the current message's END_MARKER in a single recv() call - a recv() can return more
	//than one framed message back-to-back, so these are replayed on the next _waitForAck() instead of dropped.
	Buffer _leftoverBytes;
};