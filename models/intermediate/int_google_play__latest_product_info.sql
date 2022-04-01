with earnings as (

    select *
    from {{ var('earnings') }}

), transaction_recency as (

    select 
        product_id,
        product_title,
        sku_id,
        max(transaction_pt_timestamp) as last_transaction_at
    
    from earnings
    group by 1,2,3

), order_product_records as (

    select 
        *,
        row_number() over(partition by sku_id order by last_transaction_at desc) as n

    from transaction_recency

), latest_product_record as (

    select 
        product_id as package_name, -- same thing
        product_title,
        sku_id

    from order_product_records
    where n = 1

)

select *
from latest_product_record