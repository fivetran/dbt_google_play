{{ config(enabled=var('google_play__using_subscriptions', False)) }}

{% if var('google_play_union_schemas', []) | length > 0 or var('google_play_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='financial_stats_subscriptions_country', 
        database_variable='google_play_database', 
        schema_variable='google_play_schema', 
        default_database=target.database,
        default_schema='google_play',
        default_variable='financial_stats_subscriptions_country',
        union_schema_variable='google_play_union_schemas',
        union_database_variable='google_play_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='google_play_sources',
        single_source_name='google_play',
        single_table_name='financial_stats_subscriptions_country'
    )
}}

{% endif %}