# postgres-indexes
homework on the ProductStar platform

В прикрепленных файлах с выполенным домашним задание будет создана таблица account2, так как используется база данных с предыщего урока в которой 
таблица account уже присутствует.

1. Создать таблицу account:

create table account(account_id BIGSERIAL primary key, name varchar(255), age int);

2. Добавить случайных данных:

insert into account (name, age) select substr(md5(random()::text), 0, 15) as name, 20 + floor(random() * 50 + 1)::int as age from generate_series(1, 1000000);

3. С помощью explain проанализировать запрос:

explain analyze select name from account where name like 'a%' and age > 30 order by name asc;

4. Придумать индекс, который сможет его ускорить добавить индекс и проверить, что он ускорил запрос.
