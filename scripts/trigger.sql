-- Triggers.
-- 1. Триггер по вставке продукта в версионную таблицу. Проверяет, что цена положительна,
-- а также в случае присутствия в таблице продукта с указанным id, создаёт новую запись,
-- а в старой проставляет нужную дату.
create or replace function osh.product_alter()
    returns trigger
    language plpgsql
as $$
begin
    if new.price is null then
        raise exception 'product_id = %: price must not be NULL', new.product_id;
    end if;
    if new.price <= 0 then
        raise exception 'product_id = %: price must be positive', new.product_id;
    end if;

    if new.valid_to_dt = '9999-12-31'::timestamp
        and (select *
             from osh.product prd
             where prd.product_id = new.product_id) is not null then
        update osh.product
        set valid_to = new.valid_from_dt - '1 day'::interval
        where 1=1
          and product_id = new.product_id
          and valid_to_dt = '9999-12-31'::timestamp
        ;
    end if;
    return new;
end;
$$;

create trigger product_alter before insert on osh.product
    for each row execute procedure osh.product_alter();

-- 2. Триггер по увеличению рейтинга товара при его покупке. Считаем, что рейтинг товара
-- зависит от количесвта покупок. На каждые 10 покупок приходится по 0.1 рейтинга. После
-- достижения отметки в 5 баллов рост прекращается.
-- Примечание: количество считается по product_id, а не по product_hist_id.
create or replace function osh.improve_rate()
    returns trigger
    language plpgsql
as $$
declare
    cur_count bigint;
    cur_product_id integer;
begin
    -- initialize `cur_product_id`
    select into cur_product_id
    from osh.product_in_order prd_ord
             join osh.product prd using (product_hist_id);

    -- initialize `cur_count`
    select into cur_count
        sum(count)
    from osh.product_in_order
    where product_hist_id in (select product_hist_id
                              from osh.product prd
                              where prd.product_hist_id = cur_product_id);

    -- update rating
    update osh.product
    set rating = round(cur_count / 10, 1)
    where product_id = cur_product_id;

    return new;
end;
$$;

create trigger improve_rate after insert on osh.product_in_order
    for each row execute procedure osh.improve_rate();