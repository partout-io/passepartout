// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !USE_CMAKE
#if PSP_PROVIDERS
@_exported import CommonProviders
#endif
// FIXME: #1594, Fine-tune this export because app-apple should stop using Partout directly
@_exported import Partout
#endif
