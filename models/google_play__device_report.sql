with installs as (

    select *
    from {{ var('stats_installs_device') }}

), ratings as (

    select *
    from {{ var('stats_ratings_device') }}

), install_metrics as (

    select
        *,
        -- maybe this should be split into two columns and people can take the difference themsevles...
        sum(daily_device_installs) over (partition by device, package_name rows between unbounded preceding and current row) as total_device_installs,
        sum(daily_device_uninstalls) over (partition by device, package_name rows between unbounded preceding and current row) as total_device_uninstalls

    from installs 

), device_join as (

    select 
        coalesce(install_metrics.date_day, ratings.date_day) as date_day,
        coalesce(install_metrics.device, ratings.device) as device,
        coalesce(install_metrics.package_name, ratings.package_name) as package_name,

        coalesce(install_metrics.active_device_installs, 0) as active_device_installs,
        coalesce(install_metrics.daily_device_installs, 0) as daily_device_installs,
        coalesce(install_metrics.daily_device_uninstalls, 0) as daily_device_uninstalls,
        coalesce(install_metrics.daily_device_upgrades, 0) as daily_device_upgrades,
        coalesce(install_metrics.daily_user_installs, 0) as daily_user_installs,
        coalesce(install_metrics.daily_user_uninstalls, 0) as daily_user_uninstalls,
        
        coalesce(install_metrics.install_events, 0) as install_events,
        coalesce(install_metrics.uninstall_events, 0) as uninstall_events,
        coalesce(install_metrics.update_events, 0) as update_events,    

        -- gonna need to do some first_value stuff here...
        install_metrics.total_unique_user_installs,
        install_metrics.total_device_installs,
        install_metrics.total_device_uninstalls,

        ratings.daily_average_rating,
        ratings.rolling_total_average_rating

    from install_metrics
    full outer join ratings
        on install_metrics.date_day = ratings.date_day
        and install_metrics.package_name = ratings.package_name
        and coalesce(install_metrics.device, 'null_device') = coalesce(ratings.device, 'null_device')

), create_partitions as (

    select
        *,

        -- might wanna do a for loop over a list of metrics like the country report
        sum(case when rolling_total_average_rating is null 
                then 0 else 1 end) over (partition by device, package_name order by date_day asc rows unbounded preceding) as rolling_avg_rating_partition,

        sum(case when total_unique_user_installs is null 
                then 0 else 1 end) over (partition by device, package_name order by date_day asc rows unbounded preceding) as total_users_partition,

        sum(case when total_device_installs is null 
                then 0 else 1 end) over (partition by device, package_name order by date_day asc rows unbounded preceding) as total_device_installs_partition,

        sum(case when total_device_uninstalls is null 
                then 0 else 1 end) over (partition by device, package_name order by date_day asc rows unbounded preceding) as total_device_uninstalls_partition

    from device_join

), fill_values as (

    select 
        date_day,
        device,
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
        daily_average_rating,

        first_value( rolling_total_average_rating ) over (
            partition by rolling_avg_rating_partition, device, package_name order by date_day asc rows between unbounded preceding and current row) as rolling_total_average_rating,

        first_value( total_unique_user_installs ) over (
            partition by total_users_partition, device, package_name order by date_day asc rows between unbounded preceding and current row) as total_unique_user_installs,

        first_value( total_device_installs ) over (
            partition by total_device_installs_partition, device, package_name order by date_day asc rows between unbounded preceding and current row) as total_device_installs,

        first_value( total_device_uninstalls ) over (
            partition by total_device_uninstalls_partition, device, package_name order by date_day asc rows between unbounded preceding and current row) as total_device_uninstalls

    from create_partitions

), final as (

    select 
        date_day,
        device,
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
        daily_average_rating,
        rolling_total_average_rating,
        coalesce(total_unique_user_installs, 0) as total_unique_user_installs,
        coalesce(total_device_installs, 0) as total_device_installs,
        coalesce(total_device_uninstalls, 0) as total_device_uninstalls,
        coalesce(total_device_installs, 0) - coalesce(total_device_uninstalls, 0) as net_device_installs

    from fill_values
)

select *
from final