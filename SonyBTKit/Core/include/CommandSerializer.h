#pragma once
#include "Constants.h"
#include "ByteMagic.h"
#include <cstddef>
#include <vector>
#include <stdexcept>
#include "Exceptions.h"

/// Ambient-sound levels at or below this step can't use "focus on voice" (Sony's minimum).
constexpr int MINIMUM_VOICE_FOCUS_STEP = 2;
/// Sentinel level meaning "ambient sound disabled" (only meaningful on the v1 protocol).
constexpr unsigned int ASM_LEVEL_DISABLED = -1;

namespace CommandSerializer
{
	/// One unframed protocol message, as produced by ``unpackBtMessage``.
	struct Message
	{
		/// The frame's channel/type byte (ACK, DATA_MDR, ...).
		DATA_TYPE dataType;
		/// The 1-bit toggling sequence number used for the ACK/retransmit handshake.
		unsigned char seqNumber;
		Buffer payload; // command bytes (the <DATA> field), unescaped; empty for bare ACKs
	};

	//escape special chars

	/// Replaces every reserved byte (0x3C '<', 0x3D '=', 0x3E '>') with a sentry-escaped pair.
	///
	/// @param src The raw bytes to escape.
	/// @return A new buffer, at most twice as long as `src`.
	Buffer _escapeSpecials(const Buffer& src);

	/// Reverses ``_escapeSpecials``, restoring the reserved bytes.
	///
	/// @param src The escaped bytes as received over Bluetooth.
	/// @return The original unescaped buffer.
	/// @throws std::runtime_error If a sentry byte is the last byte of the input or is followed by
	///         an unknown escape code.
	Buffer _unescapeSpecials(const Buffer& src);

	/// Computes the additive 8-bit checksum over a raw byte range.
	///
	/// @param src  Pointer to the first byte.
	/// @param size Number of bytes to accumulate.
	/// @return The low 8 bits of the sum of every byte.
	unsigned char _sumChecksum(const char* src, size_t size);

	/// Computes the additive 8-bit checksum over a whole buffer.
	///
	/// @param src The bytes to accumulate.
	/// @return The low 8 bits of the sum of every byte.
	unsigned char _sumChecksum(const Buffer& src);

	//Package a serialized command according to the protocol
	/*
	References:
	* DataType
	* CommandBluetoothSender.sendCommandWithRetries
	* BluetoothSenderWrapper.sendCommandViaBluetooth
	* 
	* Serialized data format: <START_MARKER>ESCAPE_SPECIALS(<DATA_TYPE><SEQ_NUMBER><BIG ENDIAN 4 BYTE SIZE OF UNESCAPED DATA><DATA><1 BYTE CHECKSUM>)<END_MARKER>
	*/
	/// Wraps a command payload in a complete Bluetooth frame.
	///
	/// @param src       The command bytes (the <DATA> field), unescaped; may be empty (bare ACK).
	/// @param dataType  The channel/type byte, e.g. `DATA_TYPE::DATA_MDR` for commands or `DATA_TYPE::ACK`.
	/// @param seqNumber The 1-bit toggling sequence number for this frame.
	/// @return The framed, escaped and checksummed byte stream ready to be written to the socket.
	/// @throws std::runtime_error If the framed message exceeds `MAX_BLUETOOTH_MESSAGE_SIZE`
	///         (chunked messages are not implemented).
	Buffer packageDataForBt(const Buffer& src, DATA_TYPE dataType, unsigned int seqNumber);

	/// Parses one framed message received from the device.
	///
	/// @param src The bytes between the START and END markers, still escaped.
	/// @return The parsed type, sequence number and unescaped payload.
	/// @throws std::runtime_error If the message is shorter than the 7-byte header or the declared
	///         payload size exceeds the data actually received.
	/// @throws RecoverableException If the additive checksum doesn't match (with `shouldDisconnect`).
	Message unpackBtMessage(const Buffer& src);

	/// Maps an ambient-sound level to Sony's dual/single focus value.
	///
	/// @param asmLevel Ambient-sound level, 0..19 on v1 devices. 0 means DUAL, 1 means SINGLE,
	///                 anything else means OFF.
	/// @return The `NC_DUAL_SINGLE_VALUE` to place in the v1 NCASM frame.
	/// @throws std::runtime_error If `asmLevel` exceeds `MAX_STEPS_WH_1000_XM3` (19).
	NC_DUAL_SINGLE_VALUE getDualSingleForAsmLevel(char asmLevel);

	/// Serializes the v1 noise-cancelling / ambient-sound setting command (NCASM_SET_PARAM).
	///
	/// @param ncAsmEffect       Whether the NC/ASM effect is being applied or adjusted (`NC_ASM_EFFECT`).
	/// @param ncAsmSettingType  Which part of the setting changes: on/off, level, or dual/single.
	/// @param asmSettingType    Whether `asmLevel` carries an on/off flag or a level.
	/// @param asmId             Which ambient-sound curve to use: normal or voice focus.
	/// @param asmLevel          Ambient-sound level 0..19, or `ASM_LEVEL_DISABLED` when turning
	///                          ambient sound off.
	/// @return The 8-byte command payload, still unframed.
	Buffer serializeNcAndAsmSetting(NC_ASM_EFFECT ncAsmEffect, NC_ASM_SETTING_TYPE ncAsmSettingType, ASM_SETTING_TYPE asmSettingType, ASM_ID asmId, char asmLevel);

	//v2 protocol variant (WH-CH720N, XM5, newer XM4, etc) - different NCASM_SET_PARAM byte layout than v1.
	/// Serializes the v2 noise-cancelling / ambient-sound setting command.
	///
	/// The v2 layout (`68 17 01 ...`) differs from v1: there is no dual/single field, level is
	/// 1-based, and NC vs ambient-sound is selected by its own byte.
	///
	/// @param ncAsmEffect        `NC_ASM_EFFECT::ON` or `::OFF` (the on/off flag of the frame).
	/// @param ncAsmSettingType   `NOISE_CANCELLING` or `AMBIENT_SOUND` - which feature the level applies to.
	/// @param voicePassthrough   `ASM_ID::VOICE` for focus-on-voice, `ASM_ID::NORMAL` otherwise.
	/// @param asmLevel           Ambient-sound level; clamped to 1 by callers because v2 has no 0/disabled.
	/// @return The 7-byte command payload, still unframed.
	Buffer serializeNcAndAsmSettingV2(NC_ASM_EFFECT ncAsmEffect, NC_ASM_SETTING_TYPE_V2 ncAsmSettingType, ASM_ID voicePassthrough, char asmLevel);

	/// Serializes the v1-only surround/virtual-position setting command (VPT_SET_PARAM).
	///
	/// @param type   Which feature is being set: `VPT` (surround preset) or `SOUND_POSITION`.
	/// @param preset The preset id, e.g. a `VPT_PRESET_ID` or `SOUND_POSITION_PRESET` value;
	///               0 turns the feature off.
	/// @return The 3-byte command payload, still unframed.
	Buffer serializeVPTSetting(VPT_INQUIRED_TYPE type, unsigned char preset);
}
