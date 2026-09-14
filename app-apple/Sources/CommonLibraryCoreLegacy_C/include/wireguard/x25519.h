/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2018-2025 WireGuard LLC. All Rights Reserved.
 */

#pragma once

void curve25519_derive_public_key(unsigned char public_key[32], const unsigned char private_key[32]);
void curve25519_generate_private_key(unsigned char private_key[32]);
