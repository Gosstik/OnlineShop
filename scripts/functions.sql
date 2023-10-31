-- Functions.
-- 1. Функция, принимающая на вход две даты start и finish и выдающая доход
-- компании за данный промежуток времени [start, finish]
create or replace function osh.income_for_period(start date, finish date)
    returns money
    language plpgsql
as $$
declare
    result money;
begin
    select into result
        coalesce(sum(prd.price * prd_ord.count), 0::money) as price_with_count
    from osh.order ord
             join osh.product_in_order prd_ord using (order_id)
             join osh.product prd using (product_hist_id)
    where ord.order_dt between start and finish
    ;

    return result;
end;
$$;

-- test 1.1
select *
from osh.income_for_period('2020-01-01', '2021-12-31')
;

-- test 1.2
select *
from osh.income_for_period('3000-01-01', '4000-12-31')
;

---------------------------------------------------------------------------------------

-- 2. Функция, которая по id заказа выдаёт таблицу из названия предметов, их количества,
-- стоимость одной штуки и суммарную стоимость. Последняя строка - суммарная стоимость заказа.
-- Если заказа с таким id не существует, бросается искличение с кодом 02000.
create or replace function osh.order_info(order_id_arg integer)
    returns table (product_name varchar(70), count integer, per_piece money, total money)
    language plpgsql
as $$
declare
    id_exists integer;
begin
    select order_id into id_exists
    from osh.order as ord
    where ord.order_id = order_id_arg;

    if id_exists is null then
        raise exception 'Order with id "%" does not exist in data base.', order_id_arg
            using errcode = '02000';
    end if;

    return query
        with main as (
            select
                prd.name as product_name_ret,
                prd_ord.count as count_ret,
                prd.price as per_piece_ret,
                prd_ord.count * prd.price as total_ret
            from osh.order ord
                     join osh.product_in_order prd_ord using (order_id)
                     join osh.product prd using (product_hist_id)
            where ord.order_id = order_id_arg
        )
        select *
        from main

        union

        select
            'All' as product_name_ret,
            coalesce(sum(count_ret)::integer, 0) as count_ret,
            coalesce(sum(total_ret), 0::money) as per_piece_ret,
            coalesce(sum(total_ret), 0::money) as total_ret
        from main
    ;
end; $$;

-- test 1.1
select *
from osh.order_info(10113)
;

-- test 1.2
select *
from osh.order_info(1)
;