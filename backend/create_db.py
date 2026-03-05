import pymysql
import os

DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "pass")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3306"))

def create_database():
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASS,
            port=DB_PORT
        )
        cursor = conn.cursor()
        print("Creating database 'deskcare' if not exists...")
        cursor.execute("CREATE DATABASE IF NOT EXISTS deskcare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        print("Database created or already exists.")
        conn.close()
    except Exception as e:
        print(f"Error creating database: {e}")

if __name__ == "__main__":
    create_database()
