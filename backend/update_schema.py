import pymysql
import os
from sqlalchemy import create_engine, text

# Use the same connection string logic as database.py
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "pass")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = "deskcare"

SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def upgrade_schema():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    with engine.connect() as conn:
        print("Checking schema updates...")
        
        # 1. Add SystemConfig table
        try:
            conn.execute(text("SELECT 1 FROM system_config LIMIT 1"))
            print("Table 'system_config' already exists.")
        except Exception:
            print("Creating table 'system_config'...")
            conn.execute(text("""
                CREATE TABLE system_config (
                    `key` VARCHAR(50) NOT NULL,
                    `value` VARCHAR(255),
                    `description` VARCHAR(255),
                    PRIMARY KEY (`key`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """))
            # Insert default value
            conn.execute(text("INSERT INTO system_config (`key`, `value`) VALUES ('require_download_code', 'true')"))
            conn.commit()

        # 2. Update DownloadKey table
        # Check if 'type' column exists
        try:
            result = conn.execute(text("SHOW COLUMNS FROM download_keys LIKE 'type'"))
            if result.fetchone():
                print("Column 'type' in 'download_keys' already exists.")
            else:
                print("Adding column 'type' to 'download_keys'...")
                conn.execute(text("ALTER TABLE download_keys ADD COLUMN `type` VARCHAR(20) DEFAULT 'one_time'"))
                conn.commit()
        except Exception as e:
            print(f"Error checking column type: {e}")

        # Check if 'usage_count' column exists
        try:
            result = conn.execute(text("SHOW COLUMNS FROM download_keys LIKE 'usage_count'"))
            if result.fetchone():
                print("Column 'usage_count' in 'download_keys' already exists.")
            else:
                print("Adding column 'usage_count' to 'download_keys'...")
                conn.execute(text("ALTER TABLE download_keys ADD COLUMN `usage_count` INT DEFAULT 0"))
                conn.commit()
        except Exception as e:
            print(f"Error checking column usage_count: {e}")

        # Check if 'expires_at' column exists
        try:
            result = conn.execute(text("SHOW COLUMNS FROM download_keys LIKE 'expires_at'"))
            if result.fetchone():
                print("Column 'expires_at' in 'download_keys' already exists.")
            else:
                print("Adding column 'expires_at' to 'download_keys'...")
                conn.execute(text("ALTER TABLE download_keys ADD COLUMN `expires_at` DATETIME NULL"))
                conn.commit()
        except Exception as e:
            print(f"Error checking column expires_at: {e}")

        # Check if 'max_uses' column exists
        try:
            result = conn.execute(text("SHOW COLUMNS FROM download_keys LIKE 'max_uses'"))
            if result.fetchone():
                print("Column 'max_uses' in 'download_keys' already exists.")
            else:
                print("Adding column 'max_uses' to 'download_keys'...")
                conn.execute(text("ALTER TABLE download_keys ADD COLUMN `max_uses` INT NULL"))
                conn.commit()
        except Exception as e:
            print(f"Error checking column max_uses: {e}")

    print("Schema update complete.")

if __name__ == "__main__":
    upgrade_schema()
