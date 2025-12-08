# Image Gallery - FastAPI & S3

A modern, interactive image gallery application built with FastAPI and AWS S3.

## Features

- 📤 Upload images to S3
- 🖼️ View images in a beautiful gallery
- ✏️ Edit image metadata (title, description, tags)
- 🗑️ Delete images
- 🔍 Automatic thumbnail generation
- 📱 Responsive design
- 🚀 Fast API with async support
- 📊 Health checks and monitoring

## Tech Stack

**Backend:**
- FastAPI (Python web framework)
- boto3 (AWS SDK)
- Pillow (Image processing)
- Pydantic (Data validation)

**Frontend:**
- HTML5
- Bootstrap 5
- Vanilla JavaScript

**Infrastructure:**
- AWS S3 (Storage)
- Docker (Containerization)
- Kubernetes (Orchestration)

## Prerequisites

- Python 3.11+
- AWS Account with S3 bucket
- Docker (for containerization)
- kubectl & helm (for Kubernetes deployment)

## Local Development

### 1. Clone the repository

```bash
git clone <repository-url>
cd image-gallery
```

### 2. Create virtual environment

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure environment

Create `.env` file from `.env.example`:

```bash
cp .env.example .env
```

Edit `.env` with your AWS credentials:

```env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET_NAME=your-bucket-name
```

### 5. Create S3 bucket

```bash
aws s3 mb s3://your-bucket-name --region us-east-1
```

### 6. Run the application

```bash
uvicorn main:app --reload
```

Visit: http://localhost:8000

API Documentation: http://localhost:8000/docs

## Docker

### Build image

```bash
docker build -t image-gallery:latest .
```

### Run container

```bash
docker run -p 8000:8000 \
  -e AWS_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=your_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret \
  -e S3_BUCKET_NAME=your-bucket \
  image-gallery:latest
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Main gallery page |
| GET | `/health` | Health check |
| GET | `/api/images` | List all images |
| GET | `/api/images/{id}` | Get image by ID |
| POST | `/api/images` | Upload new image |
| PUT | `/api/images/{id}` | Update image metadata |
| DELETE | `/api/images/{id}` | Delete image |
| GET | `/docs` | Swagger UI |

## Project Structure

```
image-gallery/
├── app/
│   ├── models/
│   │   └── schemas.py          # Pydantic models
│   ├── routers/
│   │   └── images.py           # API routes
│   ├── services/
│   │   └── s3_service.py       # S3 operations
│   └── config.py               # Configuration
├── static/
│   ├── style.css               # Styles
│   └── app.js                  # Frontend JS
├── templates/
│   └── index.html              # Main page
├── main.py                     # FastAPI app
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Docker configuration
├── .env.example                # Environment template
└── README.md                   # This file
```

## S3 Bucket Structure

```
your-bucket/
├── images/                     # Original images
│   └── {timestamp}_{filename}
├── thumbnails/                 # Thumbnails (300x300)
│   └── {timestamp}_{filename}
└── metadata/                   # JSON metadata
    └── {timestamp}_{filename}.json
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `us-east-1` |
| `AWS_ACCESS_KEY_ID` | AWS access key | Required |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | Required |
| `S3_BUCKET_NAME` | S3 bucket name | Required |
| `USE_IAM_ROLE` | Use IAM role instead of keys | `false` |
| `APP_ENV` | Environment | `development` |
| `LOG_LEVEL` | Logging level | `INFO` |

## Kubernetes Deployment

Coming in next steps:
- Kubernetes manifests
- Helm charts
- CI/CD pipelines
- Monitoring setup

## Health Checks

The `/health` endpoint returns:

```json
{
  "status": "healthy",
  "timestamp": "2024-12-07T22:00:00",
  "s3_connection": true
}
```

## License

MIT

## Author

DevOps Engineer
