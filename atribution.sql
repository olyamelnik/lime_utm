-- атрибуция

-- последний визит
select source as channel, uniqIf(order_id, order_id != '') as orders
from web_visits
group by source
order by orders desc;

--первый визит
select first_ch as channel, sum(orders) as orders
from (
    select loyalty_id,
           argMin(source, started_at) as first_ch,
           uniqIf(order_id, order_id != '') as orders
    from web_visits
    group by loyalty_id
)
group by first_ch
order by orders desc;

--линейная
select first_ch as channel, sum(orders) as orders
from (
    select loyalty_id,
           argMin(source, started_at) as first_ch,
           uniqIf(order_id, order_id != '') as orders
    from web_visits
    group by loyalty_id
)
group by first_ch
order by orders desc;
