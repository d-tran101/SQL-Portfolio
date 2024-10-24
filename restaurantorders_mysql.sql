-- most ordered items per category

WITH category_items_ranking as (
SELECT 
	mi.category, 
	mi.item_name, 
	COUNT(od.item_id) AS n_order_items, 
	RANK() OVER(PARTITION BY mi.category ORDER BY COUNT(od.item_id) DESC) AS n_ordered_items_ranking
FROM menu_items mi
INNER JOIN order_details od ON mi.menu_item_id = od.item_id
GROUP BY mi.category, mi.item_name
)
select 
	category, 
	item_name,
    n_order_items
FROM category_items_ranking
WHERE n_ordered_items_ranking = 1

-- least ordered items per category 

WITH category_items_ranking as (
SELECT 
	mi.category, 
	mi.item_name, 
	COUNT(od.item_id) AS n_order_items, 
	RANK() OVER(PARTITION BY mi.category ORDER BY COUNT(od.item_id)) AS n_ordered_items_ranking
FROM menu_items mi
INNER JOIN order_details od ON mi.menu_item_id = od.item_id
GROUP BY mi.category, mi.item_name
)
select 
	category, 
	item_name,
    n_order_items
FROM category_items_ranking
WHERE n_ordered_items_ranking = 1

-- what are the top 5 highest spending orders look like? which items did they buy and how much did they spend

WITH order_id_ranking as (
SELECT 
	od.order_id, 
	SUM(mi.price) as total_price,
	DENSE_RANK() OVER(ORDER BY SUM(mi.price) desc) AS total_price_ranking
FROM menu_items mi
	INNER JOIN order_details od on mi.menu_item_id = od.item_id
GROUP BY od.order_id
)
SELECT 
	od.order_id, 
	mi.category, 
    mi.item_name, mi.price, 
    SUM(mi.price) OVER(PARTITION BY order_id) as total_prices_of_order_id
FROM menu_items mi
INNER JOIN order_details od ON mi.menu_item_id = od.item_id
WHERE od.order_id IN (SELECT order_id
		from order_id_ranking
		where total_price_ranking <=5)

-- were there certain times that had more or less orders?
SELECT 
	DATE_FORMAT(od.order_time, '%h %p') as hour_of_day, 
	COUNT(DISTINCT od.order_id) as total_unique_orders,
    DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT od.order_id) DESC) as time_ranking
FROM menu_items mi
INNER JOIN order_details od ON mi.menu_item_id = od.item_id
GROUP BY DATE_FORMAT(od.order_time, '%h %p')

-- were there certain days that had more or less orders?

SELECT 
	CASE
		WHEN DAYOFWEEK(od.order_date) = 1 then 'Sunday'
        WHEN DAYOFWEEK(od.order_date) = 2 then 'Monday'
        WHEN DAYOFWEEK(od.order_date) = 3 then 'Tuesday'
        WHEN DAYOFWEEK(od.order_date) = 4 then 'Wednesday'
        WHEN DAYOFWEEK(od.order_date) = 5 then 'Thursday'
        WHEN DAYOFWEEK(od.order_date) = 6 then 'Friday'
        WHEN DAYOFWEEK(od.order_date) = 7 then 'Saturday'
	END as day_name,
	COUNT(DISTINCT od.order_id) as total_unique_orders,
    DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT od.order_id) DESC) as day_ranking
FROM menu_items mi
INNER JOIN order_details od ON mi.menu_item_id = od.item_id
GROUP BY 1

-- what is the average order cost per customer?

SELECT ROUND(AVG(mi.price),2)
FROM menu_items mi
	INNER JOIN order_details od on mi.menu_item_id = od.item_id

-- which cuisines should we focus on developing more menu items for based on the data?

SELECT 
	mi.category, 
	SUM(mi.price) as total_revenue_per_category,
    COUNT(mi.menu_item_id) as total_order_per_category,
    SUM(mi.price) / COUNT(DISTINCT od.order_id) as average_revenue_per_order
FROM menu_items mi
INNER JOIN order_details od ON mi.menu_item_id = od.item_id
GROUP BY mi.category

-- what is the rolling total of sales for each week?

SELECT 
	EXTRACT(week from od.order_date) as week, 
	SUM(SUM(mi.price)) OVER(ORDER BY EXTRACT(week from od.order_date)) as sales_rolling_total
FROM menu_items mi
	INNER JOIN order_details od on mi.menu_item_id = od.item_id
GROUP BY EXTRACT(week from od.order_date)
ORDER BY EXTRACT(week from od.order_date)

-- what is the rolling total of sales for each month?

SELECT 
	EXTRACT(month from od.order_date) as month, 
	SUM(SUM(mi.price)) OVER(ORDER BY EXTRACT(month from od.order_date)) as sales_rolling_total
FROM menu_items mi
	INNER JOIN order_details od on mi.menu_item_id = od.item_id
GROUP BY EXTRACT(month from od.order_date)
ORDER BY EXTRACT(month from od.order_date)



