// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
@testable import CommonLibrary
import Foundation
import Testing

@MainActor
struct OnboardingObservableTests {
    @Test
    func test_givenStep_whenOrder_thenIsExpected() {
        #expect(OnboardingStep.community.order == 0)
        #expect(OnboardingStep.doneV3.order == 1)
        #expect(OnboardingStep.migrateV3_2_3.order == 2)
        #expect(OnboardingStep.doneV3_2_3.order == 3)
        #expect(OnboardingStep.migrateV3_5_15.order == 4)
        #expect(OnboardingStep.doneV3_5_15.order == 5)
    }

    @Test
    func givenNil_whenAdvance_thenAdvancesToNext() {
        let sut = OnboardingObservable() // .community
        sut.advance()
        #expect(sut.step == .doneV3)
    }

    @Test
    func givenMid_whenAdvance_thenAdvancesToNext() {
        let sut = OnboardingObservable(initialStep: .migrateV3_2_3)
        sut.advance()
        #expect(sut.step == .doneV3_2_3)
    }

    @Test
    func givenMid_whenAdvanceFromV2_thenSkipsV323Migration() {
        let sut = OnboardingObservable(initialStep: .first) // .community
        #expect(sut.step == .community)
        sut.advance() // .doneV3
        sut.advance() // .migrateV3_2_3 (skipped to .doneV3_6)
        #expect(sut.step == .doneV3_5_15)
    }

    @Test
    func givenMid_whenAdvanceFromV3_thenAdvancesToV323Migration() {
        let sut = OnboardingObservable(initialStep: .doneV3)
        sut.advance()
        #expect(sut.step == .migrateV3_2_3)
        sut.advance()
        #expect(sut.step == .doneV3_2_3)
    }

    @Test
    func givenLast_whenAdvance_thenDoesNotAdvance() {
        let sut = OnboardingObservable(initialStep: .doneV3_5_18)
        #expect(sut.step == .last)
        sut.advance()
        #expect(sut.step == .doneV3_5_18)
    }
}
