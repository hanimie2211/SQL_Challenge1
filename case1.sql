CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
-- 1. What is the total amount each customer spent at the restaurant?
select members.customer_id, sum(menu.price) as total_spent
from members 
join sales on members.customer_id = sales.customer_id
join menu on sales.product_id = menu.product_id
group by members.customer_id;

-- 2. How many days has each customer visited the restaurant?
select members.customer_id, count(distinct(sales.order_date)) as number_days_visited
from members
join sales on members.customer_id = sales.customer_id
group by members.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select members.customer_id, (
	select menu.product_name
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id
    order by sales.order_date asc
    limit 1
) as first_purchased_item, (
	select sales.order_date
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id
    order by sales.order_date asc
    limit 1
) as first_purchased_date
from members;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name, count(*) as total_purchases
from sales
join menu on sales.product_id = menu.product_id
group by menu.product_name
order by count(*) desc
limit 1;

-- 5. Which item was the most popular for each customer?
select members.customer_id, (
	select menu.product_name
	from sales
	join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id
	group by menu.product_name
	order by count(*) desc
    limit 1
) as most_popular_item, (
	select count(*)
	from sales
	join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id
	group by menu.product_name
	order by count(*) desc
    limit 1
) as total_purchases
from members;

-- 6. Which item was purchased first by the customer after they became a member?
select members.customer_id, (
	select menu.product_name
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id and sales.order_date > members.join_date
    order by sales.order_date asc
    limit 1
) as first_item_after_member, (
	select sales.order_date
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id and sales.order_date > members.join_date
    order by sales.order_date asc
    limit 1
) as first_purchase_date_after_member
from members;

-- 7. Which item was purchased just before the customer became a member?
select members.customer_id, (
	select menu.product_name
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id and sales.order_date < members.join_date
    order by sales.order_date desc
    limit 1
) as last_item_before_member, (
	select sales.order_date
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id and sales.order_date < members.join_date
    order by sales.order_date desc
    limit 1
) as last_date_before_member
from members;

-- 8. What is the total items and amount spent for each member before they became a member?
select members.customer_id, count(distinct(menu.product_id)) as total_items_before_member, sum(menu.price) as total_spent_before_member
from members
join sales on members.customer_id = sales.customer_id
join menu on sales.product_id = menu.product_id
where sales.order_date < members.join_date
group by members.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select members.customer_id,
(
	select sum(menu.price) * 10
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id and menu.product_name not like 'sushi'
) +
(
	select sum(menu.price) * 10 * 2
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id and menu.product_name like 'sushi'
) as total_points
from members;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select members.customer_id,
(
	select coalesce(sum(menu.price), 0) * 10
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id 
    and datediff(sales.order_date, members.join_date) >= 7
    and sales.order_date <= '2021-01-31'
) +
(
	select coalesce(sum(menu.price), 0) * 10 * 2
    from sales
    join menu on sales.product_id = menu.product_id
    where sales.customer_id = members.customer_id 
    and datediff(sales.order_date, members.join_date) between 0 and 6
) as total_points_in_janurary
from members;