# Money math parity

iOS `MoneyMath` and Android `MoneyMath` must return the same integer cents for the same inputs.

Rounding: nearest cent, ties away from zero (`NSRoundPlain` / `RoundingMode.HALF_UP`).
Monthly rent weeks: `4.3333`.
Default card fee: `2.9%`.
Default services on card: `70%`.

## Shared fixtures

| Case | Inputs | Result cents |
| --- | --- | --- |
| Booth sample week | services 100000, cash 10000, card 5000, supplies 4000, rent 25000, extra 2000, fee 2.9%, card share 70% | 81825 |
| Commission, worker does not pay fees | same money, cut 55%, tips you, extra 2000 | 64000 |
| Commission, worker pays fees | same + workerPaysCardFees | 61825 |
| Negative booth week | services 10000, supplies 5000, rent 25000, fees 0 | -20000 |
| Monthly rent | 100000 / 4.3333 | 23077 |
| Half cent fee | services 100, fee 1%, card share 50% | 1 |
| Split 1¢ tip | cash tip 1, cut 0, split | 1 |
| US parse | `$1,240.50` | 124050 |
| EU parse | `1.240,50` | 124050 |
| Negative parse | `-5` | 0 |

If a fixture changes, update both test targets in the same change.
