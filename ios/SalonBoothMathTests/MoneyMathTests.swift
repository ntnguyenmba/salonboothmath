import XCTest
@testable import SalonBoothMath

final class MoneyMathTests: XCTestCase {
    func testBoothCashAndCardTips() {
        let result = MoneyMath.boothTakeHome(
            services: 100_000,
            cashTips: 10_000,
            cardTips: 5_000,
            supplies: 4_000,
            weeklyRent: 25_000,
            extraFees: 2_000,
            cardFeeRate: Decimal(string: "0.029")!,
            percentServicesOnCard: Decimal(string: "0.70")!
        )
        XCTAssertEqual(result, 81_825)
    }

    func testCommissionWithoutWorkerCardFees() {
        let result = MoneyMath.commissionTakeHome(
            services: 100_000,
            cashTips: 10_000,
            cardTips: 5_000,
            supplies: 4_000,
            cut: Decimal(string: "0.55")!,
            tipOwner: .you,
            workerPaysCardFees: false,
            extraFees: 2_000
        )
        XCTAssertEqual(result, 64_000)
    }

    func testCommissionWithWorkerCardFees() {
        let result = MoneyMath.commissionTakeHome(
            services: 100_000,
            cashTips: 10_000,
            cardTips: 5_000,
            supplies: 4_000,
            cut: Decimal(string: "0.55")!,
            tipOwner: .you,
            workerPaysCardFees: true,
            extraFees: 2_000,
            cardFeeRate: Decimal(string: "0.029")!,
            percentServicesOnCard: Decimal(string: "0.70")!
        )
        XCTAssertEqual(result, 61_825)
    }

    func testNegativeTakeHomeStaysNegative() {
        XCTAssertEqual(
            MoneyMath.boothTakeHome(
                services: 10_000, cashTips: 0, cardTips: 0,
                supplies: 5_000, weeklyRent: 25_000,
                cardFeeRate: 0, percentServicesOnCard: 0
            ),
            -20_000
        )
    }

    func testMonthlyRentConversion() {
        XCTAssertEqual(MoneyMath.weeklyRent(cents: 100_000, period: .month), 23_077)
    }
}
