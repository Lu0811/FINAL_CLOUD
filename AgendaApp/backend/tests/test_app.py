import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app
import json


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_health_endpoint(client):
    """Test the health endpoint returns 200"""
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'service' in data
    assert 'timestamp' in data


def test_get_tasks_endpoint(client):
    """Test the tasks endpoint returns valid JSON"""
    response = client.get('/tasks')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert 'success' in data
    assert 'tasks' in data
    assert isinstance(data['tasks'], list)


def test_stats_endpoint(client):
    """Test the stats endpoint returns valid statistics"""
    response = client.get('/stats')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert 'success' in data
    assert 'stats' in data
    
    stats = data['stats']
    assert 'total' in stats
    assert 'completed' in stats
    assert 'pending' in stats
    assert isinstance(stats['total'], int)


def test_create_task_invalid_data(client):
    """Test creating a task with invalid data"""
    response = client.post('/tasks', 
                          data=json.dumps({}), 
                          content_type='application/json')
    assert response.status_code == 400
    
    data = json.loads(response.data)
    assert data['success'] is False
    assert 'error' in data


def test_create_and_delete_task(client):
    """Test creating and deleting a task"""
    # Create task
    task_data = {
        'title': 'Test task',
        'done': False
    }
    
    response = client.post('/tasks', 
                          data=json.dumps(task_data), 
                          content_type='application/json')
    assert response.status_code == 201
    
    data = json.loads(response.data)
    assert data['success'] is True
    assert 'task' in data
    
    task_id = data['task']['_id']
    assert task_id is not None
    
    # Verify task exists
    response = client.get('/tasks')
    data = json.loads(response.data)
    task_titles = [task['title'] for task in data['tasks']]
    assert 'Test task' in task_titles
    
    # Delete task
    response = client.delete(f'/tasks/{task_id}')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['success'] is True


def test_update_nonexistent_task(client):
    """Test updating a task that doesn't exist"""
    fake_id = '507f1f77bcf86cd799439011'
    response = client.put(f'/tasks/{fake_id}', 
                         data=json.dumps({'title': 'Updated'}), 
                         content_type='application/json')
    assert response.status_code == 404
    
    data = json.loads(response.data)
    assert data['success'] is False


def test_delete_nonexistent_task(client):
    """Test deleting a task that doesn't exist"""
    fake_id = '507f1f77bcf86cd799439011'
    response = client.delete(f'/tasks/{fake_id}')
    assert response.status_code == 404
    
    data = json.loads(response.data)
    assert data['success'] is False