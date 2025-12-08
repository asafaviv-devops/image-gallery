from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from app.routers import images
from app.models.schemas import HealthResponse
from app.services.s3_service import s3_service
from datetime import datetime
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Image Gallery API",
    description="A simple image gallery with S3 storage",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Include routers
app.include_router(images.router)

# Setup Prometheus metrics
instrumentator = Instrumentator(
    should_group_status_codes=False,
    should_ignore_untemplated=True,
    should_respect_env_var=False,  # Always enable metrics
    should_instrument_requests_inprogress=True,
    excluded_handlers=[],  # Don't exclude /metrics
    inprogress_name="http_requests_inprogress",
    inprogress_labels=True,
)

# Expose metrics endpoint
instrumentator.instrument(app).expose(app, endpoint="/metrics", include_in_schema=True)


@app.get("/", response_class=HTMLResponse)
async def root():
    """Serve main HTML page"""
    try:
        with open("templates/index.html", "r") as f:
            return HTMLResponse(content=f.read())
    except FileNotFoundError:
        return HTMLResponse(
            content="<h1>Image Gallery</h1><p>API is running. Visit /docs for API documentation.</p>"
        )


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    from app.metrics import track_health_check, update_uptime
    
    # Update uptime
    update_uptime()
    
    # Check S3
    s3_status = await s3_service.check_connection()
    
    # Track health check
    track_health_check(s3_status)
    
    return HealthResponse(
        status="healthy" if s3_status else "degraded",
        timestamp=datetime.utcnow().isoformat(),
        s3_connection=s3_status
    )


@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    logger.info("Starting Image Gallery application...")
    
    # Initialize custom metrics
    from app.metrics import update_uptime
    update_uptime()
    logger.info("✅ Custom metrics initialized")
    
    # Check S3 connection
    s3_status = await s3_service.check_connection()
    if s3_status:
        logger.info("✅ S3 connection successful")
    else:
        logger.warning("⚠️  S3 connection failed")


@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    logger.info("Shutting down Image Gallery application...")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
