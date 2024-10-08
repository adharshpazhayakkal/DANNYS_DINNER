CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 #1. What is the total amount each customer spent at the restaurant?
 SELECT s.customer_id, SUM(m.price) AS total_amount FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY s.customer_id;
 
 #2. How many days has each customer visited the restaurant?
 SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS visit_days FROM sales s GROUP BY s.customer_id;
 
 #3. What was the first item from the menu purchased by each customer?
 SELECT s.customer_id, s.product_id, m.product_name FROM sales s JOIN menu m ON s.product_id = m.product_id WHERE (s.customer_id, s.order_date) IN (SELECT customer_id, MIN(order_date) FROM sales GROUP BY customer_id);
 
 #4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 SELECT m.product_name, COUNT(s.product_id) AS purchase_count FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY s.product_id, m.product_name ORDER BY purchase_count DESC LIMIT 1;
 
 #5) Which item was the most popular for each customer?
 SELECT s.customer_id, s.product_id, m.product_name, COUNT(*) AS purchase_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id, m.product_name
HAVING COUNT(*) = (
  SELECT MAX(purchase_count)
  FROM (
    SELECT s1.customer_id, s1.product_id, COUNT(*) AS purchase_count
    FROM sales s1
    GROUP BY s1.customer_id, s1.product_id
  ) AS item_counts
  WHERE item_counts.customer_id = s.customer_id
);

#6. Which item was purchased first by the customer after they became a member?
WITH Rankedsales as (select s.customer_id,s.order_date,s.product_id,m.product_name,row_number() over(partition by s.customer_id order by s.order_date) as rn  from sales as s join menu as m on s.product_id=m.product_id join members as memb on s.customer_id=memb.customer_id where s.order_date>memb.join_date) select customer_id,
  order_date,
  product_id,
  product_name
FROM
  RankedSales
WHERE
  rn = 1
ORDER BY
  customer_id,
  rn;
  
  ##7)Which item was purchased just before the customer became a member?
  WITH PreMembershipPurchases AS (
  SELECT s.customer_id, s.product_id, s.order_date,
         ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
  FROM sales s
  JOIN members m ON s.customer_id = m.customer_id
  WHERE s.order_date < m.join_date
)
SELECT pmp.customer_id, pmp.product_id, m.product_name, pmp.order_date
FROM PreMembershipPurchases pmp
JOIN menu m ON pmp.product_id = m.product_id
WHERE pmp.rn = 1;

#8. What is the total number of items and amount spent for each member before they became a member?
select s.customer_id,count(s.product_id), sum(m.price) from sales as s join menu as m on s.product_id=m.product_id join members as memb on s.customer_id=memb.customer_id where s.order_date<memb.join_date group by  s.customer_id;

#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
  s.customer_id,SUM(CASE WHEN m.product_name = 'sushi' THEN m.price * 10 * 2 ELSE m.price * 10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
