with installs as (

    select *
    from {{ var('stats_installs_overview') }}
), 

ratings as (

    select *
    from {{ var('stats_ratings_overview') }}
), 

crashes as (

    select *
    from {{ var('stats_crashes_overview') }}
), 

store_performance as (

    select *
    from {{ var('stats_store_performance_country') }}
), 

install_metrics as (

    select
        *,
        sum(daily_device_installs) over (partition by package_name rows between unbounded preceding and current row) as total_device_installs,
        sum(daily_device_uninstalls) over (partition by package_name rows between unbounded preceding and current row) as total_device_uninstalls
    from installs 
), 

-- this is at the country level so let's roll up to overview
store_performance_rollup as (

    select 
        date_day,
        package_name,
        sum(store_listing_acquisitions) as store_listing_acquisitions,
        sum(store_listing_visitors) as store_listing_visitors
    from store_performance
    group by 1,2
),

store_performance_metrics as (

    select
        *,
        round(store_listing_acquisitions * 1.0 / nullif(store_listing_visitors, 0), 4) as store_listing_conversion_rate,
        sum(store_listing_acquisitions) over (partition by package_name rows between unbounded preceding and current row) as total_store_acquisitions,
        sum(store_listing_visitors) over (partition by package_name rows between unbounded preceding and current row) as total_store_visitors
    from store_performance_rollup
), 

overview_join as (

    select 
        -- these 2 columns are the grain of this model
        coalesce(install_metrics.date_day, ratings.date_day, store_performance_metrics.date_day, crashes.date_day) as date_day,
        coalesce(install_metrics.package_name, ratings.package_name, store_performance_metrics.package_name, crashes.package_name) as package_name,

        -- metrics based on unique devices + users
        coalesce(install_metrics.active_device_installs, 0) as active_device_installs,
        coalesce(install_metrics.daily_device_installs, 0) as daily_device_installs,
        coalesce(install_metrics.daily_device_uninstalls, 0) as daily_device_uninstalls,
        coalesce(install_metrics.daily_device_upgrades, 0) as daily_device_upgrades,
        coalesce(install_metrics.daily_user_installs, 0) as daily_user_installs,
        coalesce(install_metrics.daily_user_uninstalls, 0) as daily_user_uninstalls,
        coalesce(store_performance_metrics.store_listing_acquisitions) as store_listing_acquisitions,
        coalesce(store_performance_metrics.store_listing_visitors) as store_listing_visitors,
        store_performance_metrics.store_listing_conversion_rate, -- not coalescing if there aren't any visitors 

        -- metrics based on events. a user or device can have multiple installs in one day
        coalesce(crashes.daily_crashes, 0) as daily_crashes,
        coalesce(crashes.daily_anrs, 0) as daily_anrs,
        coalesce(install_metrics.install_events, 0) as install_events,
        coalesce(install_metrics.uninstall_events, 0) as uninstall_events,
        coalesce(install_metrics.update_events, 0) as update_events,    

        -- all of the following fields (except daily_average_rating) are rolling metrics that we'll use window functions to backfill instead of coalescing
        install_metrics.total_unique_user_installs,
        install_metrics.total_device_installs,
        install_metrics.total_device_uninstalls,
        ratings.daily_average_rating, -- this one actually isn't rolling but we won't coalesce days with no reviews to 0 rating. todo: move
        ratings.rolling_total_average_rating,
        store_performance_metrics.total_store_acquisitions,
        store_performance_metrics.total_store_visitors

    from install_metrics
    full outer join ratings
        on install_metrics.date_day = ratings.date_day
        and install_metrics.package_name = ratings.package_name
    full outer join store_performance_metrics
        on store_performance_metrics.date_day = install_metrics.date_day
        and store_performance_metrics.package_name = install_metrics.package_name
    full outer join crashes
        on install_metrics.date_day = crashes.date_day
        and install_metrics.package_name = crashes.package_name
),

-- to backfill in days with NULL values for rolling metrics, we'll create partitions to batch them together with records that have non-null values
-- we can't just use last_value(ignore nulls) because of postgres :/
create_partitions as (

    select
        *

    {%- set rolling_metrics = ['rolling_total_average_rating', 'total_unique_user_installs', 'total_device_installs', 'total_device_uninstalls', 'total_store_acquisitions', 'total_store_visitors'] -%}

    {% for metric in rolling_metrics -%}
        , sum(case when {{ metric }} is null 
                then 0 else 1 end) over (partition by package_name order by date_day asc rows unbounded preceding) as {{ metric | lower }}_partition
    {%- endfor %}
    from overview_join
), 

-- now we'll take the non-null value for each partitioned batch and propagate it across the rows included in the batch
fill_values as (

    select 
        date_day,
        package_name,
        active_device_installs,
        daily_device_installs,
        daily_device_uninstalls,
        daily_device_upgrades,
        daily_user_installs,
        daily_user_uninstalls,
        daily_crashes,
        daily_anrs,
        install_events,
        uninstall_events,
        update_events,
        store_listing_acquisitions, -- should we prepend with daily_?
        store_listing_visitors,
        store_listing_conversion_rate, -- daily
        daily_average_rating

        {% for metric in rolling_metrics -%}

        , first_value( {{ metric }} ) over (
            partition by {{ metric | lower }}_partition, package_name order by date_day asc rows between unbounded preceding and current row) as {{ metric }}

        {%- endfor %}
    from create_partitions
), 

final as (

    select 
        date_day,
        package_name,
        active_device_installs,
        daily_device_installs,
        daily_device_uninstalls,
        daily_device_upgrades,
        daily_user_installs,
        daily_user_uninstalls,
        daily_crashes,
        daily_anrs,
        install_events,
        uninstall_events,
        update_events,
        store_listing_acquisitions, -- should we prepend with daily_?
        store_listing_visitors,
        store_listing_conversion_rate, -- daily
        daily_average_rating,

        -- leave null if there are no ratings yet
        rolling_total_average_rating, 

        -- the first day will have NULL values, let's make it 0
        coalesce(total_unique_user_installs, 0) as total_unique_user_installs,
        coalesce(total_device_installs, 0) as total_device_installs,
        coalesce(total_device_uninstalls, 0) as total_device_uninstalls,
        coalesce(total_store_acquisitions, 0) as total_store_acquisitions,
        coalesce(total_store_visitors, 0) as total_store_visitors,

        -- calculate percentage and difference rolling metrics
        round(total_store_acquisitions * 1.0 / nullif(total_store_visitors, 0), 4) as rolling_store_conversion_rate,
        coalesce(total_device_installs, 0) - coalesce(total_device_uninstalls, 0) as net_device_installs
    from fill_values
)

select *
from final