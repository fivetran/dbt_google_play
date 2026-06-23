with base as (

    select *
    from {{ ref('stg_google_play__stats_crashes_overview_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_google_play__stats_crashes_overview_tmp')),
                staging_columns=get_stats_crashes_overview_columns()
            )
        }}

    
        {{ fivetran_utils.apply_source_relation(package_name='google_play') }}

    from base
),

final as (

    select
        cast(source_relation as {{ dbt.type_string() }}) as source_relation,
        cast(date as date) as date_day,
        cast(package_name as {{ dbt.type_string() }}) as package_name,
        cast(daily_anrs as {{ dbt.type_bigint() }}) as anrs,
        cast(daily_crashes as {{ dbt.type_bigint() }}) as crashes,
        _fivetran_synced
    from fields
)

select *
from final