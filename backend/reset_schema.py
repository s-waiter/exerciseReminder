from app.database import engine, Base
from app import models
from sqlalchemy import text

def reset_database():
    print("Resetting database schema...")
    with engine.connect() as conn:
        print("Disabling foreign key checks...")
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        
        # Explicitly drop known orphan tables that were removed from models
        print("Dropping orphan tables...")
        conn.execute(text("DROP TABLE IF EXISTS download_logs"))
        conn.execute(text("DROP TABLE IF EXISTS daily_usage"))
        # conn.execute(text("DROP TABLE IF EXISTS user_backups"))
        
        print("Dropping remaining tables defined in models...")
        Base.metadata.drop_all(bind=conn)
        
        print("Creating all tables...")
        Base.metadata.create_all(bind=conn)
        
        print("Re-enabling foreign key checks...")
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
        conn.commit()

    print("Database schema reset complete.")

if __name__ == "__main__":
    reset_database()
