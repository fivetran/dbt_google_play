{#- Parses the app name out of a Google Play package name (for example, `com.example.app` -> `app`).
    Package names follow the pattern x.y.<app_name>, so the app name is the text after the final period. -#}
{% macro infer_app_name(package_name_column='package_name') -%}
    {{ dbt.split_part(string_text=package_name_column, delimiter_text="'.'", part_number=-1) }}
{%- endmacro %}
