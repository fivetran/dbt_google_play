with installs as (

    select *
    from {{ var('stats_installs_country') }}
), 

ratings as (

    select *
    from {{ var('stats_ratings_country') }}
), 

store_performance as (

    select *
    from {{ var('stats_store_performance_country') }}
), 

install_metrics as (

    select
        *,
        sum(daily_device_installs) over (partition by country, package_name rows between unbounded preceding and current row) as total_device_installs,
        sum(daily_device_uninstalls) over (partition by country, package_name rows between unbounded preceding and current row) as total_device_uninstalls
    from installs 
), 

store_performance_metrics as (

    select
        *,
        sum(store_listing_acquisitions) over (partition by country_region, package_name rows between unbounded preceding and current row) as total_store_acquisitions,
        sum(store_listing_visitors) over (partition by country_region, package_name rows between unbounded preceding and current row) as total_store_visitors
    from store_performance
), 

country_join as (

    select 
        -- these 3 columns are the grain of this model
        coalesce(install_metrics.date_day, ratings.date_day, store_performance_metrics.date_day) as date_day,
        coalesce(install_metrics.country, ratings.country, store_performance_metrics.country_region) as country,
        coalesce(install_metrics.package_name, ratings.package_name, store_performance_metrics.package_name) as package_name,

        -- metrics based on unique devices + users
        coalesce(install_metrics.active_device_installs, 0) as active_device_installs,
        coalesce(install_metrics.daily_device_installs, 0) as daily_device_installs,
        coalesce(install_metrics.daily_device_uninstalls, 0) as daily_device_uninstalls,
        coalesce(install_metrics.daily_device_upgrades, 0) as daily_device_upgrades,
        coalesce(install_metrics.daily_user_installs, 0) as daily_user_installs,
        coalesce(install_metrics.daily_user_uninstalls, 0) as daily_user_uninstalls,
        coalesce(store_performance_metrics.store_listing_acquisitions, 0) as store_listing_acquisitions,
        coalesce(store_performance_metrics.store_listing_visitors, 0) as store_listing_visitors,
        store_performance_metrics.store_listing_conversion_rate, -- not coalescing if there aren't any visitors 
        
        -- metrics based on events. a user or device can have multiple installs in one day
        coalesce(install_metrics.install_events, 0) as install_events,
        coalesce(install_metrics.uninstall_events, 0) as uninstall_events,
        coalesce(install_metrics.update_events, 0) as update_events,    

        -- all of the following fields (except %'s') are rolling metrics that we'll use window functions to backfill instead of coalescing
        install_metrics.total_unique_user_installs,
        install_metrics.total_device_installs,
        install_metrics.total_device_uninstalls,
        ratings.daily_average_rating, -- this one actually isn't rolling but we won't coalesce days with no reviews to 0 rating
        ratings.rolling_total_average_rating,
        store_performance_metrics.total_store_acquisitions,
        store_performance_metrics.total_store_visitors
        
    from install_metrics
    full outer join ratings
        on install_metrics.date_day = ratings.date_day
        and install_metrics.package_name = ratings.package_name
        and coalesce(install_metrics.country, 'null_country') = coalesce(ratings.country, 'null_country') -- in the source package we aggregate all null country records together into one batch per day
    full outer join store_performance_metrics
        on store_performance_metrics.date_day = install_metrics.date_day
        and store_performance_metrics.package_name = install_metrics.package_name
        and coalesce(store_performance_metrics.country_region, 'null_country') = coalesce(install_metrics.country, 'null_country')
), 

-- to backfill in days with NULL values for rolling metrics, we'll create partitions to batch them together with records that have non-null values
-- we can't just use last_value(ignore nulls) because of postgres :/
create_partitions as (

    select
        *

    {%- set rolling_metrics = ['rolling_total_average_rating', 'total_unique_user_installs', 'total_device_installs', 'total_device_uninstalls', 'total_store_acquisitions', 'total_store_visitors'] -%}

    {% for metric in rolling_metrics -%}
        , sum(case when {{ metric }} is null 
                then 0 else 1 end) over (partition by country, package_name order by date_day asc rows unbounded preceding) as {{ metric | lower }}_partition
    {%- endfor %}
    from country_join
), 

-- now we'll take the non-null value for each partitioned batch and propagate it across the rows included in the batch
fill_values as (

    select 
        date_day,
        country,
        package_name,
        active_device_installs,
        daily_device_installs,
        daily_device_uninstalls,
        daily_device_upgrades,
        daily_user_installs,
        daily_user_uninstalls,
        install_events,
        uninstall_events,
        update_events,
        store_listing_acquisitions, -- should we prepend with daily_?
        store_listing_visitors,
        store_listing_conversion_rate, -- daily
        daily_average_rating

        {% for metric in rolling_metrics -%}

        , first_value( {{ metric }} ) over (
            partition by {{ metric | lower }}_partition, country, package_name order by date_day asc rows between unbounded preceding and current row) as {{ metric }}

        {%- endfor %}
    from create_partitions
), 

final as (

    select 
        date_day,
        country,
        package_name,
        active_device_installs,
        daily_device_installs,
        daily_device_uninstalls,
        daily_device_upgrades,
        daily_user_installs,
        daily_user_uninstalls,
        install_events,
        uninstall_events,
        update_events,
        store_listing_acquisitions,
        store_listing_visitors,
        store_listing_conversion_rate,
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