from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import os
import uuid
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, 
     origins=["*"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
     allow_headers=["Content-Type", "Authorization"],
     supports_credentials=True)

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres-service'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'agenda123'),
    'database': os.getenv('DB_NAME', 'agendaapp'),
    'port': 5432
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"Error connecting to PostgreSQL: {str(e)}")
        return None

def init_database():
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute('''
                CREATE TABLE IF NOT EXISTS tasks (
                    id VARCHAR(50) PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    done BOOLEAN DEFAULT FALSE,
                    due_date DATE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            conn.commit()
            cur.close()
            conn.close()
            logger.info("Database initialized")
            return True
        except Exception as e:
            logger.error(f"Error initializing database: {str(e)}")
            return False
    return False

@app.route('/health', methods=['GET'])
def health_check():
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM tasks")
            count = cur.fetchone()[0]
            cur.close()
            conn.close()
            return jsonify({
                "status": "healthy", 
                "database": "connected",
                "tasks_count": count,
                "timestamp": datetime.now().isoformat()
            })
        except Exception as e:
            return jsonify({
                "status": "unhealthy", 
                "database": "error",
                "error": str(e)
            }), 500
    return jsonify({"status": "unhealthy", "database": "disconnected"}), 500

@app.route('/tasks', methods=['GET'])
def get_tasks():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
        
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT * FROM tasks ORDER BY created_at DESC")
        tasks = cur.fetchall()
        
        tasks_list = []
        for task in tasks:
            task_dict = dict(task)
            if task_dict['created_at']:
                task_dict['created_at'] = task_dict['created_at'].isoformat()
            if task_dict['updated_at']:
                task_dict['updated_at'] = task_dict['updated_at'].isoformat()
            if task_dict['due_date']:
                task_dict['due_date'] = task_dict['due_date'].isoformat()
            tasks_list.append(task_dict)
        
        cur.close()
        conn.close()
        return jsonify(tasks_list)
    except Exception as e:
        logger.error(f"Error getting tasks: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks', methods=['POST'])
def create_task():
    try:
        data = request.get_json()
        if not data or 'title' not in data:
            return jsonify({"error": "Title is required"}), 400
        
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
        
        task_id = str(uuid.uuid4())
        cur = conn.cursor()
        
        due_date = data.get('due_date')
        if due_date:
            try:
                due_date = datetime.fromisoformat(due_date.replace('Z', '+00:00')).date()
            except:
                due_date = None
        
        cur.execute('''
            INSERT INTO tasks (id, title, done, due_date, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING *
        ''', (task_id, data['title'], data.get('done', False), due_date, datetime.now(), datetime.now()))
        
        new_task = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        task_dict = {
            "id": new_task[0],
            "title": new_task[1],
            "done": new_task[2],
            "due_date": new_task[3].isoformat() if new_task[3] else None,
            "created_at": new_task[4].isoformat(),
            "updated_at": new_task[5].isoformat()
        }
        
        return jsonify(task_dict), 201
    except Exception as e:
        logger.error(f"Error creating task: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    try:
        data = request.get_json()
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
        
        cur = conn.cursor()
        updates = []
        values = []
        
        if 'title' in data:
            updates.append("title = %s")
            values.append(data['title'])
        
        if 'done' in data:
            updates.append("done = %s")
            values.append(data['done'])
        
        if 'due_date' in data:
            due_date = data['due_date']
            if due_date:
                try:
                    due_date = datetime.fromisoformat(due_date.replace('Z', '+00:00')).date()
                except:
                    due_date = None
            updates.append("due_date = %s")
            values.append(due_date)
        
        if updates:
            updates.append("updated_at = %s")
            values.append(datetime.now())
            values.append(task_id)
            
            query = f"UPDATE tasks SET {', '.join(updates)} WHERE id = %s RETURNING *"
            cur.execute(query, values)
            
            updated_task = cur.fetchone()
            if not updated_task:
                return jsonify({"error": "Task not found"}), 404
            
            conn.commit()
            
            task_dict = {
                "id": updated_task[0],
                "title": updated_task[1],
                "done": updated_task[2],
                "due_date": updated_task[3].isoformat() if updated_task[3] else None,
                "created_at": updated_task[4].isoformat(),
                "updated_at": updated_task[5].isoformat()
            }
            
            cur.close()
            conn.close()
            return jsonify(task_dict)
        return jsonify({"error": "No data to update"}), 400
    except Exception as e:
        logger.error(f"Error updating task: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
        
        cur = conn.cursor()
        cur.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
        
        if cur.rowcount == 0:
            return jsonify({"error": "Task not found"}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Task deleted successfully"})
    except Exception as e:
        logger.error(f"Error deleting task: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting Flask with PostgreSQL")
    if init_database():
        logger.info("Server ready")
        app.run(host='0.0.0.0', port=5000, debug=False)
    else:
        logger.error("Failed to initialize database")
