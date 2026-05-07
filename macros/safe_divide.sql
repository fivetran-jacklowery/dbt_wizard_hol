{% macro safe_divide(numerator, denominator, default=0) %}
    iff({{ denominator }} = 0, {{ default }}, {{ numerator }} / {{ denominator }})
{% endmacro %}
