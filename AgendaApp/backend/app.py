from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
import os
from datetime import datetime
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Crear aplicación Flask
app = Flask(__name__)

# Habilitar CORS para permitir requests desde el frontend
CORS(app)

# Configuración de MongoDB
# En desarrollo local usa localhost, en Kubernetes usa el nombre del servicio
MONGO_HOST = os.getenv('MONGO_HOST', 'localhost')
MONGO_PORT = int(os.getenv('MONGO_PORT', 27017))
MONGO_DB = os.getenv('MONGO_DB', 'agendaapp')

logger.info(f" Conectando a MongoDB en {MONGO_HOST}:{MONGO_PORT}")

# Conectar a MongoDB
try:
    client = MongoClient(MONGO_HOST, MONGO_PORT, serverSelectionTimeoutMS=5000)
    db = client[MONGO_DB]
    tasks_collection = db.tasks
    
    # Probar la conexión
    client.admin.command('ping')
    logger.info(" Conectado exitosamente a MongoDB")
    
except Exception as e:
    logger.error(f" Error al conectar con MongoDB: {e}")
    # La app seguirá ejecutándose, pero las operaciones de DB fallarán

# Función auxiliar para convertir ObjectId a string
def serialize_task(task):
    if task:
        task['_id'] = str(task['_id'])
        return task
    return None

# Función auxiliar para obtener estadísticas
def get_database_stats():
    try:
        total_tasks = tasks_collection.count_documents({})
        completed_tasks = tasks_collection.count_documents({"done": True})
        pending_tasks = total_tasks - completed_tasks
        
        return {
            "total": total_tasks,
            "completed": completed_tasks,
            "pending": pending_tasks
        }
    except Exception as e:
        logger.error(f"Error al obtener estadísticas: {e}")
        return {"total": 0, "completed": 0, "pending": 0}

# ============================================================================
# RUTAS DE LA API
# ============================================================================

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint para verificar que el backend está funcionando"""
    try:
        # Probar conexión a MongoDB
        client.admin.command('ping')
        mongo_status = "connected"
    except Exception as e:
        mongo_status = f"error: {str(e)}"
    
    return jsonify({
        "status": "healthy",
        "service": "AgendaApp Backend",
        "timestamp": datetime.now().isoformat(),
        "mongodb": mongo_status,
        "version": "1.0.0"
    })

@app.route('/tasks', methods=['GET'])
def get_all_tasks():
    """Obtener todas las tareas"""
    try:
        logger.info(" Obteniendo todas las tareas")
        
        # Obtener todas las tareas ordenadas por fecha de creación
        tasks_cursor = tasks_collection.find().sort("_id", -1)
        tasks = [serialize_task(task) for task in tasks_cursor]
        
        stats = get_database_stats()
        
        logger.info(f" Encontradas {len(tasks)} tareas")
        
        return jsonify({
            "success": True,
            "tasks": tasks,
            "stats": stats,
            "total": len(tasks)
        })
        
    except Exception as e:
        logger.error(f" Error al obtener tareas: {e}")
        return jsonify({
            "success": False,
            "error": str(e),
            "tasks": []
        }), 500

@app.route('/tasks', methods=['POST'])
def create_task():
    """Crear una nueva tarea"""
    try:
        data = request.get_json()
        
        if not data or 'title' not in data:
            return jsonify({
                "success": False,
                "error": "El campo 'title' es requerido"
            }), 400
        
        # Crear nueva tarea
        new_task = {
            "title": data['title'].strip(),
            "done": data.get('done', False),
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }
        
        # Insertar en MongoDB
        result = tasks_collection.insert_one(new_task)
        
        # Obtener la tarea creada
        created_task = tasks_collection.find_one({"_id": result.inserted_id})
        
        logger.info(f" Nueva tarea creada: {new_task['title']}")
        
        return jsonify({
            "success": True,
            "message": "Tarea creada exitosamente",
            "task": serialize_task(created_task)
        }), 201
        
    except Exception as e:
        logger.error(f" Error al crear tarea: {e}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    """Actualizar una tarea existente"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                "success": False,
                "error": "No se proporcionaron datos para actualizar"
            }), 400
        
        # Preparar campos a actualizar
        update_fields = {"updated_at": datetime.now()}
        
        if 'title' in data:
            update_fields['title'] = data['title'].strip()
        if 'done' in data:
            update_fields['done'] = bool(data['done'])
        
        # Actualizar tarea
        result = tasks_collection.update_one(
            {"_id": ObjectId(task_id)},
            {"$set": update_fields}
        )
        
        if result.matched_count == 0:
            return jsonify({
                "success": False,
                "error": "Tarea no encontrada"
            }), 404
        
        # Obtener tarea actualizada
        updated_task = tasks_collection.find_one({"_id": ObjectId(task_id)})
        
        logger.info(f" Tarea actualizada: {task_id}")
        
        return jsonify({
            "success": True,
            "message": "Tarea actualizada exitosamente",
            "task": serialize_task(updated_task)
        })
        
    except Exception as e:
        logger.error(f" Error al actualizar tarea: {e}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    """Eliminar una tarea"""
    try:
        result = tasks_collection.delete_one({"_id": ObjectId(task_id)})
        
        if result.deleted_count == 0:
            return jsonify({
                "success": False,
                "error": "Tarea no encontrada"
            }), 404
        
        logger.info(f" Tarea eliminada: {task_id}")
        
        return jsonify({
            "success": True,
            "message": "Tarea eliminada exitosamente"
        })
        
    except Exception as e:
        logger.error(f" Error al eliminar tarea: {e}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/stats', methods=['GET'])
def get_stats():
    """Obtener estadísticas de las tareas"""
    try:
        stats = get_database_stats()
        
        return jsonify({
            "success": True,
            "stats": stats
        })
        
    except Exception as e:
        logger.error(f"❌ Error al obtener estadísticas: {e}")
        return jsonify({
            "success": False,
            "error": str(e),
            "stats": {"total": 0, "completed": 0, "pending": 0}
        }), 500

@app.route('/database/info', methods=['GET'])
def get_database_info():
    """Obtener información detallada de la base de datos - ÚTIL PARA DEBUG"""
    try:
        # Información general de la DB
        db_stats = db.command("dbstats")
        
        # Información de la colección de tareas
        collection_stats = db.command("collstats", "tasks")
        
        # Algunas tareas de ejemplo
        sample_tasks = list(tasks_collection.find().limit(3))
        
        return jsonify({
            "success": True,
            "database_info": {
                "name": MONGO_DB,
                "host": MONGO_HOST,
                "port": MONGO_PORT,
                "collections": db.list_collection_names(),
                "db_size_mb": round(db_stats.get("dataSize", 0) / (1024*1024), 2),
                "tasks_collection": {
                    "count": collection_stats.get("count", 0),
                    "size_bytes": collection_stats.get("size", 0)
                }
            },
            "sample_tasks": [serialize_task(task) for task in sample_tasks],
            "stats": get_database_stats()
        })
        
    except Exception as e:
        logger.error(f" Error al obtener info de DB: {e}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "success": False,
        "error": "Endpoint no encontrado"
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "success": False,
        "error": "Error interno del servidor"
    }), 500

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    logger.info(" Iniciando AgendaApp Backend")
    logger.info(f" MongoDB: {MONGO_HOST}:{MONGO_PORT}")
    logger.info(f" Base de datos: {MONGO_DB}")
    
    # Ejecutar en todas las interfaces para que Kubernetes pueda acceder
    app.run(
        host='0.0.0.0', 
        port=5000, 
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )
