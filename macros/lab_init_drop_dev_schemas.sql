{% macro lab_init_drop_dev_schemas(catalog_name=none, target_schema=none) %}
    {% set cleanup_catalog = catalog_name or target.database %}
    {% set cleanup_schema = target_schema or target.schema %}
    {% set schema_suffixes = ['staging', 'intermediate', 'marts', 'marketing'] %}

    {% if cleanup_catalog is none or cleanup_schema is none %}
        {% do exceptions.raise_compiler_error('lab_init_drop_dev_schemas requires an active catalog/database and target schema.') %}
    {% endif %}

    {% if cleanup_schema | lower in ['hol_2026_retail', 'sf_hol_2026_retail'] %}
        {% do exceptions.raise_compiler_error('Refusing to drop schemas for raw/source schema: ' ~ cleanup_schema) %}
    {% endif %}

    {% for suffix in schema_suffixes %}
        {% set schema_name = cleanup_schema ~ '_' ~ suffix %}
        {% do log('Dropping lab dev schema if exists: ' ~ cleanup_catalog ~ '.' ~ schema_name, info=True) %}
        {% do run_query('drop schema if exists ' ~ adapter.quote(cleanup_catalog) ~ '.' ~ adapter.quote(schema_name) ~ ' cascade') %}
    {% endfor %}
{% endmacro %}
