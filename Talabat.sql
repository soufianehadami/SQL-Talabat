DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

DROP TABLE IF EXISTS users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

DROP TABLE IF EXISTS sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


DROP TABLE IF EXISTS product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


--1. What is the total amount each customer spent on Talabat?

SELECT s.userid,SUM(p.price) total_amt_spent
FROM   sales s JOIN product p
ON s.product_id= p.product_id
GROUP BY s.userid
ORDER BY total_amt_spent 

--2. How many days has each customer visited Talabat?

SELECT userid, COUNT(DISTINCT created_date) days
FROM sales
GROUP BY userid

--3. What was the first product purchased by each customer?

SELECT product_id FROM 
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date)
FROM sales)r
WHERE r.rank=1

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT userid,COUNT(product_id) cnt
FROM sales 
WHERE  product_id = (SELECT product_id
FROM sales 
GROUP BY product_id,userid
ORDER BY COUNT(product_id) DESC
LIMIT 1)
GROUP BY userid

--5. Which item was the most popular item for each customer?

select userid,product_id FROM
(SELECT userid,product_id,cnt,RANK() OVER(PARTITION BY userid ORDER BY cnt DESC) 
FROM (SELECT userid,product_id,COUNT(product_id) cnt
FROM sales
GROUP BY userid,product_id ) r)s
WHERE s.rank=1



--6. Which item was purchased first by the customer after they became a member?

SELECT userid,product_id FROM
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date)
FROM
(SELECT s.userid,s.product_id,s.created_date
FROM sales s
JOIN goldusers_signup g ON g.userid = s.userid
WHERE s.created_date>= g.gold_signup_date) a) b
WHERE b.rank=1

--7. Which item was purchased last before the customer became a member?

SELECT userid,product_id FROM
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date DESC)
FROM
(SELECT s.userid,s.product_id,s.created_date
FROM sales s
JOIN goldusers_signup g ON g.userid = s.userid
WHERE s.created_date<= g.gold_signup_date) a) b
WHERE b.rank=1

--8. What is the total orders and the amount spent by each member after the became a member?

SELECT s.userid,SUM(p.price)amt_spent,COUNT(s.product_id) total_orders
FROM sales s 
JOIN product p ON s.product_id = p.product_id
JOIN goldusers_signup g ON g.userid=s.userid
AND s.created_date<= g.gold_signup_date
GROUP BY s.userid


--9. If buying each product generates points. For ex $5 = 2 Talabat points and each product has
--different purchasing points. For p1 $5=1 Talabat point,for p2 $10=5 Talabat points,for p3 $5=1 Talabat point.
--Calcuate points collected by each customer and for which product most points have been given till now?

SELECT product_id,points
FROM(SELECT s.product_id,SUM(p.price),
    CASE WHEN s.product_id = 1 OR s.product_id = 3 THEN SUM(p.price)/5 
    ELSE SUM(p.price)/2
    END points
FROM sales s JOIN product p ON s.product_id = p.product_id
GROUP BY s.product_id)a
ORDER BY points DESC
LIMIT 1

--10.In the first one year after a customer joins the gold program (including their join date) irrespective
--of what the customer has purchased they earn 5 Talabat points for every $10 spent. Who earned more 1 or 3 
--and what was their point earnings in their first year?

SELECT s.userid,SUM(p.price)/2 points,s.created_date
   FROM product p 
JOIN sales s ON s.product_id = p.product_id
JOIN goldusers_signup g ON s.userid = g.userid
WHERE s.created_date>=g.gold_signup_date
AND s.created_date<=g.gold_signup_date+365
GROUP BY s.userid,s.created_date