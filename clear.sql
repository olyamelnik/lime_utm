select
    source,
    concat('[', ifNull(utm_source, ''), ']') as utm_source_marked,
    concat('[', ifNull(utm_medium, ''), ']') as utm_medium_marked,
    count() as visits
from web_visits
group by source, utm_source_marked, utm_medium_marked
order by source, visits desc;

select
    if(utm_source is null or utm_source = '', '(пусто)', concat('[', utm_source, ']')) as channel_raw,
    count()                                           as visits,
    uniqExactIf(order_id, order_id != '')             as orders,
    round(orders * 100.0 / visits, 2)                 as conv_pct
from web_visits
group by channel_raw
order by visits desc;

select
    source                                            as channel_fixed,
    count()                                           as visits,
    uniqExactIf(order_id, order_id != '')             as orders,
    round(orders * 100.0 / visits, 2)                 as conv_pct
from web_visits
group by channel_fixed
order by visits desc;

select
    if(utm_source is null or utm_source = '', '(пусто)', concat('[', utm_source, ']')) as channel_raw,
    count()                               as visits,
    uniqExactIf(order_id, order_id != '') as orders
from web_visits
where started_at >= toDateTime('2026-01-19 00:00:00')  
group by channel_raw
order by visits desc