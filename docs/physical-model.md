# Физическая модель

---

Таблица `client`:

| Название      | Описание          | Тип данных     | Ограничение                                                     |
|---------------|-------------------|----------------|-----------------------------------------------------------------|
| `client_id`   | Идентификатор     | `INTEGER`      | `PRIMARY KEY`                                                   |
| `name`        | Имя               | `VARCHAR(100)` | `NOT NULL`                                                      |
| `gender`      | Пол               | `VARCHAR(1)`   | `NOT NULL`                                                      |
|               |                   |                | `DEFAULT 'N'`                                                   |
|               |                   |                | `CHECK IN ('M', 'F', 'N')`                                      |
| `birthday_dt` | Дата рождения     | `DATE`         | `NOT NULL`                                                      |
|               |                   |                | `DEFAULT '9999-12-31`                                           |
| `phone`       | Номер телефона    | `VARCHAR(20)`  | `NOT NULL`                                                      |
|               |                   |                | `CHECK ~* '\+[0-9]+$'`                                          |
| `email`       | Электронная почта | `VARCHAR(120)` | `NOT NULL`                                                      |
|               |                   |                | `DEFAULT 'N'`                                                   |
|               |                   |                | `CHECK ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$\|^N$` |

Таблица `order`:

| Название      | Описание              | Тип данных   | Ограничение                          |
|---------------|-----------------------|--------------|--------------------------------------|
| `order_id`    | Идентификатор заказа  | `INTEGER`    | `PRIMARY KEY`                        |
| `client_id`   | Идентификатор клиента | `INTEGER`    | `FOREIGN KEY`                        |
| `order_dt`    | Дата заказа           | `TIMESTAMP`  | `NOT NULL`                           |
| `payment_way` | Способ оплаты         | `VARCHAR(6)` | `NOT NULL`                           |
|               |                       |              | `CHECK IN ('cash, 'card', 'online')` |

Таблица `courier`:

| Название      | Описание          | Тип данных     | Ограничение                                                |
|---------------|-------------------|----------------|------------------------------------------------------------|
| `courier_id`  | Идентификатор     | `INTEGER`      | `PRIMARY KEY`                                              |
| `name`        | Имя               | `VARCHAR(100)` | `NOT NULL`                                                 |
| `gender`      | Пол               | `VARCHAR(1)`   | `NOT NULL`                                                 |
|               |                   |                | `CHECK IN ('M', 'F')`                                      |
| `birthday_dt` | Дата рождения     | `DATE`         | `NOT NULL`                                                 |
| `phone`       | Номер телефона    | `VARCHAR(20)`  | `NOT NULL`                                                 |
|               |                   |                | `CHECK ~* '\+[0-9]+$'`                                     |
| `email`       | Электронная почта | `VARCHAR(120)` | `NOT NULL`                                                 |
|               |                   |                | `CHECK ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$` |

Таблица `order_delivery`:

| Название     | Описание              | Тип данных | Ограничение   |
|--------------|-----------------------|------------|---------------|
| `order_id`   | Идентификатор заказа  | `INTEGER`  | `PRIMARY KEY` |
|              |                       |            | `FOREIGN KEY` |
| `courier_id` | Идентификатор курьера | `INTEGER`  | `PRIMARY KEY` |
|              |                       |            | `FOREIGN KEY` |

Таблица `manufacturer`:

| Название          | Описание           | Тип данных     | Ограничение                                                |
|-------------------|--------------------|----------------|------------------------------------------------------------|
| `manufacturer_nm` | Имя производителя  | `VARCHAR(100)` | `PRIMARY KEY`                                              |
| `phone`           | Контактный телефон | `VARCHAR(20)`  | `NOT NULL`                                                 |
|                   |                    |                | `CHECK ~* '\+[0-9]+$'`                                     |
| `email`           | Электронная почта  | `VARCHAR(120)` | `NOT NULL`                                                 |
|                   |                    |                | `CHECK ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$` |
| `country`         | Страна             | `VARCHAR(40)`  | `DEFAULT 'N'`                                              |

Таблица `category`:

| Название      | Описание           | Тип данных | Ограничение   |
|---------------|--------------------|------------|---------------|
| `category_nm` | Название категории | `INTEGER`  | `PRIMARY KEY` |
| `creation_dt` | Дата создания      | `INTEGER`  | `NOT NULL`    |

Таблица `product`:

| Название          | Описание                         | Тип данных     | Ограничение            |
|-------------------|----------------------------------|----------------|------------------------|
| `product_hist_id` | Идентификатор состояния продукта | `INTEGER`      | `PRIMARY KEY`          |
| `product_id`      | Идентификатор продукта           | `INTEGER`      | `NOT NULL`             |
| `name`            | Название продукта                | `VARCHAR(70)`  | `NOT NULL`             |
| `category_nm`     | Название категории               | `VARCHAR(50)`  | `FOREIGN KEY`          |
| `price`           | Стоимость                        | `MONEY`        | `NOT NULL`             |
| `manufacturer_nm` | Имя производителя                | `VARCHAR(100)` | `FOREIGN KEY`          |
| `rating`          | Оценка покупателями              | `INTEGER`      |                        |
| `valid_from_dt`   | Дата начала действия             | `TIMESTAMP`    | `NOT NULL`             |
| `valid_to_dt`     | Дата конца действия              | `TIMESTAMP`    | `NOT NULL`             |
|                   |                                  |                | `DEFAULT '9999-12-31'` |

Таблица `product_in_order`:

| Название          | Описание                         | Тип данных | Ограничение   |
|-------------------|----------------------------------|------------|---------------|
| `order_id`        | Идентификатор заказа             | `INTEGER`  | `PRIMARY KEY` |
|                   |                                  |            | `FOREIGN KEY` |
| `product_hist_id` | Идентификатор состояния продукта | `INTEGER`  | `PRIMARY KEY` |
|                   |                                  |            | `FOREIGN KEY` |

---
Таблица `client`:
```postgresql
create table if not exists osh.client (
    client_id   integer,
    name        varchar(100) not null,
    gender      varchar(1)   not null default 'N',
    birthday_dt date         not null default '9999-12-31',
    phone       varchar(20)  not null,
    email       varchar(120) not null default 'N',

    constraint PK_client primary key (client_id),
    constraint CHK_client_gender check (gender in ('M', 'F', 'N')),
    constraint CHK_client_phone check (phone ~* '\+[0-9]+$'),
    constraint CHK_client_email check (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$|^N$')
);
```
Таблица `order`:
```postgresql
create table if not exists osh.order (
    order_id    integer,
    client_id   integer,
    order_dt    timestamp  not null,
    payment_way varchar(6) not null,

    constraint PK_order primary key (order_id),
    constraint FK_order_clt_id foreign key (client_id) references osh.client(client_id)
        on delete cascade
        on update cascade,
    constraint CHK_order_payment_way check (payment_way in ('cash', 'card', 'online'))
);
```
Таблица `courier`:
```postgresql
create table if not exists osh.courier (
    courier_id  integer,
    name        varchar(100) not null,
    gender      varchar(1)   not null,
    birthday_dt date         not null,
    phone       varchar(20)  not null,
    email       varchar(120) not null,

    constraint PK_courier primary key (courier_id),
    constraint CHK_courier_gender check (gender in ('M', 'F')),
    constraint CHK_courier_phone check (phone ~* '\+[0-9]+$'),
    constraint CHK_courier_email check (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);
```
Таблица `order_delivery`:
```postgresql
create table if not exists osh.order_delivery (
    order_id   integer,
    courier_id integer,

    constraint PK_order_delivery primary key (order_id, courier_id),
    constraint FK_order_delivery_order_id foreign key (order_id) references osh.order(order_id)
        on delete cascade
        on update cascade,
    constraint FK_order_delivery_courier_id foreign key (courier_id) references osh.courier(courier_id)
        on delete cascade
        on update cascade
);
```
Таблица `manufacturer`:
```postgresql
create table if not exists osh.manufacturer (
    manufacturer_nm varchar(100),
    phone           varchar(20)  not null,
    email           varchar(120) not null,
    country         varchar(40)  not null,

    constraint PK_manufacturer primary key (manufacturer_nm),
    constraint CHK_manufacturer_phone check (phone ~* '\+[0-9]+$'),
    constraint CHK_manufacturer_email check (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);
```
Таблица `category`:
```postgresql
create table if not exists osh.category (
    category_nm varchar(50),
    creation_dt date        not null,

    constraint PK_category primary key (category_nm)
);
```
Таблица `product`:
```postgresql
create table if not exists osh.product (
    product_hist_id integer,
    product_id      integer     not null,
    name            varchar(70) not null,
    category_nm     varchar(50),
    price           money       not null,
    manufacturer_nm varchar(100),
    rating          integer,
    valid_from_dt   timestamp   not null,
    valid_to_dt     timestamp   not null default '9999-12-31',

    constraint PK_product primary key (product_hist_id),
    constraint FK_product_category_nm foreign key (category_nm) references osh.category(category_nm)
        on delete cascade
        on update cascade,
    constraint FK_product_manufacturer_nm foreign key (manufacturer_nm) references osh.manufacturer(manufacturer_nm)
        on delete cascade
        on update cascade,
    constraint CHK_product_rating check (rating between 1 and 5)
);
```
Таблица `product_in_order`:
```postgresql
create table if not exists osh.product_in_order (
    order_id        integer,
    product_hist_id integer,
    count           integer,

    constraint PK_product_in_order primary key (order_id, product_hist_id),
    constraint FK_order_delivery_order_id foreign key (order_id) references osh.order(order_id)
        on delete cascade
        on update cascade,
    constraint FK_product_in_order_product_id foreign key (product_hist_id) references osh.product(product_hist_id)
        on delete cascade
        on update cascade
);
```