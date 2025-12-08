from prometheus_client import Counter, Histogram, Gauge, Info
import time

# Application info
app_info = Info('app', 'Application information')
app_info.info({
    'version': '1.0.0',
    'name': 'image-gallery'
})

# Uptime
app_start_time = time.time()
app_uptime_seconds = Gauge(
    'app_uptime_seconds',
    'Application uptime in seconds'
)

def update_uptime():
    """Update uptime gauge"""
    app_uptime_seconds.set(time.time() - app_start_time)

# Health check
health_check_total = Counter(
    'health_check_total',
    'Total health check requests',
    ['status']
)

health_check_s3_status = Gauge(
    'health_check_s3_status',
    'S3 connection status (1=healthy, 0=unhealthy)'
)

# Custom metrics for image operations
image_uploads_total = Counter(
    'image_uploads_total',
    'Total number of image uploads',
    ['status']
)

image_upload_size_bytes = Histogram(
    'image_upload_size_bytes',
    'Size of uploaded images in bytes',
    buckets=[100_000, 500_000, 1_000_000, 5_000_000, 10_000_000]
)

image_deletions_total = Counter(
    'image_deletions_total',
    'Total number of image deletions',
    ['status']
)

images_stored_total = Gauge(
    'images_stored_total',
    'Current number of images in storage'
)

s3_operation_duration_seconds = Histogram(
    's3_operation_duration_seconds',
    'Duration of S3 operations',
    ['operation'],
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
)

# Connection pool
s3_connection_errors_total = Counter(
    's3_connection_errors_total',
    'Total S3 connection errors'
)


def track_image_upload(status: str, size: int):
    """Track image upload metrics"""
    image_uploads_total.labels(status=status).inc()
    if status == 'success':
        image_upload_size_bytes.observe(size)


def track_image_deletion(status: str):
    """Track image deletion metrics"""
    image_deletions_total.labels(status=status).inc()


def track_health_check(s3_healthy: bool):
    """Track health check"""
    status = 'healthy' if s3_healthy else 'unhealthy'
    health_check_total.labels(status=status).inc()
    health_check_s3_status.set(1 if s3_healthy else 0)


def track_s3_connection_error():
    """Track S3 connection error"""
    s3_connection_errors_total.inc()


def track_s3_operation(operation: str):
    """Context manager to track S3 operation duration"""
    class S3OperationTimer:
        def __enter__(self):
            self.start = time.time()
            return self
        
        def __exit__(self, *args):
            duration = time.time() - self.start
            s3_operation_duration_seconds.labels(operation=operation).observe(duration)
    
    return S3OperationTimer()
