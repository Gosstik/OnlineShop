-- CRUD-запросы для таблицы manufacturer.

-- Смотрим содержимое.
select *
from osh.manufacturer
;

-- Выводим имена и телефоны всех производителей из России.
select manufacturer_nm, phone
from osh.manufacturer
where country = 'Russia'
;

-- Оставляем только производителей из России, Беларуси и Китая.
delete from osh.manufacturer
where country not in ('Russia', 'Belarus', 'China')
;

-- Обновляем почтовый домен у одного из производителей.
update osh.manufacturer
set email = 'Veon@yandex.com'
where manufacturer_nm = 'Veon'
;

--------------------------------------------------------------

-- CRUD-запросы для таблицы category.

-- Смотрим содержимое.
select *
from osh.category
;

-- Выводим названия категорий с датой создания после начала 2020 года.
select category_nm
from osh.category
where extract(year from creation_dt) > 2019
;

-- Удаляем категории, созданные до февраля 2019 года.
delete from osh.category
where creation_dt < '2019-02-01'
;

-- Обновляем название одной из категорий.
update osh.category
set category_nm = 'electronics and technics'
where category_nm = 'electronics'
;
