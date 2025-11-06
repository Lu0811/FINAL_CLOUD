// La configuración de API_BASE_URL viene de config.js

// Estado de la aplicación
let tasks = [];
let currentFilter = 'all';
let currentDate = new Date();

// Elementos del DOM
const taskTitleInput = document.getElementById('taskTitle');
const taskDateInput = document.getElementById('taskDate');
const tasksContainer = document.getElementById('tasksContainer');
const totalTasksElement = document.getElementById('totalTasks');
const completedTasksElement = document.getElementById('completedTasks');
const pendingTasksElement = document.getElementById('pendingTasks');
const connectionStatus = document.getElementById('connectionStatus');
const statusBar = document.getElementById('statusBar');
const currentMonthElement = document.getElementById('currentMonth');
const calendarGrid = document.getElementById('calendarGrid');

// Inicializar la aplicación
document.addEventListener('DOMContentLoaded', function() {
    console.log('Agenda Pro iniciada');
    setupEventListeners();
    initializeCalendar();
    loadTasks();
    checkBackendHealth();
    
    // Configurar fecha por defecto
    taskDateInput.value = new Date().toISOString().split('T')[0];
});

// Configurar event listeners
function setupEventListeners() {
    taskTitleInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter' && taskTitleInput.value.trim()) {
            addTask();
        }
    });
}

// Verificar estado del backend
async function checkBackendHealth() {
    try {
        const response = await fetch(`${API_BASE_URL}/health`);
        if (response.ok) {
            updateConnectionStatus('connected', 'Backend conectado');
        } else {
            updateConnectionStatus('disconnected', 'Backend no disponible');
        }
    } catch (error) {
        updateConnectionStatus('disconnected', 'Sin conexión');
        console.error('Error verificando backend:', error);
    }
}

// Actualizar estado de conexión
function updateConnectionStatus(status, message) {
    connectionStatus.className = `connection-status ${status}`;
    connectionStatus.textContent = message;
    
    setTimeout(() => {
        connectionStatus.style.display = 'none';
    }, 3000);
}

// Mostrar mensaje en status bar
function showStatusMessage(message, type = 'info', duration = 3000) {
    statusBar.textContent = message;
    statusBar.className = `status-bar ${type}`;
    statusBar.style.display = 'block';
    
    setTimeout(() => {
        statusBar.style.display = 'none';
    }, duration);
}

// Cargar todas las tareas desde el backend
async function loadTasks() {
    try {
        showLoadingMessage('Cargando tareas...');
        
        const response = await fetch(`${API_BASE_URL}/tasks`);
        
        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        tasks = await response.json();
        console.log(`Cargadas ${tasks.length} tareas`);
        
        renderTasks();
        updateStats();
        updateCalendar();
        
    } catch (error) {
        console.error('Error al cargar tareas:', error);
        showErrorMessage(`Error al cargar tareas: ${error.message}`);
        updateConnectionStatus('disconnected', 'Error de conexión');
    }
}

// Agregar nueva tarea
async function addTask() {
    const title = taskTitleInput.value.trim();
    const date = taskDateInput.value;
    
    if (!title) {
        showStatusMessage('Por favor, escribe una tarea', 'error');
        taskTitleInput.focus();
        return;
    }
    
    try {
        const newTask = {
            title: title,
            due_date: date || null,
            done: false
        };
        
        const response = await fetch(`${API_BASE_URL}/tasks`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(newTask)
        });
        
        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        const createdTask = await response.json();
        tasks.unshift(createdTask);
        
        // Limpiar formulario
        taskTitleInput.value = '';
        taskDateInput.value = new Date().toISOString().split('T')[0];
        
        renderTasks();
        updateStats();
        updateCalendar();
        
        showStatusMessage('Tarea agregada correctamente', 'success');
        
    } catch (error) {
        console.error('Error al crear tarea:', error);
        showStatusMessage(`Error al crear tarea: ${error.message}`, 'error');
    }
}

// Alternar estado de completado de una tarea
async function toggleTask(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;
    
    try {
        const updatedTask = {
            ...task,
            done: !task.done
        };
        
        const response = await fetch(`${API_BASE_URL}/tasks/${taskId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(updatedTask)
        });
        
        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        const result = await response.json();
        
        // Actualizar tarea en la lista local
        const index = tasks.findIndex(t => t.id === taskId);
        if (index !== -1) {
            tasks[index] = result;
        }
        
        renderTasks();
        updateStats();
        
        const status = result.done ? 'completada' : 'marcada como pendiente';
        showStatusMessage(`Tarea ${status}`, 'success');
        
    } catch (error) {
        console.error('Error al actualizar tarea:', error);
        showStatusMessage(`Error al actualizar tarea: ${error.message}`, 'error');
    }
}

// Eliminar tarea
async function deleteTask(taskId) {
    if (!confirm('¿Estás seguro de que quieres eliminar esta tarea?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/tasks/${taskId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        // Remover tarea de la lista local
        tasks = tasks.filter(t => t.id !== taskId);
        
        renderTasks();
        updateStats();
        updateCalendar();
        
        showStatusMessage('Tarea eliminada', 'success');
        
    } catch (error) {
        console.error('Error al eliminar tarea:', error);
        showStatusMessage(`Error al eliminar tarea: ${error.message}`, 'error');
    }
}

// Filtrar tareas
function filterTasks(filter) {
    currentFilter = filter;
    
    // Actualizar tabs activos
    document.querySelectorAll('.filter-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    event.target.classList.add('active');
    
    renderTasks();
}

// Renderizar lista de tareas
function renderTasks() {
    let filteredTasks = tasks;
    
    // Aplicar filtro
    switch (currentFilter) {
        case 'pending':
            filteredTasks = tasks.filter(task => !task.done);
            break;
        case 'completed':
            filteredTasks = tasks.filter(task => task.done);
            break;
        default:
            filteredTasks = tasks;
    }
    
    if (filteredTasks.length === 0) {
        const message = currentFilter === 'all' ? 
            'No hay tareas. ¡Agrega tu primera tarea!' :
            `No hay tareas ${currentFilter === 'pending' ? 'pendientes' : 'completadas'}.`;
            
        tasksContainer.innerHTML = `
            <div class="empty-state">
                <h3>${message}</h3>
                <p>Las tareas aparecerán aquí cuando las agregues.</p>
            </div>
        `;
        return;
    }
    
    const tasksHTML = filteredTasks.map(task => {
        const dueDate = task.due_date ? new Date(task.due_date).toLocaleDateString('es-ES') : null;
        const isOverdue = task.due_date && !task.done && new Date(task.due_date) < new Date();
        
        return `
            <div class="task-item ${task.done ? 'completed' : ''} ${isOverdue ? 'overdue' : ''}">
                <div class="task-content">
                    <input type="checkbox" class="task-checkbox" 
                           ${task.done ? 'checked' : ''} 
                           onchange="toggleTask('${task.id}')">
                    <div class="task-details">
                        <div class="task-title">${task.title}</div>
                        <div class="task-meta">
                            <span class="task-created">Creada: ${new Date(task.created_at).toLocaleDateString('es-ES')}</span>
                            ${dueDate ? `<span class="task-date">Vence: ${dueDate}</span>` : ''}
                        </div>
                    </div>
                    <div class="task-actions">
                        <button class="btn btn-danger btn-small" onclick="deleteTask('${task.id}')">
                            Eliminar
                        </button>
                    </div>
                </div>
            </div>
        `;
    }).join('');
    
    tasksContainer.innerHTML = `<div class="task-list">${tasksHTML}</div>`;
}

// Actualizar estadísticas
function updateStats() {
    const total = tasks.length;
    const completed = tasks.filter(task => task.done).length;
    const pending = total - completed;
    
    totalTasksElement.textContent = total;
    completedTasksElement.textContent = completed;
    pendingTasksElement.textContent = pending;
}

// Mostrar mensaje de carga
function showLoadingMessage(message) {
    tasksContainer.innerHTML = `<div class="loading">${message}</div>`;
}

// Mostrar mensaje de error
function showErrorMessage(message) {
    tasksContainer.innerHTML = `
        <div class="empty-state">
            <h3>Error</h3>
            <p>${message}</p>
            <button class="btn btn-primary" onclick="loadTasks()">Reintentar</button>
        </div>
    `;
}

// === FUNCIONALIDAD DEL CALENDARIO ===

function initializeCalendar() {
    updateCalendarHeader();
    renderCalendar();
}

function updateCalendarHeader() {
    const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    currentMonthElement.textContent = `${months[currentDate.getMonth()]} ${currentDate.getFullYear()}`;
}

function changeMonth(delta) {
    currentDate.setMonth(currentDate.getMonth() + delta);
    updateCalendarHeader();
    renderCalendar();
}

function renderCalendar() {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    
    // Primer día del mes
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    
    // Obtener primer día de la semana (domingo = 0)
    const startDay = firstDay.getDay();
    
    // Crear headers de días
    const dayHeaders = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
    
    let calendarHTML = '';
    
    // Headers de días de la semana
    dayHeaders.forEach(day => {
        calendarHTML += `<div class="calendar-day-header">${day}</div>`;
    });
    
    // Días vacíos al inicio
    for (let i = 0; i < startDay; i++) {
        calendarHTML += '<div class="calendar-day empty"></div>';
    }
    
    // Días del mes
    for (let day = 1; day <= lastDay.getDate(); day++) {
        const date = new Date(year, month, day);
        const isToday = date.toDateString() === new Date().toDateString();
        const dateStr = date.toISOString().split('T')[0];
        
        // Verificar si hay tareas en este día
        const hasTasks = tasks.some(task => 
            task.due_date && task.due_date.split('T')[0] === dateStr
        );
        
        const classes = [
            'calendar-day',
            isToday ? 'today' : '',
            hasTasks ? 'has-tasks' : ''
        ].filter(Boolean).join(' ');
        
        calendarHTML += `
            <div class="${classes}" onclick="selectDate('${dateStr}')">
                ${day}
            </div>
        `;
    }
    
    calendarGrid.innerHTML = calendarHTML;
}

function selectDate(dateStr) {
    taskDateInput.value = dateStr;
    taskTitleInput.focus();
    
    // Filtrar tareas por fecha seleccionada
    const tasksForDate = tasks.filter(task => 
        task.due_date && task.due_date.split('T')[0] === dateStr
    );
    
    if (tasksForDate.length > 0) {
        showStatusMessage(`${tasksForDate.length} tarea(s) para esta fecha`, 'info');
    }
}

function updateCalendar() {
    renderCalendar();
}

// Verificar estado del backend periódicamente
setInterval(checkBackendHealth, 30000); // Cada 30 segundos
