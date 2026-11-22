-- проверка пустых utm_source по каналам и неделям

select
    toStartOfWeek(started_at) as week,
    source,
    count() as visits,
    countIf(
        utm_source is null
        or trim(utm_source) = ''
    ) as missing_utm,
    round(
        missing_utm * 100.0 / visits, 2
    ) as missing_pct,
    if(missing_pct > 1, 'ALERT', 'OK') as status
from web_visits
where source != 'SEO'
group by week, source
order by week, source;

-- проверка значений utm_source вне справочника

select
    'utm_source' as field,
    utm_source as value,
    count() as visits
from web_visits
where utm_source is not null
  and trim(utm_source) != ''
  and utm_source not in (
      'vk', 'yandex', 'instagram', 'bloggers', 'telegram', 'qr'
  )
group by value
union all
-- проверка значений utm_medium вне справочника
select
    'utm_medium' as field,
    utm_medium as value,
    count() as visits
from web_visits
where utm_medium is not null
  and trim(utm_medium) != ''
  and utm_medium not in (
      'cpc', 'offline', 'influencer'
  )
group by utm_medium
order by visits desc;

-- проверка разных написаний utm_campaign внутри каналов

select
    source,
    lower(
        replaceAll(trim(utm_campaign), '-', ' ')
    ) as normalized_campaign,
    countDistinct(utm_campaign) as variants,
    groupArray(distinct utm_campaign) as raw_values,
    count() as visits
from web_visits
where utm_campaign is not null
  and trim(utm_campaign) != ''
group by source, normalized_campaign
having variants > 1
order by variants desc, visits desc;

-- проверка некорректного регистра и пробелов в utm_source

select
    utm_source,
    count() as visits
from web_visits
where utm_source is not null
  and utm_source != lower(trim(utm_source))
group by utm_source
order by visits desc;

-- проверка разных написаний одного utm_source внутри канала

select
    source,
    lower(trim(utm_source)) as normalized_source,
    countDistinct(utm_source) as variants,
    groupArray(distinct utm_source) as raw_values
from web_visits
where utm_source is not null
  and trim(utm_source) != ''
group by source, normalized_source
having variants > 1
order by variants desc;

-- проверка соответствия каналов между визитами и расходами

select
    channel,
    sum(visits) as visits,
    sum(spend) as spend,
    if(
        visits = 0 or spend = 0,
        'ALERT',
        'OK'
    ) as status
from (
    select
        lower(trim(source)) as channel,
        count() as visits,
        0 as spend
    from web_visits
    group by channel

    union all

    select
        lower(trim(channel)) as channel,
        0 as visits,
        sum(spend_rub) as spend
    from marketing_spend
    group by channel
)
group by channel
having visits = 0 or spend = 0
order by channel;

-- проверка падения недельного трафика более чем на 30%

with weekly as(
    select
        toStartOfWeek(started_at) as week,
        utm_source,
        count() as visits
    from web_visits
    group by week, utm_source
),
check_data as(
    select
        week,
        utm_source,
        visits,
        avg(visits) over
        (
            partition by utm_source
            order by toUInt32(week)
            rows between 4 preceding and 1 preceding
        ) as avg_previous
    from weekly
)
select
    week,
    utm_source,
    visits,
    round(avg_previous, 0) as avg_previous,
    round(
        visits * 100.0 / avg_previous, 2
    ) as pct_of_average,
    if(
        visits < avg_previous * 0.7,
        'ALERT',
        'OK'
    ) as status

-- проверка: визиты с заказом, у которых нет заказа в order_items
-- порог: больше 3% за неделю (обычный фон 1,9%)
select
    week,
    count()                                      as orders,
    countIf(not found)                           as not_found,
    round(not_found * 100.0 / orders, 2)         as pct_not_found,
    if(pct_not_found > 3, 'ALERT', 'ok')         as status
from (
    select
        toStartOfWeek(started_at, 1) as week,
        toInt64OrNull(order_id) as oid,
        oid in (select order_id from order_items where order_id is not null) as found
    from web_visits
    where order_id != ''
      and started_at < toStartOfWeek(now(), 1)  
    group by week, oid
)
group by week
order by week;
from check_data
where avg_previous > 0 and week < '2026-09-13'
order by week, utm_source;
