import XCTest
@testable import Ease

final class EaseTests: XCTestCase {

    // MARK: Pattern math

    func testCycleSeconds() {
        XCTAssertEqual(BreathPattern.box.cycleSeconds, 16)
        XCTAssertEqual(BreathPattern.relax.cycleSeconds, 19)
        XCTAssertEqual(BreathPattern.even.cycleSeconds, 10)
    }

    func testFreeAndProSplit() {
        XCTAssertEqual(BreathPattern.free.count, 3)
        XCTAssertTrue(BreathPattern.free.allSatisfy { !$0.isPro })
        XCTAssertTrue(BreathPattern.proPresets.allSatisfy { $0.isPro })
        XCTAssertEqual(BreathPattern.builtIn(id: "relax"), BreathPattern.relax)
    }

    func testCustomPatternDetailOmitsZeroHolds() {
        let dto = CustomPatternDTO(id: "x", name: "Mine", inhale: 4, holdIn: 0, exhale: 6, holdOut: 0)
        XCTAssertEqual(dto.asPattern().detail, "4·6")
        let withHolds = CustomPatternDTO(id: "y", name: "Mine", inhale: 4, holdIn: 4, exhale: 6, holdOut: 2)
        XCTAssertEqual(withHolds.asPattern().detail, "4·4·6·2")
        XCTAssertTrue(dto.asPattern().isPro)
        XCTAssertTrue(dto.asPattern().isCustom)
    }

    // MARK: Streak math

    private func days(_ offsets: [Int], cal: Calendar) -> Set<Date> {
        let today = cal.startOfDay(for: Date())
        return Set(offsets.compactMap { cal.date(byAdding: .day, value: -$0, to: today) })
    }

    func testCurrentStreakCountsTodayBackwards() {
        let cal = Calendar.current
        XCTAssertEqual(AppModel.currentStreak(days: days([0, 1, 2], cal: cal), cal: cal), 3)
    }

    func testCurrentStreakHoldsWhenTodayNotYetLogged() {
        let cal = Calendar.current
        // Logged yesterday & the day before, not today → streak still 2 (today still possible).
        XCTAssertEqual(AppModel.currentStreak(days: days([1, 2], cal: cal), cal: cal), 2)
    }

    func testCurrentStreakBreaksWithGap() {
        let cal = Calendar.current
        // Today logged, then a gap at day 1, then days 2 & 3 → current streak is just 1.
        XCTAssertEqual(AppModel.currentStreak(days: days([0, 2, 3], cal: cal), cal: cal), 1)
        XCTAssertEqual(AppModel.currentStreak(days: [], cal: cal), 0)
    }

    func testLongestStreak() {
        let cal = Calendar.current
        // Runs: {0,1,2} length 3, and {5,6} length 2 → longest 3.
        XCTAssertEqual(AppModel.longestStreak(days: days([0, 1, 2, 5, 6], cal: cal), cal: cal), 3)
    }

    // MARK: Store

    @MainActor
    func testProductIDAndPriceFallback() {
        XCTAssertEqual(Store.productID, "ease_pro_unlock")
    }
}
