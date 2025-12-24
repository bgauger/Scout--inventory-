#!/usr/bin/env python3
"""
Raspberry Pi Service Management Application
A Flask-based web application for monitoring and managing Docker containers
on a Raspberry Pi with a 7-inch touchscreen display.
"""

import os
import logging
from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
import docker
from datetime import datetime

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
WEB_CONTAINER = os.getenv('WEB_CONTAINER_NAME', 'webapp')
DB_CONTAINER = os.getenv('DB_CONTAINER_NAME', 'database')
REFRESH_INTERVAL = int(os.getenv('REFRESH_INTERVAL', '5000'))

# Initialize Docker client
try:
    docker_client = docker.from_env()
    logger.info("Docker client initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Docker client: {e}")
    docker_client = None


def get_container_status(container_name):
    """
    Get the status of a Docker container.

    Args:
        container_name (str): Name of the container

    Returns:
        dict: Container status information
    """
    if not docker_client:
        return {
            'name': container_name,
            'status': 'unknown',
            'state': 'Docker not available',
            'error': 'Docker client not initialized'
        }

    try:
        container = docker_client.containers.get(container_name)
        return {
            'name': container_name,
            'status': container.status,
            'state': container.attrs['State']['Status'],
            'started_at': container.attrs['State'].get('StartedAt', 'N/A'),
            'id': container.short_id,
            'image': container.image.tags[0] if container.image.tags else 'unknown'
        }
    except docker.errors.NotFound:
        return {
            'name': container_name,
            'status': 'not_found',
            'state': 'Container not found',
            'error': f'Container {container_name} does not exist'
        }
    except Exception as e:
        logger.error(f"Error getting status for {container_name}: {e}")
        return {
            'name': container_name,
            'status': 'error',
            'state': 'Error',
            'error': str(e)
        }


def restart_container(container_name):
    """
    Restart a Docker container.

    Args:
        container_name (str): Name of the container to restart

    Returns:
        dict: Result of the restart operation
    """
    if not docker_client:
        return {
            'success': False,
            'message': 'Docker client not initialized'
        }

    try:
        container = docker_client.containers.get(container_name)
        container.restart(timeout=10)
        logger.info(f"Successfully restarted container: {container_name}")
        return {
            'success': True,
            'message': f'Container {container_name} restarted successfully'
        }
    except docker.errors.NotFound:
        return {
            'success': False,
            'message': f'Container {container_name} not found'
        }
    except Exception as e:
        logger.error(f"Error restarting {container_name}: {e}")
        return {
            'success': False,
            'message': str(e)
        }


@app.route('/')
def index():
    """Render the main dashboard page."""
    return render_template('index.html',
                         refresh_interval=REFRESH_INTERVAL,
                         web_container=WEB_CONTAINER,
                         db_container=DB_CONTAINER)


@app.route('/api/status')
def api_status():
    """Get status of all monitored containers."""
    web_status = get_container_status(WEB_CONTAINER)
    db_status = get_container_status(DB_CONTAINER)

    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'containers': {
            'web': web_status,
            'database': db_status
        }
    })


@app.route('/api/restart/<container_type>', methods=['POST'])
def api_restart(container_type):
    """
    Restart a specific container.

    Args:
        container_type (str): Either 'web' or 'database'
    """
    if container_type == 'web':
        container_name = WEB_CONTAINER
    elif container_type == 'database':
        container_name = DB_CONTAINER
    else:
        return jsonify({
            'success': False,
            'message': f'Invalid container type: {container_type}'
        }), 400

    result = restart_container(container_name)
    status_code = 200 if result['success'] else 500
    return jsonify(result), status_code


@app.route('/api/health')
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'docker_available': docker_client is not None,
        'timestamp': datetime.now().isoformat()
    })


if __name__ == '__main__':
    port = int(os.getenv('FLASK_PORT', '5000'))
    host = os.getenv('FLASK_HOST', '0.0.0.0')

    logger.info(f"Starting Service Management App on {host}:{port}")
    app.run(host=host, port=port, debug=False)
