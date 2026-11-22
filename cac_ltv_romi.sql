-- подсчет доли клиентов, заказов, выручки и расходов; индекса «доля выручки / доля расходов»; CAC, LTV, ROMI, LTV/CAC.
with revenue as (
    select a.channel as channel,
           uniqExact(oi.loyalty_id) as buyers,
           uniq(oi.order_id) as orders,
           sum(oi.paid_money_rub + oi.paid_points_rub) as revenue_all,
           sum(oi.paid_money_rub) as revenue_money
    from order_items oi
    join (
        select loyalty_id, any(channel) as channel
        from acquisition_channels
        group by loyalty_id
    ) a on oi.loyalty_id = a.loyalty_id
    group by a.channel
),
count_clients as (
    select channel, uniqExact(loyalty_id) as clients
    from acquisition_channels
    group by channel
),
total_spend as (
    select channel, sum(spend_rub) * 0.2 as spend_sample
    from marketing_spend
    group by channel
)
select
    cl.channel                                                       as channel,
    cl.clients                                                       as clients,
    r.buyers                                                         as buyers,
    r.orders                                                         as orders,
    round(cl.clients * 100.0 / sum(cl.clients) over (), 1)           as clients_pct,
    round(r.orders * 100.0 / sum(r.orders) over (), 1)               as orders_pct,
    round(r.revenue_all * 100.0 / sum(r.revenue_all) over (), 1)     as revenue_pct,
    round(r.revenue_money * 100.0 / sum(r.revenue_money) over (), 1) as revenue_money_pct,
    round(sp.spend_sample * 100.0 / sum(sp.spend_sample) over (), 1) as spend_pct,
    round((r.revenue_all / sum(r.revenue_all) over ()) / (sp.spend_sample / sum(sp.spend_sample) over ()), 2)     as index_all,
    round((r.revenue_money / sum(r.revenue_money) over ()) / (sp.spend_sample / sum(sp.spend_sample) over ()), 2) as index_money,
    round(sp.spend_sample / cl.clients)                              as cac_rub,
    round(r.revenue_money / cl.clients)                              as ltv_rub,
    round((r.revenue_money - sp.spend_sample) * 100.0 / sp.spend_sample, 1) as romi_pct,
    round(r.revenue_money / sp.spend_sample, 2)                      as ltv_cac
from count_clients cl
left join revenue r on cl.channel = r.channel
left join total_spend sp on cl.channel = sp.channel
order by romi_pct desc;

-- подсчет возвращающихся клиентов
select a.channel as channel,
       count() as buyers,
       countIf(c.orders >= 2) as repeaters,
       round(repeaters * 100.0 / buyers, 1) as repeat_pct
from (
    select loyalty_id, uniq(order_id) as orders
    from order_items
    group by loyalty_id
) c
join (
    select loyalty_id, any(channel) as channel
    from acquisition_channels
    group by loyalty_id
) a on c.loyalty_id = a.loyalty_id
group by a.channel
order by repeat_pct desc;
