{#
  In dbt-clickhouse a schema is a ClickHouse database. dbt's default would
  turn `+schema: datamart` into `analytics_datamart`; use the configured
  name as-is so models land in the database created by
  warehouse/clickhouse/init/02_datamart.sql.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
