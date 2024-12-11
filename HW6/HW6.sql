/* **************************************************************************************** */
-- when set, it prevents potentially dangerous updates and deletes
set SQL_SAFE_UPDATES=0;

-- when set, it disables the enforcement of foreign key constraints.
set FOREIGN_KEY_CHECKS=0;

/* **************************************************************************************** 
-- These control:
--     the maximum time (in seconds) that the client will wait while trying to establish a 
	   connection to the MySQL server 
--     how long the client will wait for a response from the server once a request has 
       been sent over
**************************************************************************************** */
SHOW SESSION VARIABLES LIKE '%timeout%';       
SET GLOBAL mysqlx_connect_timeout = 600;
SET GLOBAL mysqlx_read_timeout = 600;

/* **************************************************************************************** */
-- The DB where the accounts table is created

-- Create the accounts table (Part 1 already done) 
CREATE TABLE accounts (
  account_num CHAR(6) PRIMARY KEY,    -- HAD TO CHANGE when you get to higher levels in insertion
  branch_name VARCHAR(50),            -- Branch name (e.g., Brighton, Downtown, etc.)
  balance DECIMAL(10, 2),             -- Account balance, with two decimal places (e.g., 1000.50)
  account_type VARCHAR(50)            -- Type of the account (e.g., Savings, Checking)
);

DROP TABLE if exists accounts; -- for reseting the query to not have redundant values when I populated 


/* ***************************************************************************************************
The procedure generates 50,000 records for the accounts table, with the account_num padded to 5 digits.
branch_name is randomly selected from one of the six predefined branches.
balance is generated randomly, between 0 and 100,000, rounded to two decimal places.
***************************************************************************************************** */
-- Change delimiter to allow semicolons inside the procedure
DELIMITER $$

CREATE PROCEDURE generate_accountsInc(startID INT, endID INT)
BEGIN
  DECLARE i INT DEFAULT startID;
  DECLARE branch_name VARCHAR(50);
  DECLARE account_type VARCHAR(50);
  
  -- Loop to generate as many accounts as entailed by input
  WHILE i <= endID DO
    -- Randomly select a branch from the list of branches
    SET branch_name = ELT(FLOOR(1 + (RAND() * 6)), 'Brighton', 'Downtown', 'Mianus', 'Perryridge', 'Redwood', 'RoundHill');
    
    -- Randomly select an account type
    SET account_type = ELT(FLOOR(1 + (RAND() * 2)), 'Savings', 'Checking');
    
    -- Insert account record
    INSERT INTO accounts (account_num, branch_name, balance, account_type)
    VALUES (
      LPAD(i, 6, '0'),                   -- Account number as just digits,  Needed to change to 6 for 150000
      branch_name,                       -- Randomly selected branch name
      ROUND((RAND() * 100000), 2),       -- Random balance between 0 and 100,000, rounded to 2 decimal places
      account_type                       -- Randomly selected account type (Savings/Checking)
    );

    SET i = i + 1;
  END WHILE;
END$$

-- Reset the delimiter back to the default semicolon
DELIMITER ;

-- ******************************************************************
-- execute the procedure
-- ******************************************************************

-- fun had below (Part 2)
CALL generate_accountsInc(1,5000);
CALL generate_accountsInc(5001,10000);
CALL generate_accountsInc(10001,15000);
CALL generate_accountsInc(15001,20000);
CALL generate_accountsInc(20001,25000);
CALL generate_accountsInc(25001,30000);
CALL generate_accountsInc(30001,35000);
CALL generate_accountsInc(35001,40000);
CALL generate_accountsInc(40001,45000);
CALL generate_accountsInc(45001,50000);
CALL generate_accountsInc(50001,55000);
CALL generate_accountsInc(55001,60000);
CALL generate_accountsInc(60001,65000);
CALL generate_accountsInc(65001,70000);
CALL generate_accountsInc(70001,75000);
CALL generate_accountsInc(75001,80000);
CALL generate_accountsInc(80001,85000);
CALL generate_accountsInc(85001,90000);
CALL generate_accountsInc(90001,95000);
CALL generate_accountsInc(95001,100000);
CALL generate_accountsInc(100001,105000);
CALL generate_accountsInc(105001,110000);
CALL generate_accountsInc(110001,115000);
CALL generate_accountsInc(115001,120000);
CALL generate_accountsInc(120001,125000);
CALL generate_accountsInc(125001,130000);
CALL generate_accountsInc(130001,135000);
CALL generate_accountsInc(135001,140000);
CALL generate_accountsInc(140001,145000);
CALL generate_accountsInc(145001,150000);


-- ****************************************************************************************
-- PART 3 
-- *****************************************************************************************
CREATE INDEX idx_branch_name ON accounts (branch_name); -- index on branch name.
CREATE INDEX idx_balance ON accounts(balance); -- index on balance 
DROP INDEX idx_branch_name ON accounts; -- drop for timing analysis 
DROP INDEX idx_balance ON accounts; 
DROP INDEX idx_branch_account_type ON accounts;
SELECT count(*) FROM accounts WHERE branch_name = 'Downtown' AND balance BETWEEN 10000 and 50000;

-- ****************************************************************************************
-- If you frequently run queries that filter or sort by both branch_name and account_type, 
-- creating a composite index on these two columns can improve performance.
-- ****************************************************************************************
CREATE INDEX idx_branch_account_type ON accounts (branch_name, account_type);
CREATE INDEX idx_account_type ON accounts (account_type);
DROP INDEX idx_branch_account_type ON accounts;

SELECT count(*) FROM accounts 
WHERE branch_name = 'Downtown' 
AND account_type = 'Savings';


-- ****************************************************************************************
-- The EXPLAIN statement shows how MySQL executes a query and whether it is using indexes 
-- to find rows efficiently. By running EXPLAIN before and after creating an index, you can 
-- see whether the query plan changes and whether the index is being used.
-- ****************************************************************************************
EXPLAIN SELECT count(*) FROM accounts 
WHERE branch_name = 'Downtown'
AND account_type = 'Savings';

alter table accounts drop primary key;
alter table accounts add primary key(account_num);

SELECT * FROM accounts WHERE branch_name = 'Downtown' AND account_type = 'Savings';
-- ******************************************************************************************
-- Timing analysis
-- ******************************************************************************************

-- Show indexes and drop all the indexes I added below. 
SHOW INDEXES from accounts;

DROP INDEX idx_account_type ON accounts;
DROP INDEX idx_branch_account_type ON accounts;
DROP INDEX idx_balance ON accounts;
DROP INDEX idx_branch_name ON accounts;


SET @start_time = NOW(6);
SELECT count(*) FROM accounts WHERE branch_name = 'Downtown' AND account_type = 'Savings'; -- example
SET @end_time = NOW(6);
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;
    
-- POINT QUERY 1 
SET @start_time = NOW(6);
SELECT balance FROM accounts WHERE account_num = '000039'; -- getting balance from account 39 
SET @end_time = NOW(6);
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;

-- POINT QUERY 2 
SET @start_time = NOW(6);
SELECT branch_name FROM accounts WHERE account_num = '000039'; -- branch name for account 39
SET @end_time = NOW(6);
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;
    
-- Ranged Query 1
SET @start_time = NOW(6);
Select count(*) FROM accounts WHERE balance BETWEEN 20000 AND 100000; -- range query for those with 2000 to 10000
SET @end_time = NOW(6);
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;
    
-- Ranged Query 2
SET @start_time = NOW(6);
Select * FROM accounts WHERE balance BETWEEN 0 AND 3900; -- range query for those with 0 to 3900
SET @end_time = NOW(6);
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;
    
-- Stored procedure to get average execution time of 10 queries
DELIMITER $$

CREATE PROCEDURE calcAvgExecution4(IN inputquer TEXT) -- had to make it calcAvgExecution4 because the first 3 had issues
BEGIN
    -- variables for time calculation
    DECLARE start_time_micro BIGINT; -- BIGINT because microseconds are huge apparently
    DECLARE end_time_micro BIGINT;
    DECLARE total_time BIGINT DEFAULT 0;
    DECLARE avgExecTime BIGINT;
    DECLARE i INT DEFAULT 1;

    -- session variable for query
    SET @query = inputquer;  
    PREPARE stmt FROM @query; -- prepare SQL input
    
    WHILE i <= 10 DO -- execute input query 10 times.
        SET start_time_micro = UNIX_TIMESTAMP(NOW(6)) * 1000000 + MICROSECOND(NOW(6)); -- gets the start time
        EXECUTE stmt;
        SET end_time_micro = UNIX_TIMESTAMP(NOW(6)) * 1000000 + MICROSECOND(NOW(6)); -- gets end time 
        
        SET total_time = total_time + (end_time_micro - start_time_micro); -- getting execution time for this iteration
        -- Keep track of the iteration
        SET i = i + 1;
    END WHILE;
    DEALLOCATE PREPARE stmt; 

    SET avgExecTime = total_time / 10; -- Get the average execution time after while statement by dividing by the total_time by 10 entries 
    
    -- Return the average execution time
    SELECT avgExecTime AS avgExecTime;
END$$

DELIMITER ;

CALL calcAvgExecution4('SELECT * FROM accounts');








    