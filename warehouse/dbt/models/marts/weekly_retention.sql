{#
  Weekly activity and LLM cost per active user, with the user's signup
  cohort and attributes for retention analysis.

  A week's totals keep changing until the week ends, so appending rows would
  double-count. Instead each incremental run recomputes whole weeks from
  `lookback_weeks` before the latest week already in the table, and
  insert_overwrite swaps those week partitions out atomically. Older weeks
  are left untouched.
#}
{% set lookback_weeks = 1 %}

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by='week_of_activity',
        order_by='(week_of_activity, user_id)'
    )
}}

{% set incremental_filter %}
    {% if is_incremental() %}
        and created_at >= (
            select max(week_of_activity) - toIntervalWeek({{ lookback_weeks }})
            from {{ this }}
        )
    {% endif %}
{% endset %}

select
    uc.week_of_creation as week_of_creation,
    ua.week_of_activity as week_of_activity,
    ua.user_id as user_id,
    uc.department as department,
    uc.country as country,
    uc.plan as plan,
    uc.created_at as created_at,
    ua.days_active as days_active,
    ua.total_conversations as total_conversations,
    ua.total_messages as total_messages,
    uco.weekly_cost as weekly_cost,
    uco.total_input_tokens as total_input_tokens,
    uco.total_output_tokens as total_output_tokens
from (
    select
        dateTrunc('week', created_at) as week_of_activity,
        user_id,
        count(distinct dateTrunc('day', created_at)) as days_active,
        count(distinct conversation_id) as total_conversations,
        count(distinct id) as total_messages
    from {{ source('raw', 'raw_messages') }} final
    where role = 'user'
        and _peerdb_is_deleted = 0
        {{ incremental_filter }}
    group by week_of_activity, user_id
) as ua
left join (
    select
        dateTrunc('week', ru.created_at) as week_of_activity,
        ru.user_id as user_id,
        sum(ru.uncached_input_tokens + ru.cached_input_tokens) as total_input_tokens,
        sum(ru.output_tokens) as total_output_tokens,
        sum(
            ((ru.uncached_input_tokens + ru.cached_input_tokens) / 1000) * rm.input_cost_per_1k
            + (ru.output_tokens / 1000) * rm.output_cost_per_1k
        ) as weekly_cost
    from {{ source('raw', 'raw_usage') }} as ru final
    left join {{ source('raw', 'raw_models') }} as rm final
        on ru.model_id = rm.id
    where ru._peerdb_is_deleted = 0
        {{ incremental_filter }}
    group by week_of_activity, user_id
) as uco
    on ua.user_id = uco.user_id
    and ua.week_of_activity = uco.week_of_activity
left join (
    select
        id,
        department,
        country,
        plan,
        created_at,
        dateTrunc('week', created_at) as week_of_creation
    from {{ source('raw', 'raw_users') }} final
    where _peerdb_is_deleted = 0
) as uc
    on ua.user_id = uc.id
