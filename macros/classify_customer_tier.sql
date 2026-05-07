{% macro classify_customer_tier(lifetime_value_column) %}
    case
        when {{ lifetime_value_column }} >= 500  then 'platinum'
        when {{ lifetime_value_column }} >= 200  then 'gold'
        when {{ lifetime_value_column }} >= 50   then 'silver'
        else 'bronze'
    end
{% endmacro %}
