## Import libraries

import time
import pandas as pd
import psycopg2 as pg2
import psycopg2.extras as extras
import source.config as cfg


## SQL query operations functions

def execute_query(path:str, conn:pg2.connect):
    '''Execute query from .sql file'''
    with conn.cursor() as cursor:
        with open(path, 'r') as f:
            try:
                cursor.execute(f.read())
                conn.commit()
            except (Exception, pg2.DatabaseError) as error:
                print("Error: %s" % error)
                conn.rollback()
                return
    print('Query executed successfully')


def insert_into_table(table:str, data:pd.DataFrame, conn:pg2.connect):
    '''Insert pandas DataFrame into SQL table'''
    query = "INSERT INTO %s(%s) VALUES %%s" % (table, ','.join([f'"{col}"' for col in data.columns]))
    with conn.cursor() as cursor:
        try:
            extras.execute_values(cursor, query, data.values)
            conn.commit()
        except (Exception, pg2.DatabaseError) as error:
            print("Error: %s" % error)
            conn.rollback()
            return
        print("Inserted {} rows into {}".format(len(data), table))


def select_from_table(table:str, columns:list, conn:pg2.connect):
    '''Select columns from SQL table'''
    query = "SELECT %s FROM %s" % (','.join(columns), table)
    with conn.cursor() as cursor:
        try:
            cursor.execute(query)
            conn.commit()
            return pd.DataFrame(cursor.fetchall(), columns=columns)
        except (Exception, pg2.DatabaseError) as error:
            print("Error: %s" % error)
            conn.rollback()
            return
        

## Load data from Excel table

data = pd.read_excel(
    'Sample - Superstore.xlsx', 
    parse_dates=['Order Date', 'Ship Date'], 
    dtype={'Postal Code': str}
)

# Source table has missed Postal code for Burlington, VE. Fill missed values

data['Postal Code'] = data['Postal Code'].fillna('05401')


## Make connection with PostgreSQL database

conn = pg2.connect(host=cfg.hostname, 
                   dbname=cfg.dbname, 
                   user=cfg.user,
                   password=cfg.password)
conn.set_session(autocommit=True)


## Execute SQL queries for making Stage and Data Warehouse schemas

execute_query('queries/create_stg.sql', conn)
execute_query('queries/create_dw.sql', conn)

# Insert source data into stg.orders

insert_into_table("stg.orders", data, conn)


## Insert data into Data Warehouse tables

data.columns = [col.lower().replace(' ', '_').replace('-', '_') for col in data.columns]

# dw.customer

customers = data[['customer_id', 'customer_name', 'segment']].drop_duplicates()
insert_into_table('dw.customers', customers, conn)

# dw.regions

regions = data[['region', 'person']].drop_duplicates()
insert_into_table('dw.regions', regions, conn)

# dw.geography

geography = data[['country', 'city', 'state', 'postal_code', 'region']].drop_duplicates().reset_index(drop=True)

regions_uid = regions[['region']]
regions_uid['region_uid'] = range(1, regions_uid.shape[0]+1)  # Make regions_uid from range started by 1  

geography = geography.merge(regions_uid, on='region')
geography = geography[geography.columns.drop('region')]

insert_into_table('dw.geography', geography, conn)

# dw.products

products = data[['product_id', 'product_name', 'category', 'sub_category']].drop_duplicates()
insert_into_table('dw.products', products, conn)

# dw.orders

orders = data[['order_id', 'order_date']].drop_duplicates()

date_df = select_from_table('dw.calendar', ['date_id', 'date'], conn)
date_df['date'] = pd.to_datetime(date_df['date'])  # Replace order date to order uid

orders = orders.merge(date_df, left_on='order_date', right_on='date', how='left')[['order_id', 'date_id']]

insert_into_table('dw.orders', orders[['order_id', 'date_id']], conn)

# dw.order_facts

ord_facts = data[['row_id', 'order_id', 'product_id', 'product_name', 'customer_id', 'returned']]
ord_facts.loc[:, 'returned'] = ord_facts['returned'].replace({'Yes': True, 'No': False}).astype(bool)

prod_df = select_from_table('dw.products', ['product_uid', 'product_id', 'product_name'], conn)
ord_facts = ord_facts.merge(prod_df, on=['product_id', 'product_name'], how='left')  # Replace product id to uid

cust_df = select_from_table('dw.customers', ['customer_uid', 'customer_id'], conn)
ord_facts = ord_facts.merge(cust_df, on='customer_id', how='left')  # Replace customer id to uid

ord_df = select_from_table('dw.orders', ['order_uid', 'order_id', 'date_id'], conn)
ord_facts = ord_facts.merge(ord_df, on='order_id', how='left')  # Replace order id to uid

ord_facts = ord_facts[['row_id', 'order_uid', 'product_uid', 'customer_uid', 'returned']]
insert_into_table('dw.order_facts', ord_facts, conn)

# dw.shipping

shipping = data[['row_id', 'ship_date', 'ship_mode', 'state', 'city', 'postal_code']]

shipping = shipping.merge(date_df, left_on='ship_date', right_on='date', how='left')  # Replace ship date to date id

geo_df = select_from_table('dw.geography', ['geo_id', 'state', 'city', 'postal_code'], conn)
shipping = shipping.merge(
    geo_df, on=['state', 'city', 'postal_code'], how='left'
    )[['row_id', 'date_id', 'ship_mode', 'geo_id']]  # Replace address information to geography id

insert_into_table('dw.shipping', shipping, conn)

# dw.metrics

metrics = data[['row_id', 'sales', 'quantity', 'discount', 'profit']]
insert_into_table('dw.metrics', metrics, conn)
