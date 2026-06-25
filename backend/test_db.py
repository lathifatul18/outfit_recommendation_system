from app import app, db

with app.app_context():
    try:
        db.engine.connect()
        print("Database connection")
    except Exception as e:
        print("Database error")
        print(e)