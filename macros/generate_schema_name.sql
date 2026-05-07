{# 
    Override the default generate_schema_name macro so that custom schema names
    are used as-is in production, while dev/CI runs are still namespaced under
    the target schema to avoid clobbering prod tables.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
