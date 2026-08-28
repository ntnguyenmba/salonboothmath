import XCTest
@testable import SalonBoothMath

final class MoneyMathTests: XCTestCase {
    func testBoothCashAndCardTips() {
        let result = MoneyMath.boothTakeHome(services: 100_000, cashTips: 10_000, cardTips: 5_000, supplies: 4_000, weeklyRent: 25_000, extraFees: 2_000, cardFeeRate: Decimal(string: "0.029")!, percentServicesOnCard: Decimal(string: "0.70")!)
        XCTAssertEqual(result, 81_825)
    }

    func testCommissionWithoutWorkerCardFees() {
        XCTAssertEqual(MoneyMath.commissionTakeHome(services: 100_000, cashTips: 10_000, cardTips: 5_000, supplies: 4_000, cut: Decimal(string: "0.55")!, tipOwner: .you, workerPaysCardFees: false, extraFees: 2_000), 64_000)
    }

    func testCommissionWithWorkerCardFees() {
        XCTAssertEqual(MoneyMath.commissionTakeHome(services: 100_000, cashTips: 10_000, cardTips: 5_000, supplies: 4_000, cut: Decimal(string: "0.55")!, tipOwner: .you, workerPaysCardFees: true, extraFees: 2_000, cardFeeRate: Decimal(string: "0.029")!, percentServicesOnCard: Decimal(string: "0.70")!), 61_825)
    }

    func testNegativeTakeHomeStaysNegative() { XCTAssertEqual(MoneyMath.boothTakeHome(services: 10_000, cashTips: 0, cardTips: 0, supplies: 5_000, weeklyRent: 25_000, cardFeeRate: 0, percentServicesOnCard: 0), -20_000) }
    func testMonthlyRentConversion() { XCTAssertEqual(MoneyMath.weeklyRent(cents: 100_000, period: .month), 23_077) }
    func testUSCurrencyInput() { XCTAssertEqual(MoneyMath.cents(from: "$1,240.50"), 124_050) }
    func testEuropeanCurrencyInput() { XCTAssertEqual(MoneyMath.cents(from: "1.240,50"), 124_050) }
    func testSpacedCurrencyInput() { XCTAssertEqual(MoneyMath.cents(from: "1 240"), 124_000) }
    func testNegativeInputRejected() { XCTAssertEqual(MoneyMath.cents(from: "-5"), 0) }
    func testHalfCentRoundsUp() { XCTAssertEqual(MoneyMath.cardFees(services: 100, cardTips: 0, cardFeeRate: Decimal(string: "0.01")!, percentServicesOnCard: Decimal(string: "0.5")!), 1) }
    func testSplitOneCentTipRoundsToWorker() { XCTAssertEqual(MoneyMath.commissionTakeHome(services: 0, cashTips: 1, cardTips: 0, supplies: 0, cut: 0, tipOwner: .split), 1) }
    func testBasisPointsAreExact() {
        XCTAssertEqual(MoneyMath.basisPoints(fromPercentText: "2.9", fallback: 0), 290)
        XCTAssertEqual(MoneyMath.rate(fromBasisPoints: 290), Decimal(string: "0.029")!)
    }
}
