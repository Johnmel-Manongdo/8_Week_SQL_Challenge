/*
Case Study Questions
Each of the following case study questions can be answered using a single SQL statement:

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?
*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
    sales.customer_id, 
    SUM(menu.price) AS total_spent
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
    customer_id, 
    COUNT(DISTINCT(order_date)) AS total_days_spent
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH ordered_rank AS (
    SELECT 
        sales.customer_id, 
        sales.order_date,
	menu.product_name,
	DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS date_rank
    FROM sales
    INNER JOIN menu ON sales.product_id = menu.product_id
)

SELECT 
    customer_id, 
    order_date, 
    product_name
FROM ordered_rank
WHERE date_rank = 1
GROUP BY customer_id, order_date, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    menu.product_name,
    COUNT(sales.product_id) AS total_order
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_order DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH order_info AS (
    SELECT 
        sales.customer_id, 
        menu.product_name,
        COUNT(sales.product_id) AS total_count,
        DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.customer_id) DESC) AS ranking
  FROM sales
  INNER JOIN menu ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
)
	
SELECT 
    customer_id, 
    total_count, 
    product_name
FROM order_info
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH after_join_date AS (
    SELECT 
        sales.customer_id, 
        menu.product_name,
        sales.order_date, 
        members.join_date,
        RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS ranking
    FROM sales
    INNER JOIN members ON sales.customer_id = members.customer_id
    INNER JOIN menu ON sales.product_id = menu.product_id
    WHERE members.join_date <= sales.order_date
)

SELECT 
    customer_id, 
    product_name, 
    order_date, 
    join_date
FROM after_join_date
WHERE ranking = 1
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?

WITH before_join_date AS (
    SELECT 
        sales.customer_id, 
        menu.product_name,
        sales.order_date, 
        members.join_date,
        RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS ranking
    FROM sales
    INNER JOIN members ON sales.customer_id = members.customer_id
    INNER JOIN menu ON sales.product_id = menu.product_id
    WHERE members.join_date > sales.order_date
)

SELECT 
    customer_id, 
    product_name, 
    order_date, 
    join_date
FROM before_join_date
WHERE ranking = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
    sales.customer_id,
    COUNT(sales.product_id) AS total_items,
    SUM(menu.price) AS total_amount
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE members.join_date > sales.order_date
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_points AS (
    SELECT
        sales.customer_id,
        menu.price,
        CASE
            WHEN menu.product_name = "sushi" THEN (menu.price * 10) * 2
            ELSE menu.price * 10
	END AS points
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
)

SELECT 
    customer_id,
    SUM(price) AS total_spent,
    SUM(points) AS total_points
FROM cte_points
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?		

WITH cte_date AS (
    SELECT
        join_date,
        DATE_ADD(join_date, INTERVAL 6 DAY) AS one_week,
        customer_id,
        LAST_DAY(join_date) AS end_of_month
    FROM members
)

SELECT 
    sales.customer_id,
    SUM(CASE 
            WHEN order_date BETWEEN join_date AND one_week THEN price * 10 * 2
            ELSE price * 10
	END) AS points
FROM menu
INNER JOIN sales ON menu.product_id = sales.product_id
INNER JOIN cte_date ON cte_date.customer_id = sales.customer_id
WHERE sales.order_date >= cte_date.join_date
AND sales.order_date <= cte_date.end_of_month
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- BONUS QUESTIONS
-- Join All The Things

SELECT 
    sales.customer_id, 
    sales.order_date,  
    menu.product_name, 
    menu.price,
    CASE
        WHEN sales.order_date >= members.join_date THEN 'Y'
        ELSE 'N' END AS member
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date;

-- Rank All The Things

WITH cte_ranking AS (
    SELECT 
        sales.customer_id, 
        sales.order_date,  
        menu.product_name, 
        menu.price,
        CASE
            WHEN sales.order_date >= members.join_date THEN 'Y'
            ELSE 'N' 
        END AS member
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date
)

SELECT 
    *,
    CASE
        WHEN member = 'N' THEN NULL
        ELSE DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
    END AS ranking
FROM cte_ranking



