# dbt_google_play v0.1.0

## Initial Release
This is the initial release of this package. 

__What does this dbt package do?__
- Produces modeled tables that leverage Google Play data from [Fivetran's connector](https://fivetran.com/docs/applications/google-play) in the format described [here](https://fivetran.com/docs/applications/google-play#schemainformation) and builds off the output of our [Google Play source package](https://github.com/fivetran/dbt_google_play_source).
- The above mentioned models enable you to better understand your Google Play app performance metrics at different granularities. It achieves this by:
  - Providing intuitive reporting at the App Version, OS Version, Device Type, Country, Overview, and Product (Subscription + In-App Purchase) levels
  - Aggregates all relevant application metrics into each of the reporting levels above
- Generates a comprehensive data dictionary of your source and modeled Google Play data via the [dbt docs site](fivetran.github.io/dbt_google_play/)