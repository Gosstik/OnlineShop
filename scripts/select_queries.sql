-- 1. GROUP BY + HAVING.
-- Хотим для каждого способа оплаты который использовали хотя бы 15 раз, найти количество его
-- использования с начала 2022 года. Вывод сортируем по убыванию количества использований.
-- (нужна, чтобы посмотреть часто используемые способы оплаты)
select payment_way, count(order_id) as count
from (select payment_way, order_id
      from osh.order
      where extract(year from order_dt) >= 2022
     ) as t
group by payment_way
having count(order_id) >= 15
order by count
;

-- 2. ORDER BY.
-- Хотим вывести имя, дату рождения, номер телефона и email всех женщин-клиентов,
-- у которых указан email, отсортировав по имени и почте.
-- (нужна, если хотим сделать рассылку по почте какого-нибудь предложения или акции)
select name, birthday_dt, phone, email
from osh.client
where 1=1
  and email <> 'N'
  and gender = 'F'
order by name, email
;

-- 3. <funk>=RANK, OVER(ORDER BY)
-- Хотим получить для каждого клиента сумму, котрую он потратил за всё время существования магазина,
-- и вывести топ 10 из них, отсортировав по убыванию суммы.
-- (нужна, если хотим как-то поощрить активных покупателей)
with client_scrap as (
    select client_id, product_hist_id, count
    from osh.product_in_order join osh.order using (order_id) join osh.client using (client_id)
), product_scrap as (
    select client_id, sum(count * price) as total_amount
    from client_scrap join osh.product using (product_hist_id)
    group by client_id
)
select rank() over(order by total_amount desc) as rank, client_id, name, total_amount
from product_scrap join osh.client using (client_id)
limit(10)
;


-- 4. <funk>=(LEAD, LAG), OVER(ORDER BY)
-- Вывести доход компании за каждый месяц, а также для каждого месяца результат
-- предыдущего месяца, следующего месяца и разницу между текущим месяцем и ими.
-- (нужна, чтобы оценить скорость развития магазина)
with months as (
    select to_char(generate_series(min(order_dt), max(order_dt), '1 month'::interval), 'YYYY-MM') as month
    from osh.order
), main_t as (
    select
        month as period,
        coalesce(sum(price * count), 0::money) as cur_month
    from months mnth
        left join osh.order ord on mnth.month = to_char(ord.order_dt, 'YYYY-MM')
        left join osh.product_in_order using (order_id)
        left join osh.product using (product_hist_id)
    group by month
    order by period
), with_offset as (
    select *,
        lead(cur_month, 1, 0::money) over peroid_window as next_month,
        lag(cur_month, 1, 0::money) over peroid_window as prev_month
    from main_t
    window
        peroid_window as (order by period)
)
select *,
       cur_month - next_month as next_month_diff,
       cur_month - prev_month as prev_month_diff
from with_offset
;


-- 5. <funk>=(SUM, MIN, MAX), OVER(PARTITION BY + ORDER BY)
-- Для каждого продукта, который на данный момент есть в магазине, вывести его id, имя,
-- категорию, производителя, суммарную стоимость продуктов в этой категории, максимальную и минимальную
-- цену товара в этой категории и сегмент этого продукта относительно максимальной и минимальной
-- стоимости (budget, medium и premium). После этого отсортировать по убыванию суммарной стоимости,
-- сегменту, стоимости товара.
-- (нужна, чтобы узнать категории самых дорогих и самых дешёвых товаров в магазине, а также поделить
-- товары на категории по цене)
with cur_product as (
    select *
    from osh.product
    where 1=1
        and valid_from_dt <= 'now'::date
        and valid_to_dt >= 'now'::date
), agg_table as (
    select
        product_id,
        name,
        category_nm,
        price,
        sum(price) over category_window as total_price,
        max(price) over category_window as max_price,
        min(price) over category_window as min_price
    from cur_product
    window
        category_window as (partition by category_nm
                            order by category_nm
                            rows between unbounded preceding and unbounded following)
), main_table as (
    select
        product_id,
        name,
        category_nm,
        price,
        case
            when min_price + (max_price - min_price) / 3 > price
                then 'budget'
            when min_price + (max_price - min_price) * 2 / 3 > price
                then 'medium'
            else
                'premium'
            end as segment,
        total_price,
        max_price,
        min_price
    from agg_table
)
select *
from main_table
order by total_price desc, category_nm, price desc, name
;


-- 6. <funk>=(AVG), OVER(PARTITION BY)
-- Вывести все названия товаров, а также их производителей по убыванию рейтинга
-- предоставляемых ими товаров по каждой категории.
-- (чтобы определить лучшие товары и их производителей)
with cur_product as (
    select *
    from osh.product
    where 1=1
      and valid_from_dt <= 'now'::date
      and valid_to_dt >= 'now'::date
), rated as (
    select
        name,
        category_nm,
        manufacturer_nm,
        avg(rating) over rating_window as avg_rate
    from cur_product
    window
        rating_window as (partition by manufacturer_nm, category_nm)
)
select
    name,
    category_nm,
    manufacturer_nm,
    round(avg_rate, 2) as avg_rate
from rated
order by avg_rate desc
;
