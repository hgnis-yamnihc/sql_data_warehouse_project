/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Quality Checks
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Script Purpose:
  This script performs carious quality checks for data consistency, accuracy, 
  and standardisation across the 'silver' schemas. It includes checks for:
  - Null or duplicate primary keys.
  - Unwanted spaces ins tring fields.
  - Data Standardisation and consistency.
  - Invalid date ranges and orders.
  - Data Consistency between related fields. 

Usage Noted:
  - Run these after loading Silver layer.
  - Investigate and resolve any discrepancies found during the checks.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checking 'silver.crm_cust_info'
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checks for nulls or duplicates in primary key
-- Expectation: No results

select cst_id, count(*) 
from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;


-- Check for unwanted spaces:
-- Expectation: No Result

select cst_lastname, count(*)
from silver.crm_cust_info
group by cst_lastname
having cst_lastname != trim(cst_lastname)

-- Data Standardization & Consistency
select distinct cst_marital_status
from silver.crm_cust_info;

select distinct cst_gndr
from silver.crm_cust_info;

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checking 'silver.crm_prd_info'
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- Chek for nulls or duplicates in Primary key
-- Expectation: No result

select prd_id, count(prd_id)
from silver.crm_prd_info
group by prd_id
having count(prd_id) > 1 or prd_id is null;


-- Check for unwanted spaces
-- Expectation: No Results
select prd_nm
from silver.crm_prd_info
where prd_nm != trim(prd_nm);



-- Chekc for nulls or negative numbers
-- Expectation: No result
select *
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null;


-- Data Standardization & VConsistency
select distinct prd_line
from silver.crm_prd_info;

-- Check for Invalild date orders
select * 
from silver.crm_prd_info
where prd_end_dt < prd_start_dt;

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checking 'silver.crm_sales_details'
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- Checking for Invalid Date Orders: 
-- Expectation: NO RESULTS
select * from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_ship_dt > sls_due_dt or sls_order_dt > sls_due_dt;

-- Checks on Sales, Quantities & Prices:
-- Expectation: NO RESULTS
select sls_quantity, sls_price, sls_sales from silver.crm_sales_details 
where 
	sls_sales != sls_quantity * sls_price
	or sls_quantity is null or sls_price is null or sls_sales is null
	or sls_quantity <= 0 or sls_price <= 0 or sls_sales <= 0
order by sls_sales, sls_quantity, sls_price;



-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checking 'silver.erp_cust_az12'
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


-- Checks for invalid dates:
-- Expectation: NO RESULTS (i.e., 10yo <= all customers age <= 100yo)
--------------------------------------------------------------------------
select * from silver.erp_cust_az12 where datediff(year, bdate, (getdate())) > 100 or datediff(year, bdate, (getdate())) <= 10;

--------------------------------------------------------------------------
-- CHECKS FOR WRONG GENDERS
-- Expectation: NO RESULTS
--------------------------------------------------------------------------
select * from silver.erp_cust_az12 where trim(GEN) not in ('Female', 'Male', 'n/a');

--------------------------------------------------------------------------
-- CHECKS FOR WRONG CID/ PRIMARY KEYS
-- Expectation: NO RESULTS
--------------------------------------------------------------------------
select * from silver.erp_cust_az12 where CID not like 'AW%';
select * from silver.erp_cust_az12 where CID like 'NAS%';

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checking 'silver.erp_loc_a101'
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- Checks on CID
-- Expectations: NO RESULT
---------------------------
select CID 
from silver.erp_loc_a101 
where 
	trim(CID) != CID
or	trim(CID) like ('%-%');



-----------------------------------------------
-- Checks on Countries
-- Expectations: NO RESULT (Nulls are allowed)
-----------------------------------------------
select cntry 
from silver.erp_loc_a101
where 
	trim(cntry) like ''
or	trim(cntry) in ('DE', 'US', 'USA');


-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Checking 'silver.erp_px_cat_g1v2'
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- For checks 
select distinct(CAT) from bronze.erp_px_cat_g1v2
select distinct(SUBCAT) from bronze.erp_px_cat_g1v2
select distinct(MAINTENANCE) from bronze.erp_px_cat_g1v2

-----------------------------------------------------------------------------

select trim(id) from bronze.erp_px_cat_g1v2 where id not in (select trim(cat_id) from silver.crm_prd_info) -- just 1 ID not in other table.

-----------------------------------------------------------------------------

select * 
from bronze.erp_px_cat_g1v2 
where 
	trim(subcat) != subcat
or	trim(cat) != cat
or	trim(id) != id
or	trim(maintenance) != MAINTENANCE
