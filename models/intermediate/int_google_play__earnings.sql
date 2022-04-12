{{ config(enabled=var('google_play__using_earnings', False)) }} -- maybe this should be disabled by default? 

with earnings as (

    select *
    from {{ var('earnings') }}

), 

daily_country_metrics as (

-- let's pivot out revenue metrics associated wit each type of transaction type
{% set transaction_types = dbt_utils.get_column_values(table=ref('stg_google_play__earnings'), column="coalesce(transaction_type, 'other')") %}

    select 
        transaction_date as date_day,
        buyer_country as country, -- mm should we include states here as well? we'd have to roll up to country to join with subscriptions
        sku_id,
        package_name, -- this is the same as package_name
        merchant_currency -- should be the same across the whole table....idk does this need to be included?? it would be wack to sum up different currencies if they changed
        {% for t in transaction_types %}
        , sum( case when lower(transaction_type) = '{{ t | lower }}' then amount_merchant_currency else 0 end ) as {{ t | replace(' ', '_') | lower }}_amount
        , sum( case when lower(transaction_type) = '{{ t | lower }}' then 1 else 0 end ) as {{ t | replace(' ', '_') | lower }}_events
        {% endfor %}
    from earnings
    {{ dbt_utils.group_by(n=5) }}
)

select *
from daily_country_metrics