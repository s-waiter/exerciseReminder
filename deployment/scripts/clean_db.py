import pymysql
import os
import sys

# Default Config
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "pass")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_NAME = "deskcare"

def clean_database():
    print(f"Connecting to database '{DB_NAME}' at {DB_HOST}...")
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASS,
            port=DB_PORT,
            database=DB_NAME
        )
        cursor = conn.cursor()
        
        # Disable FK checks
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # Get all tables
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        
        for (table_name,) in tables:
            # Skip alembic_version if exists (migration history)
            if table_name == "alembic_version":
                continue
                
            print(f"Truncating table: {table_name}")
            cursor.execute(f"TRUNCATE TABLE {table_name}")
            
        # Re-enable FK checks
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        conn.commit()
        conn.close()
        print("All data has been cleared successfully.")
        
    except Exception as e:
        print(f"Error cleaning database: {e}")
        sys.exit(1)

if __name__ == "__main__":
    clean_database()
