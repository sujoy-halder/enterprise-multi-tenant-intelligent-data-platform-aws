{% macro platform_surrogate_key(fields) -%}
    md5(concat_ws('||'
    {%- for field in fields -%}
        , coalesce(cast({{ field }} as varchar), '')
    {%- endfor -%}
    ))
{%- endmacro %}
