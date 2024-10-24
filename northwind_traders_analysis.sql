-- northwind db


-- 1. top 5 customers that have spent the most on orders

WITH sales_by_customers as (
SELECT 
	c.CustomerID, 
    c.CompanyName, 
    COALESCE(ROUND(SUM(od.quantity * od.unitPrice),2),0) as total_spent,
    DENSE_RANK() OVER(ORDER BY COALESCE(ROUND(SUM(od.quantity * od.unitPrice),2),0) DESC) as total_spent_ranking
FROM customers c
	LEFT JOIN orders o on c.CustomerID = o.CustomerID
    LEFT JOIN order_details od on o.orderID = od.orderID
HAVING COALESCE(ROUND(SUM(od.quantity * od.unitPrice),2),0) <> 0
GROUP BY c.CustomerID, c.CompanyName
)
SELECT CustomerID, CompanyName, total_spent
FROM sales_by_customers
WHERE total_spent_ranking <= 5

-- 2. bottom 5 customers that spent the least on orders excluding those with 0 orders

WITH sales_by_customers as (
SELECT 
	c.CustomerID, 
    c.CompanyName, 
    COALESCE(ROUND(SUM(od.quantity * od.unitPrice),2),0) as total_spent,
    DENSE_RANK() OVER(ORDER BY COALESCE(ROUND(SUM(od.quantity * od.unitPrice),2),0)) as total_spent_ranking
FROM customers c
	LEFT JOIN orders o on c.CustomerID = o.CustomerID
    LEFT JOIN order_details od on o.orderID = od.orderID
GROUP BY c.CustomerID, c.CompanyName
HAVING COALESCE(ROUND(SUM(od.quantity * od.unitPrice),2),0) <> 0
)
SELECT CustomerID, CompanyName, total_spent
FROM sales_by_customers
WHERE total_spent_ranking <= 5

-- 3. amount of orders per customer

SELECT 
	c.companyName, 
	COUNT(DISTINCT o.orderID) as n_orders, 
    ROUND(SUM(od.quantity * od.unitPrice),2) as total_spent_on_orders
FROM customers c 
	INNER JOIN orders o on c.customerID = o.CustomerID
    INNER JOIN order_details od on o.orderID = od.orderID
GROUP BY c.companyName
ORDER BY n_orders DESC

-- 4. products that generated the highest sales revenue

SELECT 
	p.productName, 
    ROUND(SUM(od.quantity * od.unitPrice),2) as total_revenue_per_product
FROM order_details od
	INNER JOIN products p on od.productID = p.productID
GROUP BY p.productName
ORDER BY total_revenue_per_product DESC

-- 5. products that generated the lowest sales revenue

SELECT 
	p.productName, 
    ROUND(SUM(od.quantity * od.unitPrice),2) as total_revenue_per_product
FROM order_details od
	INNER JOIN products p on od.productID = p.productID
GROUP BY p.productName
ORDER BY total_revenue_per_product

-- 6. total revenue for each year (2013, 2014, 2015)

SELECT 
	EXTRACT(YEAR from o.orderDate), 
	ROUND(SUM(od.unitPrice * od.quantity),2) as total_revenue_by_year
from orders o
	inner join order_details od on o.orderID = od.orderID
GROUP BY EXTRACT(YEAR from o.orderDate)
ORDER BY EXTRACT(YEAR from o.orderDate) ASC

-- 7. monthly sales trends: the highest revenue month and the lowest revenue month from monthly_sales CTE

WITH monthly_sales as (
SELECT MONTHNAME(o.orderDate) AS month_name, 
       ROUND(SUM(od.unitPrice * od.quantity), 2) AS total_revenue_by_month
FROM orders o
INNER JOIN order_details od ON o.orderID = od.orderID
GROUP BY MONTH(o.orderDate), MONTHNAME(o.orderDate)
ORDER BY MONTH(o.orderDate)
), monthly_sales_ranking as (
SELECT 
	month_name, 
	total_revenue_per_month,
	RANK() OVER(ORDER BY total_revenue_by_month DESC) rnk
FROM monthly_sales
) 
SELECT month_name, total_revenue_per_month
FROM monthly_sales_ranking
WHERE rnk = 1

UNION

SELECT month_name, total_revenue_per_month
FROM monthly_sales_ranking
WHERE rnk = 12

-- 8. total revenue by category

SELECT 
	c.categoryName, 
    ROUND(SUM(od.unitPrice * od.quantity), 2) as total_revenue_by_category
FROM categories c
	INNER JOIN products p on c.categoryID = p.categoryID
    INNER JOIN order_details od on p.productID = od.productID
GROUP BY c.categoryName

-- 9. total sales per country

SELECT c.country, ROUND(SUM(od.quantity * od.unitPrice),2)
FROM customers c
	LEFT JOIN orders o on c.customerID = o.customerID
    LEFT JOIN order_details od on o.orderID = od.orderID
GROUP BY c.country

-- 10. average number of items per order

SELECT 
	ROUND(AVG(n_quantity),0)
FROM (
	SELECT o.orderID, SUM(od.quantity) as n_quantity
	from orders o
		inner join order_details od on o.orderID = od.orderID
	GROUP BY o.orderID
) as quantity_per_order

-- 11. sales per quarter

SELECT 
	CASE 
		WHEN MONTH(o.orderDate) between 1 and 3 then 'Q1'
        WHEN MONTH(o.orderDate) between 4 and 6 then 'Q2'
        WHEN MONTH(o.orderDate) between 7 and 9 then 'Q3'
        WHEN MONTH(o.orderDate) between 10 and 12 then 'Q4'
        END as quarter,
        ROUND(SUM(od.unitPrice * od.quantity),2) as total_revenue
FROM orders o
	INNER JOIN order_details od on o.orderID = od.orderID
GROUP BY 
	CASE 
		WHEN MONTH(o.orderDate) between 1 and 3 then 'Q1'
        WHEN MONTH(o.orderDate) between 4 and 6 then 'Q2'
        WHEN MONTH(o.orderDate) between 7 and 9 then 'Q3'
        WHEN MONTH(o.orderDate) between 10 and 12 then 'Q4'
        END
ORDER BY
	CASE 
		WHEN MONTH(o.orderDate) between 1 and 3 then 'Q1'
        WHEN MONTH(o.orderDate) between 4 and 6 then 'Q2'
        WHEN MONTH(o.orderDate) between 7 and 9 then 'Q3'
        WHEN MONTH(o.orderDate) between 10 and 12 then 'Q4'
        END

-- 12. what is the first order in each country?

WITH orders_country_ranking as (
SELECT 
	c.companyName, 
    c.country, 
    o.orderDate, 
    o.orderID,
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY o.orderDate) as order_ranking
from customers c
	INNER JOIN orders o ON c.customerID = o.customerID
)
SELECT 
	companyName, 
    country, 
    orderDate, 
    orderID
FROM orders_country_ranking
where order_ranking = 1;
    
-- 13. which customers have placed the most orders and how much did they spend in total?

SELECT 
	c.companyName, 
	COUNT(DISTINCT o.orderID) as n_orders, 
    ROUND(SUM(od.unitPrice * od.quantity),2) as total_spent,
    (COUNT(DISTINCT o.orderID) / SUM(COUNT(DISTINCT o.orderID)) OVER()) * 100.0 as total_orders
from customers c
	INNER JOIN orders o ON c.customerID = o.customerID
    INNER JOIN order_details od ON o.orderID = od.orderID
GROUP BY c.companyName

-- 14. who are the high value customers?

SELECT 
	c.companyName, 
	COUNT(DISTINCT o.orderID) as n_orders,
	CASE
		WHEN COUNT(DISTINCT o.orderID) > 15 THEN 'High Value'
        WHEN COUNT(DISTINCT o.orderID) BETWEEN 10 and 15 THEN 'Medium Value'
        WHEN COUNT(DISTINCT o.orderID) BETWEEN 5 and 9 THEN 'Low Value'
        WHEN COUNT(DISTINCT o.orderID) < 5 THEN 'Very Low Value'
        END as value_rating
FROM customers c
	INNER JOIN orders o on c.customerID = o.customerID
    INNER JOIN order_details od on o.orderID = od.orderID
GROUP BY c.companyName
ORDER BY n_orders DESC


-- 15. what orders were shipped late?

SELECT 
	orderID, 
	customerID, 
    orderDate, 
    requiredDate, 
    shippedDate, 
    shipperID, 
    freight
from orders
WHERE shippedDate > requiredDate

-- 16. late orders and total orders percentage

SELECT 
	COUNT(DISTINCT orderID) as n_late_orders, 
	(SELECT COUNT(DISTINCT orderID) FROM orders) as n_total_orders,
	(COUNT(DISTINCT orderID) / (SELECT COUNT(DISTINCT orderID) FROM orders)) * 100 as late_orders_percentage
FROM orders
WHERE shippedDate > requiredDate

-- 17. what shipping company has the most late orders?

WITH late_orders as (
SELECT 
	orderID, 
	customerID, 
    orderDate, 
    requiredDate, 
    shippedDate, 
    shipperID, 
    freight
from orders
WHERE shippedDate > requiredDate
), late_orders_ranking as (
SELECT 
	s.companyName, 
	COUNT(lo.orderID) as n_orders, 
    RANK() OVER(ORDER BY COUNT(lo.orderID) DESC) as rnk
FROM late_orders lo
	INNER JOIN shippers s on lo.shipperID = s.shipperID
GROUP BY s.companyName
)
SELECT CompanyName, n_orders
from late_orders_ranking
where rnk = 1


-- 18. rolling total sales for each month

SELECT 
	EXTRACT(MONTH from o.orderDate), 
	ROUND(SUM(od.unitPrice * od.quantity),2), 
    ROUND(SUM(SUM(od.unitPrice * od.quantity)) OVER(ORDER BY EXTRACT(MONTH from o.orderDate)),2) as rolling_total_sales
from customers c
	INNER JOIN orders o ON c.customerID = o.customerID
    INNER JOIN order_details od ON o.orderID = od.orderID
GROUP BY EXTRACT(MONTH from o.orderDate)
ORDER BY EXTRACT(MONTH from o.orderDate)

-- 19. country and city with the most orders

SELECT 
	c.country, c.city, 
	COUNT(DISTINCT o.orderID) as n_orders,
    RANK() OVER(ORDER BY COUNT(DISTINCT o.orderID) DESC) as country_city_ranking
FROM customers c
	LEFT JOIN orders o on c.customerID = o.customerID
    LEFT JOIN order_details od on o.orderID = od.orderID
GROUP BY c.country, c.city

-- 20. most orders for each country and what is the city

WITH most_orders as (
SELECT 
	c.country, c.city, 
	COUNT(DISTINCT o.orderID) as n_orders,
    RANK() OVER(PARTITION BY c.country ORDER BY COUNT(DISTINCT o.orderID) DESC) as rnk
FROM customers c
	LEFT JOIN orders o on c.customerID = o.customerID
    LEFT JOIN order_details od on o.orderID = od.orderID
GROUP BY c.country, c.city
)
SELECT 
	country, 
	city, 
    n_orders
FROM most_orders
WHERE rnk = 1

-- 21. employees with the most orders arriving late

SELECT 
	e.employeeName, 
	COUNT(DISTINCT o.orderID) as n_orders
FROM employees e
	INNER JOIN orders o on e.employeeID = o.employeeID
    INNER JOIN order_details od on o.orderID = od.orderID
WHERE o.shippedDate > requiredDate
GROUP BY e.employeeName
ORDER BY n_orders DESC

-- 22. employees that have made the most revenue

SELECT 
	e.employeeName, 
	ROUND(SUM(od.unitPrice * od.quantity),2) as total_revenue
FROM employees e
	INNER JOIN orders o on e.employeeID = o.employeeID
    INNER JOIN order_details od on o.orderID = od.orderID
GROUP BY e.employeeName

-- 23. number of employees per supervisor

SELECT e2.employeeName as Supervisor, 
COUNT(DISTINCT e1.employeeID) as n_employees_reports_to
from employees e1
	inner join employees e2 on e1.reportsTO = e2.employeeID
GROUP BY e2.employeeName

