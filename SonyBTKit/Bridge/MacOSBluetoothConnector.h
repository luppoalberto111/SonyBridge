#pragma once
#include <stdio.h>
#include "IBluetoothConnector.h"
#include "IOBluetooth/IOBluetooth.h"
#include "Constants.h"
#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <deque>
#include <future>

/// macOS implementation of ``IBluetoothConnector`` on top of IOBluetooth RFCOMM channels.
///
/// `connect()` spawns a background thread that opens the channel (trying the v1 Sony service UUID
/// first, then the v2 one) and then pumps the NSRunLoop for the lifetime of the connection. Received
/// frames are pushed into `receivedBytes` by an `IOBluetoothRFCOMMChannelDelegate` and consumed by
/// `recv()`.
class MacOSBluetoothConnector final : public IBluetoothConnector
{
public:
    MacOSBluetoothConnector();

    /// Disconnects if still connected, so no channel outlives the object.
    ~MacOSBluetoothConnector();

    /// Background thread body: resolves the device, finds the Sony SDP service record (v1 UUID first,
    /// v2 fallback), opens the RFCOMM channel, then pumps the run loop until disconnect.
    ///
    /// Called by ``connect``. Resolves `connectPromise` on success and stores the chosen
    /// `protocolVersion` before that, so the waiting thread can read it afterwards.
    ///
    /// @param macOSBluetoothConnector The connector to open the channel on (its `rfcommDevice` must
    ///                                already be set).
    /// @param connectPromise          Promise whose `set_value()` signals "channel open" and whose
    ///                                `set_exception()` reports a `RecoverableException` with
    ///                                user-facing text.
    /// @throws RecoverableException (via the promise) if no Sony service record exists, the record
    ///         has no RFCOMM channel, or the channel fails to open.
    static void connectToMac(MacOSBluetoothConnector* MacOSBluetoothConnector, std::promise<void> connectPromise) noexcept(false);

    /// Opens the RFCOMM connection to a paired device (blocking until the channel is open or failed).
    ///
    /// Also opens the base ACL link if macOS hasn't already. The v2 protocol generation is recorded
    /// here when only the v2 service UUID is found.
    ///
    /// @param addrStr Colon-separated lowercase MAC address, e.g. "94:65:2d:1a:7c:01".
    /// @throws RecoverableException (thrown from ``connectToMac``) with a user-facing message.
    virtual void connect(const std::string& addrStr) noexcept(false);

    /// Writes bytes to the RFCOMM channel synchronously.
    ///
    /// @param buf    Bytes to send.
    /// @param length Number of bytes at `buf`.
    /// @return Always `length` — the write is synchronous, so all bytes are on the wire on return.
    virtual int send(char* buf, size_t length) noexcept(false);

    /// Pops the next received chunk, blocking for up to 2.5 s for data.
    ///
    /// Leftover bytes from a chunk larger than `length` are pushed back for the next call.
    ///
    /// @param buf    Destination buffer, at least `length` bytes large.
    /// @param length Maximum number of bytes to copy.
    /// @return The number of bytes written into `buf`.
    /// @throws RecoverableException("recv timed out") when no data arrives in time — this is how
    ///         probing an unsupported feature reports "not supported".
    virtual int recv(char* buf, size_t length) noexcept(false);

    /// Closes the RFCOMM channel, wakes the background thread and joins it. Never throws.
    virtual void disconnect() noexcept;

    /// Cheap, thread-safe liveness check.
    ///
    /// @return YES while the background thread is running and the channel reports itself open.
    virtual bool isConnected() noexcept;

    /// Closes the RFCOMM channel itself (clears the delegate first) without stopping the thread.
    /// Called from ``disconnect`` before `running` is cleared.
    virtual void closeConnection();

    /// The protocol generation resolved during ``connect``.
    ///
    /// @return `SonyProtocolVersion::V1` or `::V2`; V1 until a connection succeeded.
    virtual SonyProtocolVersion getProtocolVersion() noexcept;

    /// Lists every paired device (not only those macOS reports as connected).
    ///
    /// Headsets connected for audio/BLE only report `isConnected == NO`, but `connect()` opens RFCOMM
    /// on demand, so paired-but-"disconnected" devices are included deliberately.
    ///
    /// @return Devices with UTF-8 name (or "Unknown Device") and MAC address.
    virtual std::vector<BluetoothDevice> getConnectedDevices() noexcept(false);

    /// Chunks received from the RFCOMM delegate, in arrival order; consumed by ``recv``.
    std::deque<std::vector<unsigned char>> receivedBytes;
    /// Guards `receivedBytes`.
    std::mutex receiveDataMutex;
    /// Signalled by the delegate whenever a chunk is queued.
    std::condition_variable receiveDataConditionVariable;
    /// True between a successful ``connectToMac`` and ``disconnect``; watched by the background thread.
    std::atomic<bool> running = false;
    /// Guards `running` for the background thread's condition-variable wait.
    std::mutex disconnectionMutex;
    /// Signalled by ``disconnect`` to wake the background thread so it can exit.
    std::condition_variable disconnectionConditionVariable;
    //Set on the connectToMac background thread before the connect promise resolves; safe to read from
    //any thread afterwards (the future's get() synchronizes-with the promise's set_value()).
    /// Which Sony service UUID was found while connecting; written before the connect promise resolves.
    SonyProtocolVersion protocolVersion = SonyProtocolVersion::V1;

private:
    void *rfcommDevice;   ///< Retained `IOBluetoothDevice *` for the pending/active connection.
    void *rfcommchannel;  ///< `IOBluetoothRFCOMMChannel *` of the open channel.
    std::thread uthread;  ///< Background thread running ``connectToMac`` (run-loop pump).
};
