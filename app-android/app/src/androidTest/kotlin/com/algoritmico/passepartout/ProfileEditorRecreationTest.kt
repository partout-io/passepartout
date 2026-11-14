// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
package com.algoritmico.passepartout

import android.os.Build
import android.view.KeyEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.partout.models.DNSModule
import io.partout.models.DNSModuleDomainPolicy
import io.partout.models.DNSModuleProtocolTypehttps
import io.partout.models.TaggedModuleDNS
import io.partout.models.TaggedModuleWireGuard
import io.partout.models.WireGuardModule
import io.partout.models.WireGuardConfiguration
import io.partout.models.WireGuardLocalInterface
import io.partout.models.CustomModule
import io.partout.models.ModuleType
import io.partout.models.TaggedModuleCustom
import kotlinx.serialization.json.JsonPrimitive
import io.partout.models.OpenVPNConfiguration
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import java.util.UUID
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProfileEditorRecreationTest {
    @Test
    fun draftAndVisibleEditorSurviveActivityRecreation() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val app = instrumentation.targetContext.applicationContext as PassepartoutApplication
        val profiles = app.appContext.profileObservable
        val id = UUID.randomUUID().toString()
        val moduleId = UUID.randomUUID().toString()
        val profile = TaggedProfile(id, "Recreation original", listOf(
            TaggedModuleCustom(CustomModule(ModuleType.Provider, JsonPrimitive("Custom configuration"))),
            TaggedModuleWireGuard(WireGuardModule(UUID.randomUUID().toString(),
                WireGuardConfiguration(WireGuardLocalInterface("dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo=", emptyList()), emptyList()))),
            TaggedModuleDNS(DNSModule(UUID.randomUUID().toString(),
                DNSModuleProtocolTypehttps("https://example.com/dns-query"), emptyList(),
                domainPolicy = DNSModuleDomainPolicy.matchAndSearch)),
            TaggedModuleOpenVPN(OpenVPNModule(moduleId, OpenVPNConfiguration(authUserPass = true, ca = "-----BEGIN CERTIFICATE-----\nNavigation test certificate\n-----END CERTIFICATE-----")))
        ), setOf(moduleId))
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            runBlocking { profiles.save(profile) }
            try {
                scenario.onActivity {
                    profiles.beginEditing(id)
                    val editor = requireNotNull(profiles.editor.value)
                    editor.rename("Unsaved recreation name")
                    editor.credentials(moduleId, "unsaved-user", "unsaved-password")
                }
                assertVisible("Unsaved recreation name")
                val originalSession = profiles.editor.value
                scenario.recreate()
                scenario.onActivity {
                    assertSame(originalSession, profiles.editor.value)
                    val draft = requireNotNull(profiles.editor.value).state.value
                    assertEquals("Unsaved recreation name", draft.name)
                    val credentials = draft.modules.filterIsInstance<TaggedModuleOpenVPN>().single().value.credentials
                    assertEquals("unsaved-user", credentials?.username)
                    assertEquals("unsaved-password", credentials?.password)
                    assertTrue(requireNotNull(profiles.editor.value).isDirty)
                    assertEquals(profile, profiles.profile(id))
                }
                assertVisible("Unsaved recreation name")
                scrollToText("WireGuard")
                clickText("WireGuard")
                assertVisible("hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo=")
                scenario.recreate()
                assertVisible("hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo=")
                pressBack()
                assertVisible("Unsaved recreation name")
                clickText("DNS")
                assertVisible(app.getString(R.string.modules_dns_policy_use_only))
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow,
                    app.getString(R.string.global_nouns_yes)))
                pressBack()
                assertVisible("Unsaved recreation name")
                clickText(app.getString(R.string.global_nouns_provider))
                assertVisible(app.getString(R.string.global_nouns_configuration))
                clickText(app.getString(R.string.global_nouns_configuration))
                assertVisible("Custom configuration")
                pressBack()
                assertVisible(app.getString(R.string.global_nouns_provider))
                assertVisible(app.getString(R.string.global_nouns_configuration))
                pressBack()
                assertVisible("Unsaved recreation name")
                clickText("OpenVPN")
                assertVisible(app.getString(R.string.modules_openvpn_credentials))
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow, "unsaved-user"))
                clickText(app.getString(R.string.modules_openvpn_credentials))
                assertVisible("unsaved-user")
                scenario.recreate()
                assertVisible("unsaved-user")
                pressBack()
                assertVisible(app.getString(R.string.modules_openvpn_credentials))
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow, "unsaved-user"))
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow, "Navigation test certificate"))
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow, "View content"))
                scrollToText("CA")
                clickText("CA")
                assertVisible("Navigation test certificate")
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow, "unsaved-user"))
                scenario.recreate()
                assertVisible("Navigation test certificate")
                pressBack()
                assertVisible(app.getString(R.string.modules_openvpn_credentials))
                clickText(app.getString(R.string.modules_openvpn_credentials))
                assertVisible("unsaved-user")
                assertFalse(contains(instrumentation.uiAutomation.rootInActiveWindow, "Navigation test certificate"))
                scenario.onActivity { profiles.endEditing() }
                scenario.recreate()
                scenario.onActivity { assertNull(profiles.editor.value) }
            } finally {
                scenario.onActivity { profiles.endEditing() }
                runBlocking { profiles.remove(id) }
            }
        }
    }

    private fun pressBack() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.uiAutomation.waitForIdle(500, 5000)
        instrumentation.sendKeyDownUpSync(KeyEvent.KEYCODE_BACK)
        instrumentation.uiAutomation.waitForIdle(500, 5000)
    }

    private fun scrollToText(text: String) {
        val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
        repeat(8) {
            if (find(automation.rootInActiveWindow, text)?.isVisibleToUser == true) return
            val node = scrollable(automation.rootInActiveWindow) ?: error("No scrollable list")
            node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)
            Thread.sleep(200)
        }
        fail("Missing row: $text")
    }

    private fun scrollable(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.isScrollable) return node
        return (0 until node.childCount).firstNotNullOfOrNull { scrollable(node.getChild(it)) }
    }

    private fun clickText(text: String) {
        InstrumentationRegistry.getInstrumentation().waitForIdleSync()
        val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
        automation.waitForIdle(500, 5000)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) automation.clearCache()
        var node = find(automation.rootInActiveWindow, text)
        while (node != null && !node.isClickable) node = node.parent
        assertTrue(requireNotNull(node).performAction(AccessibilityNodeInfo.ACTION_CLICK))
    }

    private fun assertVisible(text: String) {
        val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
        val deadline = System.currentTimeMillis() + 5000
        while (System.currentTimeMillis() < deadline) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) automation.clearCache()
            if (contains(automation.rootInActiveWindow, text)) return
            Thread.sleep(100)
        }
        fail("Editor text not visible after recreation: $text; visible: ${visibleText(automation.rootInActiveWindow)}")
    }

    private fun visibleText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""
        return listOfNotNull(node.text?.toString(), node.contentDescription?.toString()).joinToString(" | ") +
            (0 until node.childCount).joinToString(" | ") { visibleText(node.getChild(it)) }
    }

    private fun find(node: AccessibilityNodeInfo?, text: String): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.text?.contains(text) == true) return node
        return (0 until node.childCount).firstNotNullOfOrNull { find(node.getChild(it), text) }
    }

    private fun contains(node: AccessibilityNodeInfo?, text: String): Boolean =
        find(node, text) != null
}
