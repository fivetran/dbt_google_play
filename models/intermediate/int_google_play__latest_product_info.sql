ADD source_relation WHERE NEEDED + CHECK JOINS AND WINDOW FUNCTIONS! (Delete this line when done.)

{{ config(enabled=var('google_play__using_earnings', False)) }} 

with earnings as (

    select *
    from {{ var('earnings') }}
), 

-- figure out when the latest transaction involving this product was to find the latest product title used for it
transaction_recency as (

    select 
        package_name,
        product_title,
        sku_id,
        max(transaction_pt_timestamp) as last_transaction_at
    from earnings
    group by 1,2,3
), 

order_product_records as (

    select 
        *,
        row_number() over(partition by source_relation, sku_id order by last_transaction_at desc) as n
    from transaction_recency
), 

latest_product_record as (

    select 
        package_name,
        product_title,
        sku_id
    from order_product_records
    where n = 1
)

select *
from latest_product_record