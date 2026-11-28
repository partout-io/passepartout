// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.models.expandZipEntries
import com.algoritmico.passepartout.business.models.isZipInput
import com.algoritmico.passepartout.models.AppErrorCode
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.asAppError
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class ProfileImporterInputUnitTest {
    @Test
    fun expandZipEntries_filtersJunkAndPreservesValidEntries() {
        val zipBytes = buildZip(
            ZipSpec("a.ovpn", "client\ndev tun".toByteArray(Charsets.UTF_8)),
            ZipSpec("sub/b.conf", "[Interface]".toByteArray(Charsets.UTF_8)),
            ZipSpec("win\\C.JSON", "{\"name\":\"test\"}".toByteArray(Charsets.UTF_8)),
            ZipSpec("readme.txt", "hello".toByteArray(Charsets.UTF_8)),
            ZipSpec(".DS_Store", ByteArray(0)),
            ZipSpec("__MACOSX/", ByteArray(0), isDirectory = true),
            ZipSpec("__MACOSX/._a.ovpn", "\u0000\u0005\u0016\u0007Mac OS X".toByteArray(Charsets.UTF_8)),
            ZipSpec("._b.conf", "\u0000\u0005\u0016\u0007Mac OS X".toByteArray(Charsets.UTF_8)),
            ZipSpec("nested.zip", buildZip(ZipSpec("inner.ovpn", "client".toByteArray(Charsets.UTF_8))))
        )

        val expanded = expandZipEntries(ByteArrayInputStream(zipBytes), "Test")

        assertEquals(listOf("a.ovpn", "b.conf", "C.JSON"), expanded.map { it.filename })
        assertEquals(listOf("client\ndev tun", "[Interface]", "{\"name\":\"test\"}"), expanded.map { it.data })
        assertTrue(expanded.all { it.isFromArchive })
    }

    @Test
    fun expandZipEntries_junkOnlyThrowsImportError() {
        val zipBytes = buildZip(
            ZipSpec("readme.txt", "hello".toByteArray(Charsets.UTF_8)),
            ZipSpec(".DS_Store", ByteArray(0)),
            ZipSpec("__MACOSX/._a.ovpn", "meta".toByteArray(Charsets.UTF_8)),
            ZipSpec("nested.zip", ByteArray(0))
        )

        val error = assertThrows(ProfileImporterException.Failure::class.java) {
            expandZipEntries(ByteArrayInputStream(zipBytes), "Test")
        }
        assertNull(error.cause)
        assertEquals(AppErrorCode.importError, error.asAppError.code)
    }

    @Test
    fun expandZipEntries_emptyArchiveThrowsImportError() {
        val zipBytes = buildZip()

        val error = assertThrows(ProfileImporterException.Failure::class.java) {
            expandZipEntries(ByteArrayInputStream(zipBytes), "Test")
        }
        assertNull(error.cause)
        assertEquals(AppErrorCode.importError, error.asAppError.code)
    }

    @Test
    fun expandZipEntries_corruptAndTruncatedStreamsThrowImportError() {
        val validZip = buildZip(ZipSpec("a.ovpn", "client\ndev tun\nremote example.com".toByteArray(Charsets.UTF_8)))
        val truncatedZip = validZip.copyOf(validZip.size / 2)
        val nonZip = "not a zip archive".toByteArray(Charsets.UTF_8)

        for (bytes in listOf(nonZip, truncatedZip)) {
            val error = assertThrows(ProfileImporterException.Failure::class.java) {
                expandZipEntries(ByteArrayInputStream(bytes), "Test")
            }
            assertNull(error.cause)
            assertEquals(AppErrorCode.importError, error.asAppError.code)
        }
    }

    @Test
    fun expandZipEntries_encryptedEntryThrowsImportError() {
        val zipBytes = buildZip(ZipSpec("secret.ovpn", "client".toByteArray(Charsets.UTF_8)))
        // Bit 0 of local file header general-purpose bit flag (offset 6) marks encryption.
        zipBytes[6] = (zipBytes[6].toInt() or 0x01).toByte()

        val error = assertThrows(ProfileImporterException.Failure::class.java) {
            expandZipEntries(ByteArrayInputStream(zipBytes), "Test")
        }
        assertNull(error.cause)
        assertEquals(AppErrorCode.importError, error.asAppError.code)
    }

    @Test
    fun expandZipEntries_oversizedEntryIsSkippedOrThrowsWhenNoneLeft() {
        val oversized = ByteArray(1_000_001) { 'A'.code.toByte() }

        val deflatedAlone = buildZip(ZipSpec("huge.ovpn", oversized))
        assertThrows(ProfileImporterException.Failure::class.java) {
            expandZipEntries(ByteArrayInputStream(deflatedAlone), "Test")
        }

        val storedAlone = buildZip(ZipSpec("huge.ovpn", oversized, stored = true))
        assertThrows(ProfileImporterException.Failure::class.java) {
            expandZipEntries(ByteArrayInputStream(storedAlone), "Test")
        }

        val mixed = buildZip(
            ZipSpec("huge.ovpn", oversized),
            ZipSpec("valid.ovpn", "client".toByteArray(Charsets.UTF_8))
        )
        val expanded = expandZipEntries(ByteArrayInputStream(mixed), "Test")
        assertEquals(listOf("valid.ovpn"), expanded.map { it.filename })

        val exactBoundary = ByteArray(1_000_000) { 'A'.code.toByte() }
        val boundaryZip = buildZip(ZipSpec("exact.ovpn", exactBoundary))
        val boundaryExpanded = expandZipEntries(ByteArrayInputStream(boundaryZip), "Test")
        assertEquals(listOf("exact.ovpn"), boundaryExpanded.map { it.filename })
        assertEquals(1_000_000, boundaryExpanded.single().data.length)
    }

    @Test
    fun expandZipEntries_invalidUtf8EntryIsSkippedOrThrowsWhenNoneLeft() {
        val invalidBytes = byteArrayOf(0xFF.toByte(), 0xFE.toByte(), 0x00)
        val invalidAlone = buildZip(ZipSpec("broken.ovpn", invalidBytes))
        val error = assertThrows(ProfileImporterException.Failure::class.java) {
            expandZipEntries(ByteArrayInputStream(invalidAlone), "Test")
        }
        assertNull(error.cause)
        assertEquals(AppErrorCode.importError, error.asAppError.code)

        val mixed = buildZip(
            ZipSpec("broken.ovpn", invalidBytes),
            ZipSpec("good.conf", "[Interface]".toByteArray(Charsets.UTF_8))
        )
        val expanded = expandZipEntries(ByteArrayInputStream(mixed), "Test")
        assertEquals(listOf("good.conf"), expanded.map { it.filename })
    }

    @Test
    fun isZipInput_detectsByDisplayNameLastSegmentOrMimeType() {
        assertTrue(isZipInput("profiles.zip", null))
        assertTrue(isZipInput("PROFILES.ZIP", "application/octet-stream"))
        assertTrue(isZipInput(null, "application/zip"))
        assertTrue(isZipInput(null, "application/x-zip-compressed"))
        assertTrue(isZipInput(null, null, "bundle.zip"))
        assertFalse(isZipInput("profile.ovpn", "application/x-openvpn-profile", "profile.ovpn"))
        assertFalse(isZipInput("profile.conf", "text/plain", "profile.conf"))
        assertFalse(isZipInput("profile.json", "application/json", "profile.json"))
    }

    private data class ZipSpec(
        val path: String,
        val bytes: ByteArray,
        val isDirectory: Boolean = false,
        val stored: Boolean = false
    )

    private fun buildZip(vararg entries: ZipSpec): ByteArray {
        val output = ByteArrayOutputStream()
        ZipOutputStream(output).use { zip ->
            for (spec in entries) {
                val entry = ZipEntry(spec.path)
                if (!spec.isDirectory && spec.stored) {
                    entry.method = ZipEntry.STORED
                    entry.size = spec.bytes.size.toLong()
                    entry.compressedSize = spec.bytes.size.toLong()
                    val crc = CRC32()
                    crc.update(spec.bytes)
                    entry.crc = crc.value
                }
                zip.putNextEntry(entry)
                if (!spec.isDirectory) {
                    zip.write(spec.bytes)
                }
                zip.closeEntry()
            }
        }
        return output.toByteArray()
    }
}
