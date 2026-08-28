import Foundation
import Testing
@testable import WorklogCore

struct ActivityAggregationTests {
    @Test
    func groupsChromeSegmentsByHostAndClassification() {
        let start = Date(timeIntervalSince1970: 1_000)
        let segments = [
            classifiedSegment(
                start: start,
                duration: 60,
                url: "https://example.com/first",
                kind: .work
            ),
            classifiedSegment(
                start: start.addingTimeInterval(120),
                duration: 90,
                url: "https://example.com/second",
                kind: .work
            ),
            classifiedSegment(
                start: start.addingTimeInterval(240),
                duration: 30,
                url: "https://example.com/personal",
                kind: .personal
            )
        ]

        let groups = ActivityAggregation.groups(from: segments)
            .sorted { $0.kind.rawValue < $1.kind.rawValue }

        #expect(groups.count == 2)
        #expect(groups[0].name == "example.com")
        #expect(groups[0].duration == 30)
        #expect(groups[0].segmentCount == 1)
        #expect(groups[0].segmentIDs.count == 1)
        #expect(groups[1].name == "example.com")
        #expect(groups[1].duration == 150)
        #expect(groups[1].segmentCount == 2)
        #expect(groups[1].segmentIDs.count == 2)
    }

    @Test
    func groupsMacSegmentsByApp() {
        let start = Date(timeIntervalSince1970: 2_000)
        let segments = [
            classifiedSegment(start: start, duration: 45, appName: "Xcode"),
            classifiedSegment(start: start.addingTimeInterval(60), duration: 75, appName: "Xcode")
        ]

        let group = ActivityAggregation.groups(from: segments).first

        #expect(group?.name == "Xcode")
        #expect(group?.duration == 120)
        #expect(group?.segmentCount == 2)
    }

    @Test
    func recordsAllAppliedRulesForAGroupWithoutDuplicates() {
        let start = Date(timeIntervalSince1970: 3_000)
        let firstRuleID = UUID()
        let secondRuleID = UUID()
        let segments = [
            classifiedSegment(start: start, duration: 30, ruleID: firstRuleID),
            classifiedSegment(start: start.addingTimeInterval(60), duration: 30, ruleID: firstRuleID),
            classifiedSegment(start: start.addingTimeInterval(120), duration: 30, ruleID: secondRuleID)
        ]

        let group = ActivityAggregation.groups(from: segments).first

        #expect(group?.appliedRuleIDs == [firstRuleID, secondRuleID])
    }

    private func classifiedSegment(
        start: Date,
        duration: TimeInterval,
        appName: String = "Google Chrome",
        url: String? = nil,
        kind: ActivityKind = .work,
        ruleID: UUID? = nil
    ) -> ClassifiedSegment {
        let segment = ActivitySegment(
            startedAt: start,
            endedAt: start.addingTimeInterval(duration),
            snapshot: ActivitySnapshot(
                appName: appName,
                bundleIdentifier: "test.\(appName)",
                processIdentifier: 1,
                windowTitle: "Test",
                url: url,
                source: url == nil ? .macOS : .chrome
            )
        )

        return ClassifiedSegment(
            segment: segment,
            classification: SegmentClassification(
                segmentID: segment.id,
                kind: kind,
                categoryID: nil,
                projectID: nil,
                ruleID: ruleID,
                isManual: false
            ),
            projectName: nil,
            categoryName: nil,
            ruleName: nil
        )
    }
}
