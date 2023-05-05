create schema zomato;
use zomato;

create table golden_users
(
userid int primary key,
gold_users_signupdate date
);

insert into golden_users
values
(1,'2017-09-22'),
(3,'2017-04-21');

create table users
(
userid int primary key,
signup_date date
);

insert into users
values 
(1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

create table products
(
product_id int primary key,
product_name varchar(50),
price int
);

insert into products
values 
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

create table sales
(
userid int,
orderdate date,
product_id int
);

insert into sales
values 
(1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);