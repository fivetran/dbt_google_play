<!--section="google-play_transformation_model"-->
# Google Play dbt Package

<p align="left">
    <a alt="License"
        href="https://github.com/fivetran/dbt_google_play/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0,_<3.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/dbt/quickstart">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

This dbt package transforms data from Fivetran's Google Play connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 40
- Connector documentation
  - [Google Play connector documentation](https://fivetran.com/docs/connectors/applications/google-play)
  - [Google Play ERD](https://fivetran.com/docs/connectors/applications/google-play#schemainformation)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_google_play)
  - [dbt Docs](https://fivetran.github.io/dbt_google_play/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_google_play/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_google_play/blob/main/CHANGELOG.md)

## What does this dbt package do?
This package enables you to better understand your Google Play app performance metrics at different granularities and aggregate all relevant application metrics. It creates enriched models with metrics focused on App Version, OS Version, Device Type, Country, Overview, and Product (Subscription + In-App Purchase) reporting levels.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_google_play
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [google_play__app_version_report](https://fivetran.github.io/dbt_google_play/#!/model/model.google_play.google_play__app_version_report) | Tracks daily installs, crashes, ANRs (Application Not Responding), and user ratings by app version to monitor version stability, adoption rates, and quality. <br></br>**Example Analytics Questions:**<ul><li>Which app versions have the highest crash and ANR rates affecting user experience?</li><li>How do install volumes and user ratings differ across app versions?</li><li>Are newer app versions showing improved stability compared to previous releases?</li></ul>|
| [google_play__country_report](https://fivetran.github.io/dbt_google_play/#!/model/model.google_play.google_play__country_report) | Analyzes daily app installs, ratings, and store visibility by country to understand geographic market performance and optimize regional app store strategies. <br></br>**Example Analytics Questions:**<ul><li>Which countries drive the most app installs and have the highest user ratings?</li><li>How do store performance metrics (visitors, conversions) vary across different markets?</li><li>What countries show the strongest growth potential based on install trends?</li></ul>|
| [google_play__device_report](https://fivetran.github.io/dbt_google_play/#!/model/model.google_play.google_play__device_report) | Monitors daily installs and user ratings by device model to identify popular devices among users and optimize for device-specific compatibility. <br></br>**Example Analytics Questions:**<ul><li>Which device models have the most app installs and highest user satisfaction ratings?</li><li>Are there device-specific rating patterns that indicate compatibility issues?</li><li>Do frequent device updates correlate to increased satisfaction?</li></ul>|
| [google_play__os_version_report](https://fivetran.github.io/dbt_google_play/#!/model/model.google_play.google_play__os_version_report) | Analyzes daily installs, crashes, ANRs, and ratings by Android OS version to prioritize OS support, identify version-specific stability issues, and understand OS adoption among users. <br></br>**Example Analytics Questions:**<ul><li>Which Android OS versions have the most users and highest crash rates?</li><li>How do user ratings and app stability vary across different OS versions?</li><li>What percentage of users are on OS versions that require minimum support?</li></ul>|
| [google_play__overview_report](https://fivetran.github.io/dbt_google_play/#!/model/model.google_play.google_play__overview_report) | Provides a comprehensive daily overview of app performance including installs, crashes, store metrics, and ratings to monitor overall app health and user satisfaction. <br></br>**Example Analytics Questions:**<ul><li>What are the daily trends in app installs, uninstalls, crashes, and user ratings?</li><li>How do overall app stability metrics (crash-free rate) trend over time?</li><li>What is the relationship between store visibility metrics and daily install volumes?</li></ul>|
| [google_play__finance_report](https://fivetran.github.io/dbt_google_play/#!/model/model.google_play.google_play__finance_report) | Tracks daily subscription revenue, in-app purchases, and financial performance by product and country to analyze monetization effectiveness and revenue trends. <br></br>**Example Analytics Questions:**<ul><li>Which products and countries generate the most subscription and purchase revenue?</li><li>What is the mix of subscription versus one-time purchase revenue by market?</li><li>How do refund rates and net revenue vary across different products and regions?</li></ul>|

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Google Play connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/dbt).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_google_play/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the package (skip if also using the `app_reporting` transformation package)
Include the following Google Play package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/google_play
    version: [">=1.2.0", "<1.3.0"] # we recommend using ranges to capture non-breaking changes automatically
```

> All required sources and staging models are now bundled into this transformation package. Do not include `fivetran/google_play_source` in your `packages.yml` since this package has been deprecated.

### Define database and schema variables
By default, this package runs using your destination and the `google_play` schema. If this is not where your Google Play data is (for example, if your Google Play schema is named `google_play_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    google_play_database: your_destination_name
    google_play_schema: your_schema_name 
```

### Disable or enable source tables
Your Google Play connection might not sync every table that this package expects. If you have financial and/or subscriptions data, namely the `earnings` and `financial_stats_subscriptions_country` tables, add the following variable(s) to your `dbt_project.yml` file:

```yml
vars:
    google_play__using_earnings: true # by default this is assumed to be FALSE
    google_play__using_subscriptions: true # by default this is assumed to be FALSE
```

### Seed `country_codes` mapping table (once)

In order to map longform territory names to their ISO country codes, we have adapted the CSV from [lukes/ISO-3166-Countries-with-Regional-Codes](https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes) to align Google and [Apple's](https://developer.apple.com/help/app-store-connect/reference/app-store-localizations/) country name formats for the [App Reporting](https://github.com/fivetran/dbt_app_reporting) combo package.

You will need to `dbt seed` the `google_play__country_codes` [file](https://github.com/fivetran/dbt_google_play/blob/main/seeds/google_play__country_codes.csv) just once.

### (Optional) Additional configurations
<details open><summary>Expand/collapse configurations</summary>

#### Union multiple connections
If you have multiple google_play connections in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set either the `google_play_union_schemas` OR `google_play_union_databases` variables (cannot do both) in your root `dbt_project.yml` file:

```yml
vars:
    google_play_union_schemas: ['google_play_usa','google_play_canada'] # use this if the data is in different schemas/datasets of the same database/project
    google_play_union_databases: ['google_play_usa','google_play_canada'] # use this if the data is in different databases/projects but uses the same schema name
```
> NOTE: The native `source.yml` connection set up in the package will not function when the union schema/database feature is utilized. Although the data will be correctly combined, you will not observe the sources linked to the package models in the Directed Acyclic Graph (DAG). This happens because the package includes only one defined `source.yml`.

To connect your multiple schema/database sources to the package models, follow the steps outlined in the [Union Data Defined Sources Configuration](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_data-source) section of the Fivetran Utils documentation for the union_data macro. This will ensure a proper configuration and correct visualization of connections in the DAG.
    
#### Change the build schema
By default, this package builds the Google Play staging models within a schema titled (`<target_schema>` + `_google_play_source`) and your Google Play modeling models within a schema titled (`<target_schema>` + `_google_play`) in your destination. If this is not where you would like your Google Play data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    google_play:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```
    
#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_google_play/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    google_play_<default_source_table_name>_identifier: your_table_name 
```
</details>

<br>

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>
    
Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core™ setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).
</details>
<br>
    
## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
    
```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]

    - package: dbt-labs/spark_utils
      version: [">=0.3.0", "<0.4.0"]
```

<!--section="google-play_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/google_play/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_google_play/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_google_play/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).