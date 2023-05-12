-- 1. (сокрытие полей) Посмотреть имена и дату рождения курьеров с сокрытием их контактных номеров телефона.
create or replace view osh.v_courier_public as
select
    name,
    birthday_dt,
    regexp_replace(phone, '^\+([0-9]{4}).*([0-9]{2})$', '+\1 ***** \2') as phone
from osh.courier
;

select *
from osh.v_courier_public
;

-- 2. (сокрытие полей) Вывести имена клиентов, их пол (в отформатированном виде) и электронную почту с
-- сокрытием имени, оставляя только домен. В ячейках, где отсутствуют данные, вывести `unspecified`.
create or replace view osh.v_client_public as
select
    name,
    case
        when gender like 'M'
            then 'male'
        when gender like 'F'
            then 'female'
        else
            'unspecified'
        end as gender,
    case
        when email like 'N'
            then 'unspecified'
        else
            regexp_replace(email, '^.*(@.*)$', '*****\1')
        end as email
from osh.client
;

select *
from osh.v_client_public
;

-- 3. (соединение таблиц) Выводим общую информацию о заказе: имя клиента, имя курьера, дату заказ
-- и их контактные телефоны в удобном для чтения виде.
create or replace view osh.v_order_details as
select
    clt.name as client_name,
    crr.name as courier_name,
    ord.order_dt as order_date,
    regexp_replace(clt.phone, '^\+7([0-9]{3})([0-9]{3})([0-9]{2})([0-9]{2})$', '+7 (\1) \2 \3 \4') as client_phone,
    regexp_replace(crr.phone, '^\+7([0-9]{3})([0-9]{3})([0-9]{2})([0-9]{2})$', '+7 (\1) \2 \3 \4') as courier_phone
from osh.client clt
         join osh.order ord using (client_id)
         join osh.order_delivery ord_dlv using (order_id)
         join osh.courier crr using (courier_id)
;

select *
from osh.v_order_details
;

-- 4. (соединение таблиц) Выводим продукт, его категорию и имя его производителя с контактной
-- информацией в удобном для чтения формате.
create or replace view osh.v_product_manufacturer as
select
    prd.name,
    prd.category_nm as category,
    mnf.manufacturer_nm as manufacturer,
    regexp_replace(mnf.phone, '^\+7([0-9]{3})([0-9]{3})([0-9]{2})([0-9]{2})$', '+7 (\1) \2 \3 \4') as manufacturer_phone,
    mnf.email as manufacturer_email
from osh.product prd
         join osh.manufacturer mnf using (manufacturer_nm)
;

select *
from osh.v_product_manufacturer
;

-- 5. (соединение таблиц) Выводим имя клиента, его email и количество денег, которые он
-- потратил за всё время в магазине, сортируя по имени.
create or replace view osh.v_client_expenses as
with client_scrap as (
    select
        client_id,
        product_hist_id,
        count
    from osh.product_in_order prd_ord
             join osh.order ord using (order_id)
             join osh.client clt using (client_id)
), product_scrap as (
    select
        client_id,
        sum(count * price) as total_amount
    from client_scrap clt_scr
             join osh.product prd using (product_hist_id)
    group by client_id
)
select
    name,
    total_amount
from product_scrap prd_scr
         join osh.client clt using (client_id)
order by name
;

select *
from osh.v_client_expenses
;

-- 6. (соединение таблиц) Выводим количество и суммарную стоимость товаров за каждый месяц.
create or replace view osh.v_product_sold as
with months as (
    select to_char(generate_series(min(order_dt), max(order_dt), '1 month'::interval), 'YYYY-MM') as month
    from osh.order
)
select
    mnth.month as period,
    coalesce(sum(count), 0) as products_sold,
    coalesce(sum(price * count), 0::money) as total_amount
from months mnth
         left join osh.order ord on mnth.month = to_char(ord.order_dt, 'YYYY-MM')
         left join osh.product_in_order using (order_id)
         left join osh.product using (product_hist_id)
group by month
order by period desc
;

select *
from osh.v_product_sold
;