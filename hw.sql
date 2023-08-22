-- 1. Создать таблицу account:
create table account2(account_id BIGSERIAL primary key, name varchar(255), age int);

-- 2. Добавить случайных данных:
insert into account2 (name, age) 
select substr(md5(random()::text), 0, 15) as name, 20 + floor(random() * 50 + 1)::int as age 
from generate_series(1, 1000000);

-- 3. С помощью explain проанализировать запрос:
explain analyze select name from account2 where name like 'a%' order by name asc;

-- План выполнения запроса:

-- "Gather Merge  (cost=16052.02..20778.98 rows=40514 width=15) (actual time=162.820..202.646 rows=50355 loops=1)"
-- "  Workers Planned: 2"
-- "  Workers Launched: 2"
-- "  ->  Sort  (cost=15052.00..15102.64 rows=20257 width=15) (actual time=140.408..142.781 rows=16785 loops=3)"
-- "        Sort Key: name"
-- "        Sort Method: quicksort  Memory: 1840kB"
-- "        Worker 0:  Sort Method: quicksort  Memory: 994kB"
-- "        Worker 1:  Sort Method: quicksort  Memory: 1064kB"
-- "        ->  Parallel Seq Scan on account2  (cost=0.00..13603.00 rows=20257 width=15) (actual time=0.023..74.462 rows=16785 loops=3)"
-- "              Filter: (((name)::text ~~ 'a%'::text) AND (age > 30))"
-- "              Rows Removed by Filter: 316548"
-- "Planning Time: 0.232 ms"
-- "Execution Time: 204.775 ms"

-- Анализ плана запроса

-- Планировщик выбирает план выполнения запроса и применяет метод доступа Parallel Seq Scan к таблице account2. 
-- Parallel Seq scan предполагает последовательное чтение всей таблицы в несколько процессов.
-- Основной  процесс последовательного сканирования в узле Gather 
-- порождает 2-а рабочих процесса, каждый из рабочих процессов читает свою часть данных таблицы account2. 
-- После чтения результаты 2-х рабочих процессов объединяются с результатом процесса в узле Gather. 
-- Получается итоговая отсортированная выборка данных с указанным условием отбора.

-- Каждым процесс применяет условие фильтрации данных (((name)::text ~~ 'a%'::text) AND (age > 30). 
-- Заданное условие отфильтровывает 316548 строк в таблице в каждом из 3-х процессах.
-- Итого результирующая выборка содержит 16785 в каждом из 3-х процессов. 


-- 4. Придумать индекс, который сможет его ускорить добавить индекс и проверить, что он ускорил запрос.		

-- Для ускорения выполнения запроса создадим покрывающих индекс.

create index account2_name_index on account2 using btree(name text_pattern_ops) INCLUDE(age);

-- План выполения запроса после создания покрывающего индекса:
			
-- "Sort  (cost=5593.16..5714.70 rows=48616 width=15) (actual time=27.866..31.670 rows=50355 loops=1)"
-- "  Sort Key: name"
-- "  Sort Method: quicksort  Memory: 3726kB"
-- "  ->  Index Only Scan using account2_name_index on account2  (cost=0.42..1808.62 rows=48616 width=15) (actual time=0.032..11.999 rows=50355 loops=1)"
-- "        Index Cond: ((name ~>=~ 'a'::text) AND (name ~<~ 'b'::text))"
-- "        Filter: ((name)::text ~~ 'a%'::text)"
-- "        Heap Fetches: 0"
-- "Planning Time: 0.111 ms"
-- "Execution Time: 33.651 ms"		

-- Итого время выполения запроса в среднем сократилось примерно в 6 раз.
		
