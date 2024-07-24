use gdb023;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select 
	distinct market
from dim_customer c
where customer="Atliq Exclusive" and region="APAC";



/* 2. What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields: unique_products_2020, unique_products_2021, percentage_chg. */

with cte1 as (
select count(distinct(case 
					  when fiscal_year=2020 then product_code end)) as unique_products_2020,
	   count(distinct(case 
					  when fiscal_year=2021 then product_code end)) as unique_products_2021
		from fact_sales_monthly
)

select 
      unique_products_2020,
      unique_products_2021,
      concat(round(((unique_products_2021 - unique_products_2020) /unique_products_2020)*100,2),'%') as percentage_chg 
from cte1;



/* 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields: segment, product_count. */

SELECT 
      segment,
	  count(product_code) as product_count
from dim_product 
group by segment 
order by product_count desc



/* 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
The final output contains these fields: segment, product_count_2020, product_count_2021, difference. */

WITH CTE1 AS (SELECT 
       p.segment,
       count(distinct(case when fiscal_year=2020 then m.product_code end)) as product_count_2020,
       count(distinct(case when fiscal_year=2021 then m.product_code end)) as product_count_2021
from dim_product p 
join fact_sales_monthly m 
on p.product_code=m.product_code
group by p.segment)

SELECT 
	  segment,
      product_count_2020,
      product_count_2021,
      (product_count_2021-product_count_2020) as difference
FROM CTE1
order by difference desc;



/* 5. Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields: product_code, product, manufacturing_cost. */

SELECT 
      f.product_code,
      p.product,
      f.manufacturing_cost
 FROM dim_product p
 join fact_manufacturing_cost f
 on p.product_code=f.product_code
 where  manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost) or 
	      manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost)



/* 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
The final output contains these fields: customer_code, customer, average_discount_percentage. */

SELECT 
       c.customer,
       c.customer_code,
       avg(p.pre_invoice_discount_pct) as average_discount_percentage
FROM fact_pre_invoice_deductions p
JOIN dim_customer c
ON c.customer_code=p.customer_code
WHERE p.fiscal_year=2021 AND c.market="india"
GROUP BY c.customer_code , c.customer
ORDER BY average_discount_percentage desc
limit 5;



/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month, Year, Gross sales Amount. */

SELECT  
      MONTHNAME(fs.date) as MONTH,
      year(fs.date) as YEAR,
      CONCAT(ROUND(SUM(fs.sold_quantity*fg.gross_price)/1000000,2), 'M') as 'Gross sales Amount'
FROM fact_sales_monthly fs
JOIN fact_gross_price fg
ON fs.product_code=fg.product_code
JOIN dim_customer d
ON fs.customer_code=d.customer_code
WHERE d.customer = 'Atliq Exclusive'
GROUP BY MONTH,YEAR



/* 8. In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity. */

SELECT 
    CASE 
        WHEN s.date BETWEEN '2019-09-01' AND '2019-11-01' THEN 'Q1'
        WHEN s.date BETWEEN '2019-12-01' AND '2020-02-01' THEN 'Q2'
        WHEN s.date BETWEEN '2020-03-01' AND '2020-05-01' THEN 'Q3'
        WHEN s.date BETWEEN '2020-06-01' AND '2020-08-01' THEN 'Q4'
    END as Quarter,
    SUM(s.sold_quantity) as total_sold_quantity
FROM fact_sales_monthly s
WHERE s.fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;



/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields: channel, gross_sales_mln, percentage. */

WITH CTE1 AS (SELECT  
	  d.channel AS channel,
      ROUND(sum(fs.sold_quantity*fg.gross_price)/1000000,2) AS Sales_mln
FROM fact_sales_monthly fs
JOIN fact_gross_price fg
ON fs.product_code=fg.product_code
JOIN dim_customer d
ON fs.customer_code=d.customer_code
WHERE fs.fiscal_year=2021
GROUP BY channel)


SELECT 
      channel,
      sales_mln as GROSS_Sales_mln,
      round(sales_mln/sum(sales_mln)over()*100,2) as percentage
FROM CTE1
ORDER BY Percentage;



/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields: division, product_code, product, total_sold_quantity, rank_order. */

SELECT * 
FROM 
(SELECT 
       d.division as division,
       d.product_code as product_code,
       d.product as product,
       sum(fs.sold_quantity) as sold_quantity,
       dense_rank() over(partition by d.division order by sum(fs.sold_quantity) desc) as rank_order
FROM dim_product d
JOIN fact_sales_monthly fs
ON d.product_code=fs.product_code
where fs.fiscal_year=2021
Group by d.division,d.product_code,d.product) as sq
where sq.rank_order<4;
