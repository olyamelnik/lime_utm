with r as (
	select a.channel as channel,
    	count() as buyers,
        sum(c.rev) as revenue,
        countIf(c.orders >= 2) as repeaters
    from (
		select loyalty_id,
        	sum(paid_money_rub + paid_points_rub) as rev,
            uniq(order_id) as orders
        from order_items
        group by loyalty_id
	) c
    join (
    	select loyalty_id, any(channel) as channel
        from acquisition_channels
        group by loyalty_id
	) a on c.loyalty_id = a.loyalty_id
    group by a.channel
),
cl as (
	select channel, uniqExact(loyalty_id) as clients
    from acquisition_channels
    group by channel
),
sp as (
	select channel, sum(spend_rub) * 0.2 as spend_sample
    from marketing_spend
    group by channel
)
select
    cl.channel                                                      as channel,
    cl.clients                                                      as clients,
    r.buyers                                                        as buyers,
    round(sp.spend_sample / cl.clients)                             as cac_rub,
    round(r.revenue / cl.clients)                                   as ltv_rub,
    round((r.revenue - sp.spend_sample) * 100.0 / sp.spend_sample, 1) as romi_pct,
    round(r.repeaters * 100.0 / r.buyers, 1)                        as repeat_pct
from cl
left join r  on cl.channel = r.channel
left join sp on cl.channel = sp.channel
order by romi_pct desc;

