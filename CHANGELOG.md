# dbt_google_play v1.2.0

[PR #31](https://github.com/fivetran/dbt_google_play/pull/31) includes the following updates:

## Documentation
- Updates README with standardized Fivetran formatting

## Under the Hood
- In the `.quickstart.yml` file:
  - Adds `table_variables` for relevant sources to prevent missing sources from blocking downstream Quickstart models.
  - Adds `supported_vars` for Quickstart UI customization,

# dbt_google_play v1.1.1
[PR #30](https://github.com/fivetran/dbt_google_play/pull/30) includes the following updates:

## Schema/Data Change
**1 total change • 0 breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ---------- | ----------- | -------- | -------- | ----- |
| `google_play__finance_report` | Field corrected | `net_amount` (incorrect - double-counted) | `net_amount` (corrected) | Now accurately sums net amounts at the daily/country/product grain. |

## Bug Fixes
- Fixed double-counting of net amounts in `int_google_play__earnings`. Previously, this intermediate calculation created duplicate `net_order_amount` values for each order line item, incorrectly summing total net amounts. The summation is now performed directly in the `daily_country_metrics` CTE in [`int_google_play__earnings`](https://github.com/fivetran/dbt_google_play/blob/main/models/intermediate/int_google_play__earnings.sql).  ([PR #26](https://github.com/fivetran/dbt_google_play/pull/26))
- Added flags in `int_google_play__earnings` to fix dbt fusion compilation errors. ([PR #28](https://github.com/fivetran/dbt_google_play/pull/28))

## Under the Hood
- Syntactic fixes applied to consistency tests. ([PR #26](https://github.com/fivetran/dbt_google_play/pull/26))

## Contributors
- [@waligob](https://github.com/waligob) ([PR #28](https://github.com/fivetran/dbt_google_play/pull/28))

# dbt_google_play v1.1.0
[PR #24](https://github.com/fivetran/dbt_google_play/pull/24) includes the following updates:

## Features
- Increases the required dbt version upper limit to v3.0.0.

# dbt_google_play v1.0.0

[PR #22](https://github.com/fivetran/dbt_google_play/pull/22) includes the following updates:

## Breaking Changes

### Source Package Consolidation
- Removed the dependency on the `fivetran/google_play_source` package.
  - All functionality from the source package has been merged into this transformation package for improved maintainability and clarity.
  - If you reference `fivetran/google_play_source` in your `packages.yml`, you must remove this dependency to avoid conflicts.
  - Any source overrides referencing the `fivetran/google_play_source` package will also need to be removed or updated to reference this package.
  - Update any google_play_source-scoped variables to be scoped to only under this package. See the [README](https://github.com/fivetran/dbt_google_play?tab=readme-ov-file#change-the-build-schema) for how to configure the build schema of staging models.
- As part of the consolidation, vars are no longer used to reference staging models, and only sources are represented by vars. Staging models are now referenced directly with `ref()` in downstream models.

### dbt Fusion Compatibility Updates
- Updated package to maintain compatibility with dbt-core versions both before and after v1.10.6, which introduced a breaking change to multi-argument test syntax (e.g., `unique_combination_of_columns`).
- Temporarily removed unsupported tests to avoid errors and ensure smoother upgrades across different dbt-core versions. These tests will be reintroduced once a safe migration path is available.
  - Removed all `dbt_utils.unique_combination_of_columns` tests.
  - Moved `loaded_at_field: _fivetran_synced` under the `config:` block in `src_google_play.yml`.

### Under the Hood 
- Updated conditions in `.github/workflows/auto-release.yml`.
- Added `.github/workflows/generate-docs.yml`. 

# dbt_google_play v0.5.0

[PR #19](https://github.com/fivetran/dbt_google_play/pull/19) includes the following updates:

## Breaking Change for dbt Core < 1.9.6
> *Note: This is not relevant to Fivetran Quickstart users.*

Migrated `freshness` from a top-level source property to a source `config` in alignment with [recent updates](https://github.com/dbt-labs/dbt-core/issues/11506) from dbt Core ([Google Play Source v0.5.0](https://github.com/fivetran/dbt_google_play_source/releases/tag/v0.5.0)). This will resolve the following deprecation warning that users running dbt >= 1.9.6 may have received:

```
[WARNING]: Deprecated functionality
Found `freshness` as a top-level property of `google_play` in file `models/src_google_play.yml`. The `freshness` top-level property should be moved into the `config` of `google_play`.
```

**IMPORTANT:** Users running dbt Core < 1.9.6 will not be able to utilize freshness tests in this release or any subsequent releases, as older versions of dbt will not recognize freshness as a source `config` and therefore not run the tests.

If you are using dbt Core < 1.9.6 and want to continue running Google Play freshness tests, please elect **one** of the following options:
  1. (Recommended) Upgrade to dbt Core >= 1.9.6
  2. Do not upgrade your installed version of the `google_play` package. Pin your dependency on v0.4.0 in your `packages.yml` file.
  3. Utilize a dbt [override](https://docs.getdbt.com/reference/resource-properties/overrides) to overwrite the package's `google_play` source and apply freshness via the previous release top-level property route. This will require you to copy and paste the entirety of the previous release `src_google_play.yml` file and add an `overrides: google_play_source` property.

## Documentation
- Added Quickstart model counts to README. ([#18](https://github.com/fivetran/dbt_google_play/pull/18))
- Corrected references to connectors and connections in the README. ([#18](https://github.com/fivetran/dbt_google_play/pull/18))

## Under the hood 🚘
- Updates to ensure integration tests use latest version of dbt.

# dbt_google_play v0.4.0
[PR #14](https://github.com/fivetran/dbt_google_play/pull/14) includes the following updates:

## 🚨 Breaking Changes 🚨
- Updated the source identifier format for consistency with other packages and for compatibility with the `fivetran_utils.union_data` macro. The identifier variables now are:

previous | current
--------|---------
`stats_installs_app_version_identifier` | `google_play_stats_installs_app_version_identifier`
`stats_crashes_app_version_identifier` | `google_play_stats_crashes_app_version_identifier`
`stats_ratings_app_version_identifier` | `google_play_stats_ratings_app_version_identifier`
`stats_installs_device_identifier` | `google_play_stats_installs_device_identifier`
`stats_ratings_device_identifier` | `google_play_stats_ratings_device_identifier`
`stats_installs_os_version_identifier` | `google_play_stats_installs_os_version_identifier`
`stats_ratings_os_version_identifier` | `google_play_stats_ratings_os_version_identifier`
`stats_crashes_os_version_identifier` | `google_play_stats_crashes_os_version_identifier`
`stats_installs_country_identifier` | `google_play_stats_installs_country_identifier`
`stats_ratings_country_identifier` | `google_play_stats_ratings_country_identifier`
`stats_store_performance_country_identifier` | `google_play_stats_store_performance_country_identifier`
`stats_store_performance_traffic_source_identifier` | `google_play_stats_store_performance_traffic_source_identifier`
`stats_installs_overview_identifier` | `google_play_stats_installs_overview_identifier`
`stats_crashes_overview_identifier` | `google_play_stats_crashes_overview_identifier`
`stats_ratings_overview_identifier` | `google_play_stats_ratings_overview_identifier`
`earnings_identifier` | `google_play_earnings_identifier`
`financial_stats_subscriptions_country_identifier` | `google_play_financial_stats_subscriptions_country_identifier`

- If you are using the previous identifier, be sure to update to the current version!

## Feature update 🎉
- Unioning capability! This adds the ability to union source data from multiple google_play connectors. Refer to the [README](https://github.com/fivetran/dbt_google_play/blob/main/README.md#union-multiple-connectors) for more details.
- Added a `source_relation` column in each staging model for tracking the source of each record.
  - The `source_relation` column is also persisted from the staging models to the end models.

## Under the hood 🚘
- Added the `source_relation` column to necessary joins. 
- In the source package:
  - Updated tmp models to union source data using the `fivetran_utils.union_data` macro. 
  - Applied the `fivetran_utils.source_relation` macro in each staging model to determine the `source_relation`.
  - Updated tests to account for the new `source_relation` column.
- Included auto-releaser GitHub Actions workflow to automate future releases.

# dbt_google_play v0.3.0

## 🚨 Breaking Changes 🚨:
[PR #10](https://github.com/fivetran/dbt_google_play/pull/10) includes the following changes:
- This version of the transform package points to a [breaking change in the source package](https://github.com/fivetran/dbt_google_play_source/blob/main/CHANGELOG.md) in which the the [country code](https://github.com/fivetran/dbt_google_play_source/blob/main/seeds/google_play__country_codes.csv) mapping table to align with Apple's [format and inclusion list](https://developer.apple.com/help/app-store-connect/reference/app-store-localizations/) of country names. This was change was made in parallel with the [Apple App Store](https://github.com/fivetran/dbt_apple_store/tree/main) dbt package in order to maintain parity for proper aggregating in the combo [App Reporting](https://github.com/fivetran/dbt_app_reporting) package.
  - This is a 🚨**breaking change**🚨 as you will need to re-seed (`dbt seed --full-refresh`) the `google_play__country_codes` file again.

## Under the Hood:
[PR #9](https://github.com/fivetran/dbt_google_play/pull/9) includes the following changes:
- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job.
- Updated the pull request [templates](/.github).

# dbt_google_play v0.2.0

## 🚨 Breaking Changes 🚨:
[PR #6](https://github.com/fivetran/dbt_google_play/pull/6) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- `dbt_utils.surrogate_key` has also been updated to `dbt_utils.generate_surrogate_key`. Since the method for creating surrogate keys differ, we suggest all users do a `full-refresh` for the most accurate data. For more information, please refer to dbt-utils [release notes](https://github.com/dbt-labs/dbt-utils/releases) for this update.
- `packages.yml` has been updated to reflect new default `fivetran/fivetran_utils` version, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.

# dbt_google_play v0.1.0

## Initial Release
This is the initial release of this package. 

__What does this dbt package do?__
- Produces modeled tables that leverage Google Play data from [Fivetran's connector](https://fivetran.com/docs/applications/google-play) in the format described [here](https://fivetran.com/docs/applications/google-play#schemainformation) and builds off the output of our [Google Play source package](https://github.com/fivetran/dbt_google_play_source).
- The above mentioned models enable you to better understand your Google Play app performance metrics at different granularities. It achieves this by:
  - Providing intuitive reporting at the App Version, OS Version, Device Type, Country, Overview, and Product (Subscription + In-App Purchase) levels
  - Aggregates all relevant application metrics into each of the reporting levels above
- Generates a comprehensive data dictionary of your source and modeled Google Play data via the [dbt docs site](fivetran.github.io/dbt_google_play/)