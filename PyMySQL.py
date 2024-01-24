# Importing the needed libraries
import pandas as pd
from sqlalchemy import create_engine


# Creating the path where the file is saved, you must put the location where you saved it
csv_file_path = r'Nashville Housing Data.xlsx'


# Creating the dataframe that will hold all the data
df = pd.read_excel(csv_file_path)


# Where it says USER, put your own MySQL user, by default it should be "root"
# Where it says PASSWORD, put your own MySQL password
# Where it says SERVER, put your own MySQL server, by default it shoul be "localhost" ,
# because you will be working at your own pc
# Where it says DB, put your own DB name, you can change it at the beggining of the sql script

# Create the connection to MySQL with an extended timeout
engine = create_engine('mysql+mysqlconnector://USER:PASSWORD@SERVER/DB?connect_timeout=300')


# Try to close any pending transactions
try:
    with engine.connect() as connection:
        with connection.begin():
            pass
except Exception as e:
    print(f"Error handling transactions: {e}")


# Create the table in MySQL and let SQLAlchemy infer the data types
# Split the insert into smaller batches
Table_Name = 'housing_data'
df.to_sql(name= Table_Name, con=engine, index=False, if_exists='replace', chunksize=1000)

# If you want to change the table name, just change the value where it says "housing_data"

# Close the connection
engine.dispose()


# Print a success message
print(f'Table {Table_Name} created successfully.')