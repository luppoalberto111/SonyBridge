#pragma once

#include <vector>
#include <string>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <stdexcept>
#include "Constants.h"

/// Byte-swaps a 32-bit value between little and big endian (an involution).
///
/// @param num The value to swap.
/// @return `num` with its four bytes reversed, e.g. 0x11223344 becomes 0x44332211.
unsigned int byteOrderSwap(unsigned int num);

/// Splits an int into its big endian bytes.
///
/// The Sony protocol transmits 4-byte lengths big endian (see
/// `CommandSerializer::packageDataForBt`), so this is the length encoder.
///
/// @param num The value to encode.
/// @return A 4-element vector of bytes, most significant byte first.
std::vector<unsigned char> intToBytesBE(unsigned int num);

/// Parses a textual Bluetooth MAC address into its numeric form.
///
/// @param str The address as ASCII hex bytes separated by '-' or ':', exactly
///            `MAC_ADDR_STR_SIZE` (17) characters long, e.g. "94:65:2d:1a:7c:01".
/// @return The 48-bit address packed with the first textual byte in the most significant position.
/// @throws std::runtime_error If the string has the wrong length or contains an invalid separator/character.
long long MACStringToLong(const std::string& str);

/// Formats 6 raw MAC bytes as a printable "xx:xx:xx:xx:xx:xx" string.
///
/// @param addr Pointer to at least `MAC_ADDR_BYTES_LEN` (6) bytes, ordered least significant
///            byte first (the in-memory layout the Bluetooth stack hands us); the returned
///            string puts the most significant byte first.
/// @return Lowercase hex string with ':' separators and no trailing separator.
std::string MACBytesToString(unsigned char addr[]);
