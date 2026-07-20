
/*
=================================================================================
DDL Script: Create Gold Views
=================================================================================

Script Purpose:
  Tis cript creates views for the Gold Layer in the data warehouse. 
  The gold layer represents the final dimanesion and fact tables (star schemas)

  Each view performs transformations and combines data from the Silver later to produce a clean, enriched, and business ready data set. 

Usage:
  These views can be queried directly for analytics and reporting.

*/



-- =================================================================================
-- Create Dimensions: gold.dim_customers
-- =================================================================================

DROP VIEW IF EXISTS gold.dim_customers;
go 
create view gold.dim_customers as
	select 
		row_number() over (order by cst_id) as customer_key,
		ci.cst_id as customer_id,
		ci.cst_key as customer_number,
		ci.cst_firstname as first_name,
		ci.cst_lastname as last_name,
		la.CNTRY as country,
		ci.cst_marital_status as marital_status,
		case 
			when ci.cst_gndr != 'n/a' then ci.cst_gndr -- CRM is the master for gender info
			else coalesce(ca.gen, 'n/a')
		end as gender,
		ca.BDATE as birthdate,
		ci.cst_create_date as creation_date
	from 
		silver.crm_cust_info ci
		left join
		silver.erp_cust_az12 ca
		on ci.cst_key = ca.CID
		left join
		silver.erp_loc_a101 la
		on ca.cid = la.CID;



-- =================================================================================
-- Create Dimensions: gold.dim_products
-- =================================================================================

drop view if exists gold.dim_products;
go 
	create view gold.dim_products as
		select
			row_number() over (order by prd.prd_start_dt, prd.prd_key) as product_key,
			prd.prd_id as product_id,
			prd.prd_key as product_number,
			prd.prd_nm as product_name,
			prd.cat_id as category_id,
			pcg.CAT as category,
			pcg.SUBCAT as subcategory,
			pcg.MAINTENANCE as maintenance,
			prd.prd_cost product_cost,
			prd.prd_line as product_line,
			prd.prd_start_dt as product_start_date
		from 
			silver.crm_prd_info prd
			left join
			silver.erp_px_cat_g1v2 pcg
		on	prd.cat_id = pcg.ID
		where prd.prd_end_dt is null -- this filters out all historical data and keeps only those which are latest and without an end date.




-- =================================================================================
-- Create Dimensions: gold.facts_sales
-- =================================================================================

  
drop view if exists gold.fact_sales;
go 
create view gold.fact_sales as 
	select
		sd.sls_ord_num as order_number,
		dp.product_key,
		dc.customer_key,
		sd.sls_order_dt as order_date,
		sd.sls_ship_dt as ship_date,
		sd.sls_due_dt as due_date,
		sd.sls_quantity as sales_quantity,
		sd.sls_sales as total_sales,
		sd.sls_price as sales_price
	from
		silver.crm_sales_details sd
		left join
		gold.dim_products dp
	on	sd.sls_prd_key = dp.product_number
		left join
		gold.dim_customers dc
	on	sd.sls_cust_id = dc.customer_id;
