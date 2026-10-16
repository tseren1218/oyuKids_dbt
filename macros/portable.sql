{#  SingleStore (prod) ба DuckDB (локал тест) хоёуланд ажиллах macro-ууд.
    SingleStore-д array/lambda/PCRE ашиглахгүй — бүгд энгийн MySQL маягийн функц.  #}

{# --- cast (SingleStore: `:>` оператор) --- #}
{% macro to_int(x) %}{{ return(adapter.dispatch('to_int', 'oyu_flywheel')(x)) }}{% endmacro %}
{% macro default__to_int(x) %}cast({{ x }} as bigint){% endmacro %}
{% macro singlestore__to_int(x) %}({{ x }} :> BIGINT){% endmacro %}

{% macro to_double(x) %}{{ return(adapter.dispatch('to_double', 'oyu_flywheel')(x)) }}{% endmacro %}
{% macro default__to_double(x) %}cast({{ x }} as double){% endmacro %}
{% macro singlestore__to_double(x) %}({{ x }} :> DOUBLE){% endmacro %}

{% macro to_text(x) %}{{ return(adapter.dispatch('to_text', 'oyu_flywheel')(x)) }}{% endmacro %}
{% macro default__to_text(x) %}cast({{ x }} as varchar){% endmacro %}
{% macro singlestore__to_text(x) %}({{ x }} :> TEXT){% endmacro %}

{% macro to_ts(x) %}{{ return(adapter.dispatch('to_ts', 'oyu_flywheel')(x)) }}{% endmacro %}
{% macro default__to_ts(x) %}cast({{ x }} as timestamp){% endmacro %}
{% macro singlestore__to_ts(x) %}({{ x }} :> DATETIME(6)){% endmacro %}

{% macro to_date(x) %}{{ return(adapter.dispatch('to_date', 'oyu_flywheel')(x)) }}{% endmacro %}
{% macro default__to_date(x) %}cast({{ x }} as date){% endmacro %}
{% macro singlestore__to_date(x) %}date({{ x }}){% endmacro %}

{% macro to_bool(x) %}{{ return(adapter.dispatch('to_bool', 'oyu_flywheel')(x)) }}{% endmacro %}
{% macro default__to_bool(x) %}cast({{ x }} as boolean){% endmacro %}
{% macro singlestore__to_bool(x) %}({{ x }} <> 0){% endmacro %}

{% macro nl() %}{{ return(adapter.dispatch('nl', 'oyu_flywheel')()) }}{% endmacro %}
{% macro default__nl() %}chr(10){% endmacro %}
{% macro singlestore__nl() %}char(10){% endmacro %}

{# --- Монгол текст normalize: жижиг үсэг, цэг тэмдэг хасах, нэг зай --- #}
{% macro normalize_mn(col) %}{{ return(adapter.dispatch('normalize_mn', 'oyu_flywheel')(col)) }}{% endmacro %}
{% macro default__normalize_mn(col) -%}
trim(regexp_replace(regexp_replace(lower({{ col }}), '[^\p{L}\p{N}\s]', '', 'g'), '\s+', ' ', 'g'))
{%- endmacro %}
{% macro singlestore__normalize_mn(col) -%}
{#- Jinja for-loop scope → namespace ашиглана -#}
{%- set ns = namespace(expr='lower(' ~ col ~ ')') -%}
{%- for ch in ['.', ',', '!', '?', ';', ':', '"', "''", '«', '»', '—', '–', '-', '(', ')', '…'] -%}
  {%- set ns.expr = "replace(" ~ ns.expr ~ ", '" ~ ch ~ "', '')" -%}
{%- endfor -%}
{%- for ch in ['char(10)', 'char(13)', 'char(9)'] -%}
  {%- set ns.expr = "replace(" ~ ns.expr ~ ", " ~ ch ~ ", ' ')" -%}
{%- endfor -%}
{%- for _ in range(3) -%}
  {%- set ns.expr = "replace(" ~ ns.expr ~ ", '  ', ' ')" -%}
{%- endfor -%}
trim({{ ns.expr }})
{%- endmacro %}

{# --- Үгийн түвшний ажиллагаа (array-гүй) --- #}
{% macro word_count(col) -%}
case when {{ col }} is null or {{ col }} = '' then 0
     else length({{ col }}) - length(replace({{ col }}, ' ', '')) + 1 end
{%- endmacro %}

{% macro nth_word(col, n) %}{{ return(adapter.dispatch('nth_word', 'oyu_flywheel')(col, n)) }}{% endmacro %}
{% macro default__nth_word(col, n) %}split_part({{ col }}, ' ', {{ n }}){% endmacro %}
{% macro singlestore__nth_word(col, n) %}substring_index(substring_index({{ col }}, ' ', {{ n }}), ' ', -1){% endmacro %}

{% macro has_word(haystack, word) %}{{ return(adapter.dispatch('has_word', 'oyu_flywheel')(haystack, word)) }}{% endmacro %}
{% macro default__has_word(haystack, word) %}(strpos(concat(' ', {{ haystack }}, ' '), concat(' ', {{ word }}, ' ')) > 0){% endmacro %}
{% macro singlestore__has_word(haystack, word) %}(locate(concat(' ', {{ word }}, ' '), concat(' ', {{ haystack }}, ' ')) > 0){% endmacro %}

{% macro agg_words(col, order_col, sep) %}{{ return(adapter.dispatch('agg_words', 'oyu_flywheel')(col, order_col, sep)) }}{% endmacro %}
{% macro default__agg_words(col, order_col, sep) %}string_agg({{ col }}, '{{ sep }}' order by {{ order_col }}){% endmacro %}
{% macro singlestore__agg_words(col, order_col, sep) %}group_concat({{ col }} order by {{ order_col }} separator '{{ sep }}'){% endmacro %}

{% macro json_str(col, key) %}{{ return(adapter.dispatch('json_str', 'oyu_flywheel')(col, key)) }}{% endmacro %}
{% macro default__json_str(col, key) %}json_extract_string({{ col }}, '$.{{ key }}'){% endmacro %}
{% macro singlestore__json_str(col, key) %}json_extract_string({{ col }}, '{{ key }}'){% endmacro %}

{# --- Нууцлал ба split --- #}
{% macro pseudonymize(col) -%}
md5(concat('{{ var("pseudo_salt") }}', {{ to_text(col) }}))
{%- endmacro %}

{% macro hex_bucket(col) %}{{ return(adapter.dispatch('hex_bucket', 'oyu_flywheel')(col)) }}{% endmacro %}
{% macro default__hex_bucket(col) %}(cast(('0x' || substr({{ col }}, 1, 8)) as bigint) % 100){% endmacro %}
{% macro singlestore__hex_bucket(col) %}((conv(substr({{ col }}, 1, 8), 16, 10) :> BIGINT) % 100){% endmacro %}

{# Speaker-ээр train/dev/test → нэг хүүхэд хоёр split-д орохгүй #}
{% macro split_by_speaker(speaker_col) -%}
case when {{ hex_bucket(speaker_col) }} < 80 then 'train'
     when {{ hex_bucket(speaker_col) }} < 90 then 'dev'
     else 'test' end
{%- endmacro %}
