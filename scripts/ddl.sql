create schema osh;

set postgresql.conf.lc_monetary to "ba-RU.utf8";
-- select 10::money;

create table if not exists osh.client (
    client_id integer,
    name varchar(100) not null,
    gender varchar(1) default 'N',
    birthday_dt date default '9999-12-31',
    phone varchar(20) not null,
    email varchar(120) default 'N',

    constraint PK_client primary key (client_id),
    constraint CHK_client_gender check (gender in ('M', 'F', 'N')),
    constraint CHK_client_phone check (phone ~* '\+[0-9]+$'),
    constraint CHK_client_email check (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$|^N$')
);

create table if not exists osh.order (
    order_id integer,
    client_id integer,
    order_dt timestamp not null,
    payment_way varchar(6) not null,

    constraint PK_order primary key (order_id),
    constraint FK_order_clt_id foreign key (client_id) references osh.client(client_id)
        on delete cascade
        on update cascade,
    constraint CHK_order_payment_way check (payment_way in ('cash', 'card', 'online'))
);

create table if not exists osh.courier (
    courier_id integer,
    name varchar(100) not null,
    gender varchar(1) not null,
    birthday_dt date default '9999-12-31',
    phone varchar(20) not null,
    email varchar(120) not null,

    constraint PK_courier primary key (courier_id),
    constraint CHK_courier_gender check (gender in ('M', 'F')),
    constraint CHK_courier_phone check (phone ~* '\+[0-9]+$'),
    constraint CHK_courier_email check (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

create table if not exists osh.order_delivery (
    order_id integer,
    courier_id integer,

    constraint PK_order_delivery primary key (order_id, courier_id),
    constraint FK_order_delivery_order_id foreign key (order_id) references osh.order(order_id)
        on delete cascade
        on update cascade,
    constraint FK_order_delivery_courier_id foreign key (courier_id) references osh.courier(courier_id)
        on delete cascade
        on update cascade
);

create table if not exists osh.manufacturer (
    manufacturer_nm varchar(100),
    phone varchar(20) not null,
    email varchar(120) not null,
    country varchar(40) not null,

    constraint PK_manufacturer primary key (manufacturer_nm),
    constraint CHK_manufacturer_phone check (phone ~* '\+[0-9]+$'),
    constraint CHK_manufacturer_email check (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

create table if not exists osh.category (
    category_nm varchar(50),
    creation_dt date not null,

    constraint PK_category primary key (category_nm)
);

create table if not exists osh.product (
    product_hist_id integer,
    product_id integer,
    name varchar(70) not null,
    category_nm varchar(50),
    price money not null,
    manufacturer_nm varchar(100),
    rating integer,
    valid_from_dt timestamp not null,
    valid_to_dt timestamp not null,

    constraint PK_product primary key (product_hist_id),
    constraint FK_product_category_nm foreign key (category_nm) references osh.category(category_nm)
        on delete cascade
        on update cascade,
    constraint FK_product_manufacturer_nm foreign key (manufacturer_nm) references osh.manufacturer(manufacturer_nm)
        on delete cascade
        on update cascade,
    constraint CHK_product_rating check (rating between 1 and 5)
);

create table if not exists osh.product_in_order (
    order_id integer,
    product_hist_id integer,

    count integer,

    constraint PK_product_in_order primary key (order_id, product_hist_id),
    constraint FK_order_delivery_order_id foreign key (order_id) references osh.order(order_id)
        on delete cascade
        on update cascade,
    constraint FK_product_in_order_product_id foreign key (product_hist_id) references osh.product(product_hist_id)
        on delete cascade
        on update cascade
);
