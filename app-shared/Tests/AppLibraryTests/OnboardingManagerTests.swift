// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
@testable import CommonLibrary
import Foundation
import Testing

@MainActor
struct OnboardingManagerTests {
    @Test
    func test_givenStep_whenOrder_thenIsExpected() {
        #expect(ABI.OnboardingStep.community.order == 0)
        #expect(ABI.OnboardingStep.doneV3.order == 1)
        #expect(ABI.OnboardingStep.migrateV3_2_3.order == 2)
        #expect(ABI.OnboardingStep.doneV3_2_3.order == 3)
        #expect(ABI.OnboardingStep.migrateV3_5_15.order == 4)
        #expect(ABI.OnboardingStep.doneV3_5_15.order == 5)
    }

    @Test
    func givenNil_whenAdvance_thenAdvancesToNext() {
        let sut = OnboardingManager() // .community
        sut.advance()
        #expect(sut.step == .doneV3)
    }

    @Test
    func givenMid_whenAdvance_thenAdvancesToNext() {
        let sut = OnboardingManager(initialStep: .migrateV3_2_3)
        sut.advance()
        #expect(sut.step == .doneV3_2_3)
    }

    @Test
    func givenMid_whenAdvanceFromV2_thenSkipsV323Migration() {
        let sut = OnboardingManager(initialStep: .first) // .community
        #expect(sut.step == .community)
        sut.advance() // .doneV3
        sut.advance() // .migrateV3_2_3 (skipped to .doneV3_6)
        #expect(sut.step == .doneV3_5_15)
    }

    @Test
    func givenMid_whenAdvanceFromV3_thenAdvancesToV323Migration() {
        let sut = OnboardingManager(initialStep: .doneV3)
        sut.advance()
        #expect(sut.step == .migrateV3_2_3)
        sut.advance()
        #expect(sut.step == .doneV3_2_3)
    }

    @Test
    func givenLast_whenAdvance_thenDoesNotAdvance() {
        let sut = OnboardingManager(initialStep: .doneV3_5_18)
        #expect(sut.step == .last)
        sut.advance()
        #expect(sut.step == .doneV3_5_18)
    }
}
