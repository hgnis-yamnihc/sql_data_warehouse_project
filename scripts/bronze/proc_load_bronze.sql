/*
=====================================================================
Store Procedure: Load Bronze Layer (Source --> Bronze)
=====================================================================
Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external CSV files.
It performs the following functions:
  - Truncates the bronze tables before loading data. [Basically clears the bucket in one large throw (TRUNCATE; instantly clears the bucket) instead of using a mug (DELETE; slow and resouce heavy) for new water to come in.]
  - Uses the 'BULK INSERT' command to load data from CSV files to bronze tables.

Parametres:
  None.
This stored procedure does not acccept any parametres or return any values. 

Usage Example:
  EXEC bronze.load_bronzel;
*/



create or alter procedure bronze.load_bronze as
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	begin try

		set @batch_start_time = getdate();
		print'==============================================================================';
		print'Loading Bronze Layer';
		print'==============================================================================';

		print'------------------------------------------------------------------------------';
		print'Loading CRM Tables';
		print'------------------------------------------------------------------------------';

		-- bronze.crm_cust_info

		set @start_time = getdate();
		print'>> Truncating Table: bronze.crm_cust_info';
		truncate table bronze.crm_cust_info;
		print'>> Inserting data into: bronze.crm_cust_info';
		bulk insert bronze.crm_cust_info
		from 'D:\End to end projects\SQL Data Warehouse Project\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'



		-- bronze.crm_prd_info

		
		set @start_time = getdate();
		print'>> Truncating Table: bronze.crm_prd_info';
		truncate table bronze.crm_prd_info;
		print'>> Inserting data into: bronze.crm_prd_info';
		bulk insert bronze.crm_prd_info
		from 'D:\End to end projects\SQL Data Warehouse Project\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'


		-- bronze.crm_sales_details
		set @start_time = getdate();
		print'>> Truncating Table: bronze.crm_sales_details';
		truncate table bronze.crm_sales_details;
		print'>> Inserting data into: bronze.crm_sales_details';
		bulk insert bronze.crm_sales_details
		from 'D:\End to end projects\SQL Data Warehouse Project\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'


		-- bronze.erp_cust_az12
		set @start_time = getdate();
		print'>> Truncating Table: bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12;
		print'>> Inserting data into: bronze.erp_cust_az12';
		bulk insert bronze.erp_cust_az12
		from 'D:\End to end projects\SQL Data Warehouse Project\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'


		-- bronze.erp_loc_a101
		set @start_time = getdate();
		print'>> Truncating Table: bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101;
		print'>> Inserting data into: bronze.erp_loc_a101';
		bulk insert bronze.erp_loc_a101
		from 'D:\End to end projects\SQL Data Warehouse Project\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'

		-- bronze.erp_px_cat_g1v2
		set @start_time = getdate();
		print'>> Truncating Table: bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;
		print'>> Inserting data into: bronze.erp_px_cat_g1v2';
		bulk insert bronze.erp_px_cat_g1v2
		from 'D:\End to end projects\SQL Data Warehouse Project\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print'>>-----------------------------'

		set @batch_end_time = getdate();
		print '========================================================================'
		print'Bronze layer loading has completed.'
		print'Total Loading time for Bronze Layer: ' + cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + 'seconds';
		print '========================================================================'

		end try

		begin catch
			print '========================================================================'
			print 'Error occured during loading Bronze Layer'
			print 'Error Message' + error_message();
			print 'Error Message' + cast(error_message() as nvarchar);
			print 'Error Message' + cast(error_state() as nvarchar);
			print '========================================================================'
		end catch
end


-- To run this entire stored procedure:
execute bronze.load_bronze;
