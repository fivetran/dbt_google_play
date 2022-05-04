# Decision Log

In creating this package, which is meant for a wide range of use cases, we had to take opinionated stances on a few different questions we came across during development. We've consolidated significant choices we made here, and will continue to update as the package evolves. We are always open to and encourage feedback on these choices, and the package in general.

## Using `earnings` instead of `estimated_sales`
The `google_play__finance_report` model will **not** tie out with the Google Play UI's revenue report. This is because this model draws from the [earnings](https://support.google.com/googleplay/android-developer/answer/6135870#export&zippy=%2Cearnings) report and the UI draws from the estimated [sales](https://support.google.com/googleplay/android-developer/answer/6135870#export&zippy=%2Cestimated-sales) report. The `sales` table does not take into account withholding taxes nor chargebacks, and it contains amounts paid by buyers in their local currency and doesn't contain converted amounts in your payout currency.

Google recommends using `earnings` data for financial analyses due to the limitations of `sales`, which is more appropriate for trend analyses than accounting ([source](https://support.google.com/googleplay/android-developer/answer/6135870)).

## Including incomplete recent data
This package does not exclude recent data, though there can be somewhat considerable lags between the data you see in the Google Play UI statistics reports and that in your Google Play connector data. These delays can range from hours to over a week in our experience, and they may be inconsistent across source tables. Note that though there may be non-zero metrics reported in recent records, they still exclude events/users/devices captured in the Google Play UI and may change in the near future. 