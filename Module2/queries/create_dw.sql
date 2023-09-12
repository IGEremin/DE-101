DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;

---- CREATE TABLES


-- REGIONS

DROP TABLE IF EXISTS dw.regions;
CREATE TABLE dw.regions (
	region_uid   integer GENERATED BY DEFAULT AS IDENTITY,
	person       varchar(50) NULL,
	region       varchar(50) NOT NULL,
	CONSTRAINT PK_regions PRIMARY KEY ( region_uid )
);
TRUNCATE TABLE dw.regions;


-- GEOGRAPHY

DROP TABLE IF EXISTS dw.geography;
CREATE TABLE dw.geography (
	geo_id      integer GENERATED BY DEFAULT AS IDENTITY (START 1000),
	country     varchar(50) NOT NULL,
	"state"     varchar(50) NOT NULL,
	city        varchar(50) NOT NULL,
	postal_code varchar(20) NOT NULL,
	region_uid  integer,
	CONSTRAINT PK_geography PRIMARY KEY ( geo_id )
);
TRUNCATE TABLE dw.geography;


-- CUSTOMERS

DROP TABLE IF EXISTS dw.customers CASCADE;
CREATE TABLE dw.customers (
	customer_uid  integer GENERATED BY DEFAULT AS IDENTITY (START 10000),
	customer_id   varchar(25) NOT NULL,
	customer_name varchar(50) NOT NULL,
	segment       varchar(40) NOT NULL,
	CONSTRAINT PK_customers PRIMARY KEY ( customer_uid )
);
TRUNCATE TABLE dw.customers;


-- PRODUCTS

DROP TABLE IF EXISTS dw.products;
CREATE TABLE dw.products (
	product_uid     integer GENERATED BY DEFAULT AS IDENTITY (START 100000),	
	product_id      varchar(30) NOT NULL,
	product_name    varchar(150) NOT NULL,
	category        varchar(30) NOT NULL,
	sub_category    varchar(30) NOT NULL,
	CONSTRAINT PK_products PRIMARY KEY ( product_uid )
);
TRUNCATE TABLE dw.products;


-- CALENDAR

DROP TABLE IF EXISTS dw.calendar;
CREATE TABLE dw.calendar (
	date_id     integer GENERATED BY DEFAULT AS IDENTITY,	
	"date"      date NOT NULL,
	"year"      integer NOT NULL,
	"quarter"   smallint NOT NULL,
	"month"     smallint NOT NULL,
	"day"       smallint NOT NULL,
	dow         smallint NOT NULL,
	"week"      smallint NOT NULL,
	leap        boolean NOT NULL,
	CONSTRAINT PK_calendar PRIMARY KEY ( date_id )
);
TRUNCATE TABLE dw.calendar;

INSERT INTO dw.calendar ("date", "year", "quarter", "month", "day", dow, "week", leap)
	SELECT date::date,
		   EXTRACT('year' FROM date) AS "year",
		   EXTRACT('quarter' FROM date) AS "quarter",
		   EXTRACT('month' FROM date) AS "month",
		   EXTRACT('day' FROM date) AS "day",
	       EXTRACT('isodow' FROM date) AS dow,
	       EXTRACT('week' FROM date) AS "week",
	       (EXTRACT('day' FROM (date + interval '2 month - 1 day')) = 29 AND
	        EXTRACT('month' FROM (date + interval '2 month - 1 day')) = 2) AS leap
	FROM generate_series(date '2010-01-01',
	                     date '2030-01-01',
	                     interval '1 day') AS t(date);


-- ORDERS

DROP TABLE IF EXISTS dw.orders;
CREATE TABLE dw.orders (
	order_uid   integer GENERATED BY DEFAULT AS IDENTITY (START WITH 1000000),
	order_id    varchar(25) NOT NULL,
	date_id     integer NOT NULL,
	CONSTRAINT PK_orders PRIMARY KEY ( order_uid )
);
TRUNCATE TABLE dw.orders;


-- SHIPPING

DROP TABLE IF EXISTS dw.shipping;
CREATE TABLE dw.shipping (
	row_id       integer NOT NULL, 
	date_id      integer NULL,
	ship_mode    varchar(25) NOT NULL,
	geo_id       integer NOT NULL,
	CONSTRAINT PK_shipping PRIMARY KEY ( row_id )
);
TRUNCATE TABLE dw.shipping;


-- ORDER_FACTS

DROP TABLE IF EXISTS dw.order_facts;
CREATE TABLE dw.order_facts (
	row_id       integer GENERATED BY DEFAULT AS IDENTITY,
	order_uid    integer NOT NULL,
	product_uid  integer NOT NULL,
	customer_uid integer NOT NULL,
	returned     boolean NOT NULL,
	CONSTRAINT PK_order_facts PRIMARY KEY ( row_id )
);
TRUNCATE TABLE dw.order_facts;

-- METRICS

DROP TABLE IF EXISTS dw.metrics;
CREATE TABLE dw.metrics (
	row_id   integer NOT NULL,
	sales    numeric(20, 2) NOT NULL,
	quantity integer NOT NULL,
	discount numeric(3, 2) NOT NULL DEFAULT 0.00,
	profit   numeric(22, 4) NOT NULL,
	CONSTRAINT PK_metrics PRIMARY KEY ( row_id )
);
TRUNCATE TABLE dw.metrics;