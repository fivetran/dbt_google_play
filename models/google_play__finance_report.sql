{{ config(enabled=var('google_play__using_earnings', False)) }} -- maybe this should be disabled by default? 

with earnings as (

    select *
    from {{ ref('int_google_play__earnings') }}
), 

product_info as (

    select *
    from {{ ref('int_google_play__latest_product_info') }}

-- there's honestly quite a bit in here since we only need to do backfilling stuff if there is indeed a full outer join
{% if var('google_play__using_subscriptions', False) -%}
), 

subscriptions as (

    select *
    from {{ var('financial_stats_subscriptions_country') }}
), 

daily_join as (

-- these are dynamically set 
{% set earning_transaction_metrics = adapter.get_columns_in_relation(ref('int_google_play__earnings')) %}

    select
        coalesce(earnings.date_day, subscriptions.date_day) as date_day,
        coalesce(earnings.country, subscriptions.country) as country,
        coalesce(earnings.package_name, subscriptions.package_name) as package_name,
        coalesce(earnings.sku_id, subscriptions.product_id) as sku_id,
        earnings.merchant_currency, -- this will just be null if there aren't transactions on a given day

        {% for t in earning_transaction_metrics -%}
            {% if t.column|lower not in ['country', 'date_day', 'sku_id', 'package_name', 'merchant_currency'] -%}
        coalesce( {{ t.column }}, 0) as {{ t.column|lower }},
            {% endif %}
        {%- endfor -%}

        coalesce(subscriptions.daily_new_subscriptions, 0) as daily_new_subscriptions,
        coalesce(subscriptions.daily_cancelled_subscriptions, 0) as daily_cancelled_subscriptions,
        subscriptions.count_active_subscriptions -- do some first value stuff

    from earnings
    full outer join subscriptions
        on earnings.date_day = subscriptions.date_day
        and earnings.package_name = subscriptions.package_name
        and coalesce(earnings.country, 'null_country') = coalesce(subscriptions.country, 'null_country')
        and earnings.sku_id = subscriptions.product_id
), 

create_partitions as (

    select 
        *,
        sum(case when count_active_subscriptions is null 
                then 0 else 1 end) over (partition by country, sku_id order by date_day asc rows unbounded preceding) as count_active_subscriptions_partition
    from daily_join
), 

fill_values as (

    select 
        -- we can include these in earning_transaction_metrics but wanna keep them in this column position
        date_day,
        country,
        package_name, 
        sku_id,
        merchant_currency,
        {% for t in earning_transaction_metrics -%}
            {%- if t.column|lower not in ['country', 'date_day', 'sku_id', 'package_name', 'merchant_currency'] -%}
        {{ t.column | lower }},
            {% endif %}
        {%- endfor -%}

        daily_new_subscriptions,
        daily_cancelled_subscriptions,

        first_value( count_active_subscriptions ) over (
            partition by count_active_subscriptions_partition, country, sku_id order by date_day asc rows between unbounded preceding and current row) as count_active_subscriptions
    from create_partitions
), 

final_values as (

    select 
        date_day,
        country,
        package_name, 
        sku_id,
        merchant_currency,
        {% for t in earning_transaction_metrics -%}
            {%- if t.column|lower not in ['country', 'date_day', 'sku_id', 'package_name', 'merchant_currency'] -%}
        {{ t.column | lower }},
            {% endif %}
        {%- endfor -%}
        daily_new_subscriptions,
        daily_cancelled_subscriptions,
        coalesce(count_active_subscriptions, 0) as count_active_subscriptions
    from fill_values
{%- endif %}

), 

add_product_info as (

    select 
        base.*,
        product_info.product_title
    from {{ 'final_values' if var('google_play__using_subscriptions', False) else 'earnings' }} as base
    left join product_info 
        on base.package_name = product_info.package_name
        and base.sku_id = product_info.sku_id
)

select *
from add_product_info