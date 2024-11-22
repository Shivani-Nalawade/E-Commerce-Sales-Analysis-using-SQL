--Basic Questions
--Q1. What is the total number of customers in the customer_Details table?
select 
	count(distinct [Customer Id]) as total_customers 
from 
	Customer_Details

--Q2. How many orders were placed in total?
select 
	count(distinct [Order Id]) as total_orders 
from
	Order_Details

--Q3. What are the distinct product categories sold?
select 
	distinct [Category Name] 
from 
	Customer_Details

--Q4. What is the total sales amount across all orders?
select 
	sum(Sales) total_sales 
from 
	Order_Details

--Q5. What is the average sales value per order?
select 
	[Order Id], avg(Sales) as avg_sales 
from
	Order_Details
group by 
	[Order Id]

--Q6. List each country and the number of customers in each.
select 
	[Customer Country], count([Customer name]) as total_customers 
from
	Customer_Details
group by 
	[Customer Country]

--Q7. How many orders were placed in each region?
select 
	[Order Region], count([Order Id]) as total_orders 
from 
	Order_Details
group by 
	[Order Region]

--Q8. What is the minimum, maximum, and average product price in the order_details table?
select 
	avg([Product Price]) as avg_price, min([Product Price]) as min_price, max([Product Price]) as max_price 
from Order_Details

--Q9. List each customer segment and the total sales for each.
select 
	[Customer Segment],sum([Sales]) as total_sales
from 
	Customer_Details 
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id] 
group by 
	[Customer Segment]

--Q10. List each product category and the total quantity sold for each.
select 
	[Category Name], sum([Order Quantity]) as total_quantity 
from 
	Customer_Details 
join Order_Details on Customer_Details.[Customer Id] = Order_Details.[Customer Id]
group by 
	[Category Name]

--Intermediate Questions
--Q1. What is the total sales per month to analyze seasonality?
select 
	YEAR([Order Date]) as Order_Year, MONTH([Order Date]) as Order_Month, round(sum([Sales]),2) as Total_Sales
from 
	Order_Details
group by 
	YEAR([Order Date]), MONTH([Order Date])
order by 
	Order_Year, Order_Month

--Q2. What is the average profit margin for each product category?
select 
	[Category Name], round(avg([Profit Margin]),2) as profit_margin
from	
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Category Name]

--Q3. Calculate total sales and profit by customer country.
select 
	[Customer Country], round(sum([Sales]),2) as total_sales, round(sum([Profit Per Order]),2) as total_profit 
from
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Customer Country]

--Q4. Identify customers who placed more than one order (repeat customers).
select 
	Customer_Details.[Customer Id], [Customer name], count([Order Id]) as order_count 
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by  
	Customer_Details.[Customer Id],[Customer name]
having 
	count([Order Id]) > 1
order by 
	order_count desc

--Q5. What is the total sales amount for each customer segment?
select 
	[Customer Segment], sum([Sales]) as total_sales 
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Customer Segment]

--Q6. How many orders were placed in each region, broken down by month?
select 
	[Order Region], YEAR([Order Date]) as order_year, MONTH([Order Date]) as order_month, count([Order Id]) as total_orders
from 
	Order_Details
group by 
	[Order Region], YEAR([Order Date]), MONTH([Order Date])
order by 
	[Order Region], order_year, order_month

--Q7. What is the most popular product category in each country, based on sales?
with CountryCategorySales as
(
select 
	[Customer Country], [Category Name], sum([Sales]) as total_sales,
	ROW_NUMBER() over(partition by [Customer Country] order by sum([Sales]) desc) as sales_rank
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Customer Country], [Category Name]
)

select 
	[Customer Country], [Category Name], total_sales 
from 
	CountryCategorySales
where 
	sales_rank = 1
order by 
	[Customer Country]

--Q8. Calculate the average profit margin for orders with different product price ranges (e.g., <$50, $50-$100, >$100).
select 
	case 
		when [Product Price] < 50 then '<$50'
		when [Product Price] between 50 and 100 then '$50-$100'
		else '>$100'
	end as Price_Range,
	avg([Profit Margin]) as avg_profit_margin
from 
	Order_Details
group by 
	case 
		when  [Product Price] < 50 then '<$50'
		when [Product Price] between 50 and 100 then '$50-$100'
		else '>$100'
		end
		order by Price_Range

--Q9. Calculate total profit for each product category in each region.
select 
	[Order Region], [Category Name], sum([Profit Per Order]) as total_profit 
from 
	Order_Details
join Customer_Details on Customer_Details.[Customer Id] = Order_Details.[Customer Id]
group by 
	[Order Region], [Category Name]
order by 
	[Order Region], [Category Name]

--Advanced Questions
--Q1. Identify the top 5 customers in terms of sales within each product category.
with Ranked_sales as
(
select 
	[Customer name], [Category Name], sum([Sales]) as total_sales, 
	RANK() over(partition by [Category Name] order by sum([Sales]) desc) as rank_sales 
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Customer name], [Category Name]
)

select 
	[Customer name], [Category Name], total_sales, rank_sales 
from 
	Ranked_sales
where
	rank_sales <= 5
order by 
	 [Category Name], rank_sales

--Q2. What is the customer lifetime value (CLTV) for each customer based on average sales per order and total number of orders?
select 
	[Customer name], 
	count([Order Id]) as total_orders, 
	avg([Sales]) as avg_sales_per_order,
	count([Order Id]) * avg([Sales]) as CLTV
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by
	[Customer name]
order by 
	CLTV desc	

--Q3. Calculate the year-over-year sales growth to analyze trends.
WITH YearlySales AS (
SELECT 
	YEAR([Order Date]) AS Sales_Year,
    SUM(Sales) AS Total_Sales
FROM 
     Order_Details
GROUP BY 
     YEAR([Order Date])
),
YearlyGrowth AS (
SELECT 
	Sales_Year,
    Total_Sales,
	LAG(Total_Sales) OVER (ORDER BY Sales_Year) AS Previous_Year_Sales,
CASE 
    WHEN LAG(Total_Sales) OVER (ORDER BY Sales_Year) IS NOT NULL THEN
    ((Total_Sales - LAG(Total_Sales) OVER (ORDER BY Sales_Year)) * 100.0 / LAG(Total_Sales) OVER (ORDER BY Sales_Year))
    ELSE 
      NULL
    END AS YoY_Growth_Percentage
FROM 
    YearlySales
)
SELECT 
    Sales_Year,
    Total_Sales,
    Previous_Year_Sales,
    YoY_Growth_Percentage
FROM 
    YearlyGrowth
ORDER BY 
    Sales_Year

--Q4. Find the top 3 product categories with the highest profit margins in each region.
with CategoryProfit as
(
select 
	[Category Name], [Order Region], avg([Profit Margin]) as Avg_Profit_Margin ,
	rank() over(partition by [Order Region] order by avg([Profit Margin]) desc) as Profit_rank 
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Category Name], [Order Region]
)
select 
	[Order Region], [Category Name], Avg_Profit_Margin, Profit_rank
from
	CategoryProfit
where
	Profit_rank <= 3
order by 
	[Order Region], Profit_rank

--Q5. What is the total sales and profit per month for each product category to analyze seasonality?
select 
	[Category Name], YEAR([Order Date]) as Order_year, MONTH([Order Date]) as Order_month, 
	sum([Sales]) as total_sales, sum([Profit Per Order]) as total_profit
from 
	Customer_Details
join Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by
	[Category Name], YEAR([Order Date]), MONTH([Order Date])
order by 
	[Category Name], Order_year, Order_month

--Q6. Identify customers whose average sales amount per order is above the overall average sales amount.
with CustomerAverageSales as
(
select 
	[Customer name], avg([Sales]) as Avg_Sales_Per_Order
from 
	Customer_Details
join 
	Order_Details on Customer_Details.[Customer Id] = Order_Details.[Customer Id]
group by
	[Customer name]
),
OverallAverageSales as
(
select 
	avg([Sales]) as Overall_Avg_Sales
from 
	Order_Details
)
select 
	[Customer name], Avg_Sales_Per_Order, Overall_Avg_Sales
from
	CustomerAverageSales
cross join
	OverallAverageSales
where
	Avg_Sales_Per_Order > Overall_Avg_Sales
order by 
	Avg_Sales_Per_Order desc

--Q7. Calculate the return on investment (ROI) for each product category if profit per order and sales data are available.
select 
	[Category Name], sum([Sales]) as total_sales, sum([Profit Per Order]) as total_profit,
	case
		when sum(sales) > 0 then
			 (sum([Profit Per Order]) * 100) / sum([Sales])
		else
			0
		end as ROI_Percentage
from
	Customer_Details
join
	Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by
	[Category Name]
order by 
	ROI_Percentage desc

--Q8. Which product category shows the highest sales volatility month over month?
with MonthlySales as
(
select
	[Category Name], YEAR([Order Date]) as Order_year, MONTH([Order Date]) as Order_month, sum([Sales]) as total_monthly_sales
from
	Customer_Details 
join 
	Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Category Name], YEAR([Order Date]), MONTH([Order Date])
),

CategoryVolatility as
(
select
	[Category Name], STDEV(total_monthly_sales) as Sales_Volatility
from
	MonthlySales
group by 
	[Category Name]
)

select top 1
	[Category Name], Sales_Volatility
from
	CategoryVolatility
order by
	Sales_Volatility desc

--Q9. Identify the top 3 customer segments contributing the most to overall sales growth.
with YearlySales as
(
select 
	[Customer City], YEAR([Order Date]) as Order_year, sum([Sales]) as Total_yearly_sales
from 
	Customer_Details
join 
	Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Customer City], YEAR([Order Date])
),
SalesGrowth as
(
select
	ys1.[Customer City],ys1. Order_year, ys1.Total_yearly_sales as Current_Year_Sales, ys2.Total_yearly_sales as Previous_Yearly_Sales,
	case
		when ys2.Total_yearly_sales > 0 then
			((ys1.Total_yearly_sales - ys2.Total_yearly_sales) * 100) / ys2.Total_yearly_sales
		else
			null
		end as YOY_Growth_Percentage
	from
		YearlySales ys1
	left join 
		YearlySales ys2
		on ys1.[Customer City] = ys2.[Customer City]
		and ys1.Order_year = ys2.Order_year + 1
),

CityContribution as
(
select 
	[Customer City], sum(YOY_Growth_Percentage) as Total_Growth_Contribution
from
	SalesGrowth
where
	YOY_Growth_Percentage is not null
group by
	[Customer City]
)
select top 3
	[Customer City], Total_Growth_Contribution
from
	CityContribution
order by 
	Total_Growth_Contribution desc

--Q10. Calculate the percentage of total sales each city contributes, and identify the top 3 city with the largest shares.
with CountrySales as
(
select
	[Customer City], sum([Sales]) as total_sales
from
	Customer_Details
join 
	Order_Details on Order_Details.[Customer Id] = Customer_Details.[Customer Id]
group by 
	[Customer City]
),
TotalSales as
(
select
	sum([total_sales]) as Overall_sales
from 
	CountrySales
)
select top 3
	[Customer City], total_sales, (total_sales* 100) / Overall_sales as Sales_Percentage
from
	CountrySales
cross join 
	TotalSales
order by 
	Sales_Percentage desc

