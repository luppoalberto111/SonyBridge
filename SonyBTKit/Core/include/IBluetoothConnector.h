#pragma once
#include <string>
#include <vector>
#include "Exceptions.h"
#include "Constants.h"

inline constexpr auto SONY_UUID = "96CC203E-5068-46ad-B32D-E316F5E069BA";
// Second-generation Sony protocol UUID - see SERVICE_UUID_V2 in Constants.h for the byte-array form.
inline constexpr auto SONY_UUID_V2 = "956C7B26-D49A-4BA8-B03F-B17D393CB6E2";

inline constexpr auto NO_BLUETOOTH_DEVICES_ERROR = "No Bluetooth radios were found - is your adapter connected?";

/// A Bluetooth device as returned by ``IBluetoothConnector::getConnectedDevices``.
struct BluetoothDevice
{
	//UTF-8
	std::string name; ///< Human-readable device name, UTF-8 ("Unknown Device" when the stack reports none).
	std::string mac;  ///< Colon-separated lowercase hex address, e.g. "94:65:2d:1a:7c:01".
};

/*
General notes: Please look at the implementation of WindowsBluetoothConnector.
* Functions should throw RecoverableExceptions if they're indeed recoverable, and throw std::runtime_error otherwise.
* RecoverableException can force a disconnection of the socket with an additional param (a call to disconnect()).
* connect() should try the v1 service UUID (SONY_UUID) first and fall back to the v2 UUID (SONY_UUID_V2)
* if no v1 SDP service record is found, recording which one succeeded for getProtocolVersion().
* See notes below
*/

//Thread-safety: IBluetoothConnector implementations don't need to be thread safe, except calls to isConnected;
/// Transport abstraction so the protocol core stays platform independent.
///
/// Implemented for macOS by `MacOSBluetoothConnector` (IOBluetooth RFCOMM).
class IBluetoothConnector
{
public:
	IBluetoothConnector() = default;
	virtual ~IBluetoothConnector() = default;

	IBluetoothConnector(const IBluetoothConnector&) = delete;
	IBluetoothConnector& operator=(const IBluetoothConnector&) = delete;

	//send, recv and connect can block.
	//O: The number of bytes sent.
	/// Writes a block of bytes to the Bluetooth socket.
	///
	/// @param buf    Pointer to the bytes to send.
	/// @param length Number of bytes at `buf`.
	/// @return The number of bytes actually sent (always `length` for the current implementations).
	/// @throws RecoverableException For a recoverable link error, std::runtime_error otherwise.
	virtual int send(char* buf, size_t length) noexcept(false) = 0;

	/// Reads up to `length` bytes from the Bluetooth socket, blocking until data arrives.
	///
	/// Implementations should time out rather than block forever, so that an inquiry the device
	/// doesn't answer (or a dropped link) surfaces as a thrown exception instead of a hang.
	///
	/// @param buf    Destination buffer, at least `length` bytes large.
	/// @param length Maximum number of bytes to copy.
	/// @return The number of bytes written into `buf`; any overflow is kept for the next call.
	/// @throws RecoverableException On a timeout ("recv timed out") or link error.
	virtual int recv(char* buf, size_t length) noexcept(false) = 0;

	/// Opens the RFCOMM connection to a paired device and starts the receive thread.
	///
	/// Should try the v1 service UUID first and fall back to the v2 UUID, recording the result for
	/// ``getProtocolVersion``.
	///
	/// @param addrStr The colon-separated lowercase hex MAC address, e.g. "94:65:2d:1a:7c:01".
	/// @throws RecoverableException If the device has no supported Sony service record; the message
	///         is written for display in the UI.
	virtual void connect(const std::string& addrStr) noexcept(false) = 0;
	
	//This function should not block.
	/// Closes the connection and stops the receive thread. Never throws.
	virtual void disconnect() noexcept = 0;
	
	//Cost directive: This function must be as cheap as possible.
	//!!! Thread-safety: This function must be thread safe. !!!
	/// Cheap, thread-safe liveness check used by the UI watchdog.
	///
	/// @return True while the socket is open and the receive thread is running.
	virtual bool isConnected() noexcept = 0;

	//getConnectedDevices can block.
	/// Lists the devices to offer for connecting (paired devices on macOS, regardless of whether
	/// macOS currently reports them as connected - audio/BLE-only links still work).
	///
	/// @return The list of devices; may be empty, never throws for an empty system list.
	/// @throws RecoverableException If no Bluetooth radio is available (`NO_BLUETOOTH_DEVICES_ERROR`).
	virtual std::vector<BluetoothDevice> getConnectedDevices() = 0;

	//Only valid after a successful connect(). Reflects which service UUID (SONY_UUID vs SONY_UUID_V2) was used.
	/// The protocol generation selected at connect time; guards every v2-only opcode so they are
	/// never sent to a v1 device (e.g. 0x22 would be POWER_OFF there).
	///
	/// @return `SonyProtocolVersion::V1` or `::V2`; V1 before a successful connect.
	virtual SonyProtocolVersion getProtocolVersion() noexcept = 0;
};
