{% macro classify_customer_tier(lifetime_value_column) %}
    case
        when {{ lifetime_value_column }} >= {{ var('platinum_threshold') }} then 'platinum'
        when {{ lifetime_value_column }} >= {{ var('gold_threshold') }}     then 'gold'
        when {{ lifetime_value_column }} >= {{ var('silver_threshold') }}   then 'silver'
        else 'bronze'
    end
{% endmacro %}
