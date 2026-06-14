// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.extensions

import com.algoritmico.passepartout.abi.models.DistributionTarget

val DistributionTarget.canAlwaysReportIssue: Boolean
    get() = this == DistributionTarget.enterprise

val DistributionTarget.supportsAppGroups: Boolean
    get() = this != DistributionTarget.developerID

val DistributionTarget.supportsCloudKit: Boolean
    get() = this != DistributionTarget.developerID

val DistributionTarget.supportsIAP: Boolean
    get() = this == DistributionTarget.appStore

val DistributionTarget.supportsPaidFeatures: Boolean
    get() = this != DistributionTarget.developerID
