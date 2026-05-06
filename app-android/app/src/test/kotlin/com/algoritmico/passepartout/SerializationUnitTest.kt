package com.algoritmico.passepartout

import com.algoritmico.passepartout.helpers.globalJsonCoder
import io.partout.abi.DNSModuleProtocolType
import io.partout.abi.DNSModuleProtocolTypecleartext
import io.partout.abi.DNSModuleProtocolTypehttps
import io.partout.abi.DNSModuleProtocolTypetls
import io.partout.abi.OpenVPNObfuscationMethod
import io.partout.abi.OpenVPNObfuscationMethodobfuscate
import io.partout.abi.OpenVPNObfuscationMethodreverse
import io.partout.abi.OpenVPNObfuscationMethodxormask
import io.partout.abi.OpenVPNObfuscationMethodxorptrpos
import kotlinx.serialization.json.encodeToJsonElement
import org.junit.Assert.*
import org.junit.Test
import java.util.Base64

/**
 * Example local unit test, which will execute on the development machine (host).
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
class SerializationUnitTest {
    val dnsProtocolsJSON = """
[{"type":"cleartext"},{"type":"https","url":"https://www.google.com"},{"type":"tls","hostname":"google.com"}]
""".trimIndent()

    val obfMaskBase64 = "AQIDBAUG"
    val obfMaskBytes = Base64.getDecoder().decode(obfMaskBase64)
    val obfMethodsJSON = """
[{"type":"xormask","mask":"AQIDBAUG"},{"type":"xorptrpos"},{"type":"reverse"},{"type":"obfuscate","mask":"AQIDBAUG"}]
""".trimIndent()

    @Test
    fun dnsProtocolType_isDeserialized() {
        val dnsProtocols = globalJsonCoder.decodeFromString<List<DNSModuleProtocolType>>(dnsProtocolsJSON)
        assertEquals(dnsProtocols.size, 3)
        assert(dnsProtocols[0] is DNSModuleProtocolTypecleartext)
        val https = dnsProtocols[1] as DNSModuleProtocolTypehttps
        assertEquals(https.url, "https://www.google.com")
        val tls = dnsProtocols[2] as DNSModuleProtocolTypetls
        assertEquals(tls.hostname, "google.com")
    }

    @Test
    fun dnsProtocolType_isSerialized() {
        val clear = DNSModuleProtocolTypecleartext()
        val https = DNSModuleProtocolTypehttps(url = "https://www.google.com")
        val tls = DNSModuleProtocolTypetls(hostname = "google.com")
        val dnsProtocols = listOf(clear, https, tls)
        val json = globalJsonCoder.encodeToJsonElement(dnsProtocols).toString().trimIndent()
        println(json)
        println(dnsProtocolsJSON)
        assertEquals(json, dnsProtocolsJSON)
    }

    @Test
    fun obfMethod_isDeserialized() {
        val obfMethods = globalJsonCoder.decodeFromString<List<OpenVPNObfuscationMethod>>(obfMethodsJSON)
        assertEquals(obfMethods.size, 4)
        val xormask = obfMethods[0] as OpenVPNObfuscationMethodxormask
        assertTrue(xormask.mask.contentEquals(obfMaskBase64))
        assert(obfMethods[1] is OpenVPNObfuscationMethodxorptrpos)
        assert(obfMethods[2] is OpenVPNObfuscationMethodreverse)
        val obfuscate = obfMethods[3] as OpenVPNObfuscationMethodobfuscate
        assertTrue(obfuscate.mask.contentEquals(obfMaskBase64))
    }

    @Test
    fun obfMethod_isSerialized() {
        val xormask = OpenVPNObfuscationMethodxormask(mask = obfMaskBase64)
        val xorptrpos = OpenVPNObfuscationMethodxorptrpos()
        val reverse = OpenVPNObfuscationMethodreverse()
        val obfuscate = OpenVPNObfuscationMethodobfuscate(mask = obfMaskBase64)
        val obfMethods = listOf(xormask, xorptrpos, reverse, obfuscate)
        val json = globalJsonCoder.encodeToJsonElement(obfMethods).toString().trimIndent()
        println(json)
        println(obfMethodsJSON)
        assertEquals(json, obfMethodsJSON)
    }
}