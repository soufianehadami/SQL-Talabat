DROP TABLE IF EXISTS driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


DROP TABLE IF EXISTS ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

DROP TABLE IF EXISTS  rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

DROP TABLE IF EXISTS  rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

DROP TABLE IF EXISTS  driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time timestamp,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


DROP TABLE IF EXISTS  customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date timestamp);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

--1. How many rolls were ordered?
SELECT COUNT(*) rolls_ordered
FROM customer_orders

--2. How many unique customers are made?

SELECT COUNT(DISTINCT customer_id) unique_customers
FROM customer_orders

--3. How many succesful orders delivered by each driver?

SELECT driver_id,SUM(orders_delivered) succesful_orders
FROM 
(SELECT driver_id,COUNT(DISTINCT order_id) orders_delivered,
       CASE WHEN cancellation LIKE '%Cancellation' THEN 'c'
       ELSE 'not c'
       END cancellation_details
FROM driver_order
GROUP BY driver_id,cancellation)a
WHERE cancellation_details = 'not c'
GROUP BY driver_id

-- 4.Which customers ordered the most amount of rolls and which kind?

SELECT customer_id,roll_name,rolls_ordered
FROM 
    (SELECT customer_id,roll_name,rolls_ordered,RANK () OVER(ORDER BY rolls_ordered DESC)
FROM
    (SELECT c.customer_id,r.roll_name,COUNT(c.order_id) rolls_ordered
    FROM customer_orders c JOIN rolls r ON c.roll_id = r.roll_id
    GROUP BY c.customer_id,r.roll_name)a)b
WHERE b.rank = 1


--5. How many of each type of roll was delivered?

SELECT roll_name,SUM(rolls_delivered)
FROM
(SELECT r.roll_name,COUNT(*) rolls_delivered,
    CASE WHEN d.cancellation LIKE '%Cancellation' THEN 'c'
    ELSE 'not c'
    END cancellation_details
FROM rolls r
JOIN customer_orders c ON r.roll_id=c.roll_id
JOIN driver_order d ON d.order_id = c.order_id
GROUP BY r.roll_name,d.cancellation) a
WHERE cancellation_details = 'not c'
GROUP BY roll_name

--6. How many veg and non veg rolls vere ordered by each customer?

SELECT c.customer_id,r.roll_name,COUNT(r.roll_id) orders
FROM rolls r JOIN customer_orders c ON r.roll_id =c.roll_id
GROUP BY c.customer_id,r.roll_name


--7. What was the maximum number of rolls delivered in a single order?

SELECT MAX(rolls_delivered) max_rolls_delivered
FROM 
(SELECT c.order_id,COUNT(r.roll_id) rolls_delivered,
       CASE WHEN d.cancellation LIKE '%Cancellation' THEN 'c'
       ELSE 'not c'
       END cancellation_details
FROM rolls r JOIN customer_orders c ON r.roll_id =c.roll_id
             JOIN driver_order d ON d.order_id =c.order_id
GROUP BY c.order_id,d.cancellation)a
WHERE cancellation_details ='not c'

--8. For each customer how many delivered rolls had at least one change and how many had no change?

WITH temp_cust_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) AS
(SELECT order_id,customer_id,roll_id, 
    CASE WHEN not_include_items is null OR not_include_items = ''
    THEN '0' ELSE not_include_items END not_include_clean,
    CASE WHEN extra_items_included is null OR extra_items_included = '' OR extra_items_included = 'NaN'
    THEN '0' ELSE extra_items_included END extra_items_clean,
 order_date
FROM customer_orders),

temp_driver_order (order_id,driver_id,pickup_time,distance,new_cancellation) AS 
(SELECT order_id,driver_id,pickup_time,distance,
    CASE WHEN cancellation LIKE '%Cancellation%' THEN 0 ELSE 1 END new_cancellation
 FROM driver_order)

SELECT customer_id,SUM(rolls)total_rolls,if_changed
FROM 
(SELECT c.customer_id,COUNT(r.roll_id) rolls,
             CASE WHEN c.not_include_items <>'0' OR c.extra_items_included <>'0' THEN 'changed'
             ELSE 'not changed'
             END if_changed
FROM rolls r JOIN temp_cust_orders c ON r.roll_id=c.roll_id
             JOIN temp_driver_order d ON d.order_id = c.order_id
WHERE new_cancellation <>0
GROUP BY c.customer_id,c.not_include_items,c.extra_items_included)a    
GROUP BY customer_id,if_changed
ORDER BY customer_id


--9. How many rolls were delivered that had both exclusions and extras?

WITH temp_cust_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) AS
(SELECT order_id,customer_id,roll_id, 
    CASE WHEN not_include_items is null OR not_include_items = ''
    THEN '0' ELSE not_include_items END not_include_clean,
    CASE WHEN extra_items_included is null OR extra_items_included = '' OR extra_items_included = 'NaN'
    THEN '0' ELSE extra_items_included END extra_items_clean,
 order_date
FROM customer_orders),

temp_driver_order (order_id,driver_id,pickup_time,distance,new_cancellation) AS 
(SELECT order_id,driver_id,pickup_time,distance,
    CASE WHEN cancellation LIKE '%Cancellation%' THEN 0 ELSE 1 END new_cancellation
 FROM driver_order)
 
SELECT if_changed,SUM(rolls)rolls_delivered
FROM
(SELECT r.roll_id,COUNT(c.order_id)rolls,
        CASE WHEN c.not_include_items<>'0' AND c.extra_items_included<> '0' THEN 'both inc ex'
        ELSE 'either 1 ex or inc'
        END if_changed
FROM rolls r JOIN temp_cust_orders c ON r.roll_id=c.roll_id
             JOIN temp_driver_order d ON d.order_id=c.order_id
WHERE d.new_cancellation <>0   
GROUP BY r.roll_id,c.not_include_items,c.extra_items_included,d.new_cancellation) a
GROUP BY if_changed
       
--10. What was the total number of rolls ordered for each hour of the day?

SELECT hours_bucket,COUNT(*)rolls_ordered
FROM
(SELECT*, CONCAT(CAST(DATE_PART('hour',order_date) as VARCHAR),'-',CAST(DATE_PART('hour',order_date)+1 AS VARCHAR))hours_bucket
FROM customer_orders)a
GROUP BY hours_bucket
ORDER BY hours_bucket

--11. What was the number of orders for each day of the week?

SELECT TO_CHAR(order_date,'Day') weekday ,COUNT(DISTINCT order_id) orders
from customer_orders
GROUP BY weekday