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
select
    round(sum(orders * v_yandex    / total)) as yandex,
    round(sum(orders * v_vk        / total)) as vk,
    round(sum(orders * v_seo       / total)) as seo,
    round(sum(orders * v_instagram / total)) as instagram,
    round(sum(orders * v_bloggers  / total)) as bloggers,
    round(sum(orders * v_outdoor   / total)) as outdoor,
    round(sum(orders * v_telegram  / total)) as telegram
from (
    select
        loyalty_id,
        count()                                as total,
        countIf(order_id != '')                as orders,
        countIf(source = 'Яндекс Директ')      as v_yandex,
        countIf(source = 'VK Реклама')         as v_vk,
        countIf(source = 'SEO')                as v_seo,
        countIf(source = 'Instagram* Реклама') as v_instagram,
        countIf(source = 'Блогеры')            as v_bloggers,
        countIf(source = 'Наружная реклама')   as v_outdoor,
        countIf(source = 'Telegram Ads')       as v_telegram
    from web_visits
    group by loyalty_id
);
