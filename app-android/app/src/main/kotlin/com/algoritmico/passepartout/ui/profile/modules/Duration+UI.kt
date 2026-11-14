// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.profile.modules

import android.icu.text.MeasureFormat
import android.icu.util.Measure
import android.icu.util.MeasureUnit
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R

@Composable
internal fun Double?.durationText(): String? {
    val seconds = this ?: return null
    if (seconds <= 0) return stringResource(R.string.global_nouns_disabled)
    val total = seconds.toLong()
    val hours = total / 3600
    val minutes = total % 3600 / 60
    val remainder = total % 60
    val measures = listOfNotNull(
        hours.takeIf { it > 0 }?.let { Measure(it, MeasureUnit.HOUR) },
        minutes.takeIf { it > 0 }?.let { Measure(it, MeasureUnit.MINUTE) },
        remainder.takeIf { it > 0 || total == 0L }?.let { Measure(it, MeasureUnit.SECOND) }
    )
    val locale = LocalConfiguration.current.locales[0]
    return MeasureFormat.getInstance(locale, MeasureFormat.FormatWidth.SHORT)
        .formatMeasures(*measures.toTypedArray())
}
