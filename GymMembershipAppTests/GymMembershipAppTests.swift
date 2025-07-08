//
//  GymMembershipAppTests.swift
//  GymMembershipAppTests
//
//  Created by imac4 on 09/05/2025.
//

import Testing
@testable import GymMembershipApp

struct GymMembershipAppTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testCopilotUsageModel() async throws {
        // Test CopilotUsage model initialization and formatting
        let usage = CopilotUsage(
            id: 1,
            userId: 123,
            interactionType: "workout_suggestion",
            timestamp: "2025-07-08T10:30:00Z",
            duration: 65,
            satisfied: true,
            feedback: "Great suggestions!"
        )
        
        #expect(usage.id == 1)
        #expect(usage.interactionType == "workout_suggestion")
        #expect(usage.formattedDuration == "1m 5s")
        #expect(usage.satisfied == true)
    }
    
    @Test func testCopilotUsageStats() async throws {
        // Test CopilotUsageStats model formatting
        let stats = CopilotUsageStats(
            totalInteractions: 25,
            totalDuration: 3665, // 1 hour, 1 minute, 5 seconds
            averageDuration: 146.6,
            satisfactionRate: 0.88,
            mostUsedFeature: "workout_suggestion",
            thisWeekInteractions: 5,
            thisMonthInteractions: 15
        )
        
        #expect(stats.totalInteractions == 25)
        #expect(stats.formattedTotalDuration == "1h 1m")
        #expect(stats.formattedSatisfactionRate == "88.0%")
        #expect(stats.mostUsedFeature == "workout_suggestion")
    }

}
