// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import kotlinx.coroutines.CancellationException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class HelpersUnitTest {
    @Test
    fun runCatchingNonFatal_runsChainedCleanupBeforeRethrowingFatalError() {
        val error = LinkageError("fatal")
        var didCleanUp = false

        val thrown = assertThrows(LinkageError::class.java) {
            runCatchingNonFatal<Unit> {
                throw error
            }.also {
                didCleanUp = true
            }.getOrElse {
                fail("fatal errors must not be recoverable")
            }
        }

        assertSame(error, thrown)
        assertTrue(didCleanUp)
    }

    @Test
    fun runCatchingNonFatal_runsChainedCleanupBeforeRethrowingCancellation() {
        val error = CancellationException("cancelled")
        var didCleanUp = false

        val thrown = assertThrows(CancellationException::class.java) {
            runCatchingNonFatal<Unit> {
                throw error
            }.also {
                didCleanUp = true
            }.onFailure {
                fail("cancellation must not be recoverable")
            }
        }

        assertSame(error, thrown)
        assertTrue(didCleanUp)
    }

    @Test
    fun runCatchingNonFatal_doesNotRethrowFromOnSuccessBeforeChainedCleanup() {
        val error = LinkageError("fatal")
        var didCleanUp = false

        val thrown = assertThrows(LinkageError::class.java) {
            runCatchingNonFatal<Unit> {
                throw error
            }.onSuccess {
                fail("fatal errors must not be successful")
            }.also {
                didCleanUp = true
            }.getOrThrow()
        }

        assertSame(error, thrown)
        assertTrue(didCleanUp)
    }

    @Test
    fun runCatchingNonFatal_recoversFromNonFatalExceptions() {
        var didCleanUp = false
        var didRecover = false

        val value = runCatchingNonFatal<Int> {
            throw IllegalStateException("non-fatal")
        }.also {
            didCleanUp = true
        }.getOrElse {
            didRecover = true
            42
        }

        assertEquals(42, value)
        assertTrue(didCleanUp)
        assertTrue(didRecover)
    }
}
