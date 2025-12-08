import logging
import json
import sys
from datetime import datetime
from typing import Any, Dict


class JSONFormatter(logging.Formatter):
    """
    JSON formatter for structured logging
    Compatible with FluentBit and CloudWatch
    """
    
    def format(self, record: logging.LogRecord) -> str:
        log_data: Dict[str, Any] = {
            'timestamp': datetime.utcfromtimestamp(record.created).isoformat() + 'Z',
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        if hasattr(record, 'image_id'):
            log_data['image_id'] = record.image_id
        
        return json.dumps(log_data)


def setup_logging(app_name: str = "image-gallery", log_level: str = "INFO"):
    """
    Setup structured logging for the application
    
    Args:
        app_name: Name of the application
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
    """
    
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove existing handlers
    logger.handlers = []
    
    # Create console handler with JSON formatter
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(JSONFormatter())
    
    # Add handler to logger
    logger.addHandler(console_handler)
    
    # Log startup message
    logger.info(
        f"{app_name} logging initialized",
        extra={'app_name': app_name, 'log_level': log_level}
    )
    
    return logger


# Middleware for request logging
class RequestLoggingMiddleware:
    """Middleware to log all HTTP requests"""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope['type'] == 'http':
            logger = logging.getLogger(__name__)
            
            # Log request
            logger.info(
                "HTTP request",
                extra={
                    'method': scope['method'],
                    'path': scope['path'],
                    'client': scope.get('client', ['unknown'])[0]
                }
            )
        
        await self.app(scope, receive, send)
