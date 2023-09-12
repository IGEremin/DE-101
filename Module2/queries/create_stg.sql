DROP SCHEMA IF EXISTS stg CASCADE;
CREATE SCHEMA stg;

DROP TABLE IF EXISTS stg.orders;
CREATE TABLE stg.orders(
   "Row ID"        INTEGER  NOT NULL,
   "Order ID"      VARCHAR(14) NOT NULL,
   "Order Date"    DATE  NOT NULL,
   "Ship Date"     DATE  NOT NULL,
   "Ship Mode"     VARCHAR(14) NOT NULL,
   "Customer ID"   VARCHAR(8) NOT NULL,
   "Customer Name" VARCHAR(22) NOT NULL,
   "Segment"         VARCHAR(11) NOT NULL,
   "Country"         VARCHAR(13) NOT NULL,
   "City"            VARCHAR(17) NOT NULL,
   "State"           VARCHAR(20) NOT NULL,
   "Postal Code"   VARCHAR(50), --varchar because can start from 0
   "Region"          VARCHAR(7) NOT NULL,
   "Product ID"    VARCHAR(15) NOT NULL,
   "Category"        VARCHAR(15) NOT NULL,
   "Sub-Category"  VARCHAR(11) NOT NULL,
   "Product Name"  VARCHAR(127) NOT NULL,
   "Sales"           NUMERIC(9,4) NOT NULL,
   "Quantity"        INTEGER  NOT NULL,
   "Discount"        NUMERIC(4,2) NOT NULL,
   "Profit"          NUMERIC(21,16) NOT NULL,
   "Person"          VARCHAR(40) NOT NULL,
   "Returned"        VARCHAR(10) NOT NULL,
  CONSTRAINT PK_stg_orders PRIMARY KEY ( "Row ID" )
);
TRUNCATE stg.orders;