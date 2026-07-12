/* 
=============================================================
Stored Procedure: Load Silver Later (Bronze --> Silver Layer)
=============================================================
Script Purpose:
  This script performs the ETL (Extract, Transform, Load) proces to 
  fill the silver layer schema from the bronze layer after perform 
  operations on data to make it more usable.

Actions Performed:
  - Truncates Silver Tables
  - Inserts transformed and cleaned data from Bronze into 
    Silver Tables.

Parameters:
  None.
  This stored procedures does not accept any parameters or 
  return any values.

Usage Example:
exec.silver.load_silver;

  
===========================================================
*/



create or alter procedure silver.load_silver as 

BEGIN
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	begin try

		set @batch_start_time = getdate();

		-- Inserting Data from Bronze Layer to Silver Layer
		--------------------------------------------------------
		--------------------------------------------------------


		print('---------------------------')
		print('>> Working on CRM Tables')
		print('---------------------------')




		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		print('');
		-- Inserting Data from Bronze.crm_cust_info to Silver.crm_cust_info:
		--------------------------------------------------------------------
		print('>> Inserting Data from Bronze.crm_cust_info to Silver.crm_cust_info:')
		print('--------------------------------------------------------------------')
		set @start_time = getdate();
		truncate table silver.crm_cust_info;
		insert into silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)

		select 
			cst_id,
			cst_key,
			trim(cst_firstname) cst_firstname,
			trim(cst_lastname) cst_lastname,
		-- ------------------------------------ 
			(case when upper(trim(cst_marital_status)) = 'M' then 'Married'
				 when upper(trim(cst_marital_status)) = 'S' then 'Single'
				 else 'n/a'
			end) cst_marital_status,
		-- ------------------------------------
			(case when upper(trim(cst_gndr)) = 'F' then 'Female'
				 when upper(trim(cst_gndr)) = 'M' then 'Male'
				 else 'n/a'
			end) cst_gndr,
		-- ------------------------------------
			cst_create_date
		from (select * from (
				select *, row_number() over (partition by cst_id order by cst_create_date desc) as flag_last 
				from bronze.crm_cust_info where cst_id is not null) t where flag_last = 1)t;
-----------------------------------------------
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'


		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		print('');
		-- Inserting Data from Bronze.crm_prd_info to Silver.crm_prd_info:
		--------------------------------------------------------------------
		print('>> Inserting Data from Bronze.crm_prd_info to Silver.crm_prd_info:')
		print('--------------------------------------------------------------------')
		set @start_time = getdate();
		truncate table Silver.crm_prd_info
		insert into silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)

		select 
			prd_id,

			replace(substring(prd_key, 1, 5), '-', '_') as cat_id,
		-- ------------------------------------------------------------ 
			SUBSTRING(prd_key, 7, len(prd_key)) as prd_key,
		-- ------------------------------------------------------------ 
			prd_nm,
		-- ------------------------------------------------------------ 
			isnull(prd_cost, 0) prd_cost,
		-- ------------------------------------------------------------ Data Normalisation (map product line codes to descriptive values)
			(case upper(trim(prd_line))
				when 'M' then 'Mountain'
				when 'R' then 'Road'
				when 'S' then 'Other Sales'
				when 'T' then 'Touring'
				else 'n/a'
			end) as prd_line,
		-- ------------------------------------------------------------ Data Type Casting
			cast(prd_start_dt as date) as prd_start_dt,
		-- ------------------------------------------------------------ Data Type Casting + Data Enrichment
			cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt
		from bronze.crm_prd_info;

-----------------------------------------------
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'


		;

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		print('');
		-- Inserting Data from Bronze.crm_sales_details to Silver.crm_sales_details:
		--------------------------------------------------------------------
		print('>> Inserting Data from Bronze.crm_sales_details to Silver.crm_sales_details:')
		print('-----------------------------------------------------------------------------')
		set @start_time = getdate();
		truncate table Silver.crm_sales_details
		insert into silver.crm_sales_details(
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			sls_order_dt , 
			sls_ship_dt ,
			sls_due_dt ,
			sls_quantity ,
			sls_price ,
			sls_sales 
		)
		select
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
		-- ---------------------------------------------------------------------------------------------------
			case 
				when sls_order_dt = 0 or len(sls_order_dt) !=8 then null
				when sls_order_dt > 20260101 or sls_order_dt < 19000101 then null
				else cast(cast(sls_order_dt as varchar) as date)
			end as sls_order_dt,
		-- ---------------------------------------------------------------------------------------------------	
				case 
				when sls_ship_dt = 0 or len(sls_ship_dt) !=8 then null
				when sls_ship_dt > 20260101 or sls_ship_dt < 19000101 then null
				else cast(cast(sls_ship_dt as varchar) as date)
			end as sls_ship_dt,
		-- ---------------------------------------------------------------------------------------------------
			case 
				when sls_due_dt = 0 or len(sls_due_dt) !=8 then null
				when sls_due_dt > 20260101 or sls_due_dt < 19000101 then null
				else cast(cast(sls_due_dt as varchar) as date)
			end as sls_due_dt,
		-- ---------------------------------------------------------------------------------------------------
			sls_quantity,
		-- ---------------------------------------------------------------------------------------------------
			case 
				when sls_price is null or sls_price <= 0 then sls_sales/ nullif(sls_quantity, 0)
				else sls_price
			end as sls_price,
		-- ---------------------------------------------------------------------------------------------------
				case
				when sls_sales is null or sls_sales <= 0 or sls_sales != sls_price * sls_quantity
				then sls_quantity * abs(sls_price)
				else sls_sales
			end as sls_sales
		from bronze.crm_sales_details
-----------------------------------------------
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'

		;




		print('');
		print('');

		print('---------------------------')
		print('>> Working on ERP Tables')
		print('---------------------------')
		print('');


		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		print('');
		-- Inserting Data from Bronze.erp_CUST_AZ12 to Silver.erp_CUST_AZ12:
		--------------------------------------------------------------------
		print('>> Inserting Data from Bronze.erp_CUST_AZ12 to Silver.erp_CUST_AZ12:')
		print('--------------------------------------------------------------------')
		set @start_time = getdate();
		truncate table Silver.erp_CUST_AZ12
		insert into silver.erp_cust_az12(

			cid,
			bdate,
			gen
		)

		select
		------------------CID------------------
			case
				when CID like '%NAS%'
				then substring(CID,4, len(CID)) 
				else CID
			end as cid,
		------------------BDATE----------------
			case 
				when DATEDIFF(year, bdate, GETDATE()) > 100 
					or DATEDIFF(year, bdate, GETDATE()) <= 10
					then null 
				else BDATE
			end as bdate,
		------------------GEN------------------
			CASE 
					WHEN upper(trim(gen)) in ('F', 'FEMALE') THEN 'Female'
					WHEN upper(trim(gen)) in ('M', 'MALE') THEN 'Male'
					ELSE 'n/a'
				END AS gen

		from bronze.erp_cust_az12
-----------------------------------------------
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'

		;


		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		print('');
		-- Inserting Data from Bronze.erp_LOC_A101 to Silver.erp_LOC_A101:
		--------------------------------------------------------------------
		print('>> Inserting Data from Bronze.erp_LOC_A101 to Silver.erp_LOC_A101:')
		print('--------------------------------------------------------------------')

		set @start_time = getdate();
		truncate table silver.erp_loc_a101
		insert into silver.erp_loc_a101(
	
			cid,
			cntry

		)
		select 
			replace(CID,'-', '') as cid,
			case 
				when trim(cntry)is null or trim(cntry) = '' then null
				when trim(cntry) = 'DE' then 'Germany'
				when trim(cntry)= 'US' or trim(cntry)= 'USA' then 'United States of America'
				else trim(cntry)
			end AS country
		from bronze.erp_loc_a101;
-----------------------------------------------
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'


		;

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		print('');

		-- Inserting Data from Bronze.erp_PX_CAT_G1V2 to Silver.erp_PX_CAT_G1V2:
		--------------------------------------------------------------------
		print('>> Inserting Data from Bronze.erp_PX_CAT_G1V2 to Silver.erp_PX_CAT_G1V2:')
		print('-----------------------------------------------------------------------------')
		set @start_time = getdate();
		truncate table silver.erp_px_cat_g1v2
		insert into silver.erp_px_cat_g1v2(
		ID, CAT, SUBCAT, MAINTENANCE
		)
		select ID, CAT, SUBCAT, MAINTENANCE from bronze.erp_px_cat_g1v2
		;
-----------------------------------------------
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'

-----------------------------------------------
-----------------------------------------------
set @batch_end_time = getdate()
print('======================================')
print('Loading Silver Layer is Completed')
print '- Total Load Duration for Silver Layer:' + cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + 'seconds' 
print('======================================')

	end try

		begin catch
			print '========================================================================'
			print 'Error occured during loading Bronze Layer'
			print 'Error Message' + error_message();
			print 'Error Message' + cast(error_message() as nvarchar);
			print 'Error Message' + cast(error_state() as nvarchar);
			print '========================================================================'
		end catch

END
