import boto3
import json
import logging
from typing import List, Optional, Dict
from datetime import datetime
from botocore.exceptions import ClientError
from app.config import settings
from io import BytesIO
from PIL import Image

logger = logging.getLogger(__name__)


class S3Service:
    """Service for managing images in S3"""
    
    def __init__(self):
        """Initialize S3 client"""
        if settings.use_iam_role:
            # Use IAM role (for EKS/EC2)
            self.s3_client = boto3.client('s3', region_name=settings.aws_region)
        else:
            # Use access keys (for local development)
            self.s3_client = boto3.client(
                's3',
                region_name=settings.aws_region,
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key
            )
        
        self.bucket_name = settings.s3_bucket_name
        logger.info(f"S3Service initialized with bucket: {self.bucket_name}")
    
    async def check_connection(self) -> bool:
        """Check S3 connection"""
        try:
            self.s3_client.head_bucket(Bucket=self.bucket_name)
            return True
        except ClientError as e:
            logger.error(f"S3 connection failed: {e}")
            return False
    
    def _generate_image_id(self, filename: str) -> str:
        """Generate unique image ID"""
        timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S%f")
        return f"{timestamp}_{filename}"
    
    def _create_thumbnail(self, image_data: bytes, max_size: tuple = (300, 300)) -> bytes:
        """Create thumbnail from image data"""
        try:
            image = Image.open(BytesIO(image_data))
            image.thumbnail(max_size, Image.Resampling.LANCZOS)
            
            thumb_io = BytesIO()
            image.save(thumb_io, format=image.format or 'JPEG')
            thumb_io.seek(0)
            
            return thumb_io.getvalue()
        except Exception as e:
            logger.error(f"Failed to create thumbnail: {e}")
            return image_data
    
    async def upload_image(
        self,
        file_data: bytes,
        filename: str,
        content_type: str,
        title: str,
        description: Optional[str] = None,
        tags: List[str] = []
    ) -> Dict:
        """Upload image to S3 with metadata"""
        try:
            image_id = self._generate_image_id(filename)
            image_key = f"images/{image_id}"
            thumb_key = f"thumbnails/{image_id}"
            metadata_key = f"metadata/{image_id}.json"
            
            # Upload original image
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=image_key,
                Body=file_data,
                ContentType=content_type
            )
            logger.info(f"Uploaded image: {image_key}")
            
            # Create and upload thumbnail
            thumbnail_data = self._create_thumbnail(file_data)
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=thumb_key,
                Body=thumbnail_data,
                ContentType=content_type
            )
            logger.info(f"Uploaded thumbnail: {thumb_key}")
            
            # Create metadata
            metadata = {
                "id": image_id,
                "title": title,
                "description": description,
                "tags": tags,
                "filename": filename,
                "content_type": content_type,
                "size": len(file_data),
                "created_at": datetime.utcnow().isoformat(),
                "image_key": image_key,
                "thumbnail_key": thumb_key
            }
            
            # Upload metadata
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=metadata_key,
                Body=json.dumps(metadata),
                ContentType="application/json"
            )
            logger.info(f"Uploaded metadata: {metadata_key}")
            
            return metadata
            
        except ClientError as e:
            logger.error(f"Failed to upload image: {e}")
            raise
    
    async def list_images(self) -> List[Dict]:
        """List all images from S3"""
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix="metadata/"
            )
            
            images = []
            if 'Contents' in response:
                for obj in response['Contents']:
                    metadata_key = obj['Key']
                    
                    # Get metadata
                    metadata_obj = self.s3_client.get_object(
                        Bucket=self.bucket_name,
                        Key=metadata_key
                    )
                    metadata = json.loads(metadata_obj['Body'].read())
                    
                    # Generate presigned URLs
                    metadata['url'] = self.s3_client.generate_presigned_url(
                        'get_object',
                        Params={
                            'Bucket': self.bucket_name,
                            'Key': metadata['image_key']
                        },
                        ExpiresIn=3600
                    )
                    
                    metadata['thumbnail_url'] = self.s3_client.generate_presigned_url(
                        'get_object',
                        Params={
                            'Bucket': self.bucket_name,
                            'Key': metadata['thumbnail_key']
                        },
                        ExpiresIn=3600
                    )
                    
                    images.append(metadata)
            
            # Sort by created_at (newest first)
            images.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            
            return images
            
        except ClientError as e:
            logger.error(f"Failed to list images: {e}")
            raise
    
    async def get_image(self, image_id: str) -> Optional[Dict]:
        """Get single image metadata"""
        try:
            metadata_key = f"metadata/{image_id}.json"
            
            metadata_obj = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=metadata_key
            )
            metadata = json.loads(metadata_obj['Body'].read())
            
            # Generate presigned URLs
            metadata['url'] = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': metadata['image_key']
                },
                ExpiresIn=3600
            )
            
            metadata['thumbnail_url'] = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': metadata['thumbnail_key']
                },
                ExpiresIn=3600
            )
            
            return metadata
            
        except ClientError as e:
            logger.warning(f"Image not found: {image_id}")
            return None
    
    async def update_metadata(
        self,
        image_id: str,
        title: Optional[str] = None,
        description: Optional[str] = None,
        tags: Optional[List[str]] = None
    ) -> Optional[Dict]:
        """Update image metadata"""
        try:
            metadata_key = f"metadata/{image_id}.json"
            
            # Get existing metadata
            metadata_obj = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=metadata_key
            )
            metadata = json.loads(metadata_obj['Body'].read())
            
            # Update fields
            if title is not None:
                metadata['title'] = title
            if description is not None:
                metadata['description'] = description
            if tags is not None:
                metadata['tags'] = tags
            
            metadata['updated_at'] = datetime.utcnow().isoformat()
            
            # Save updated metadata
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=metadata_key,
                Body=json.dumps(metadata),
                ContentType="application/json"
            )
            
            logger.info(f"Updated metadata: {image_id}")
            return metadata
            
        except ClientError as e:
            logger.error(f"Failed to update metadata: {e}")
            return None
    
    async def delete_image(self, image_id: str) -> bool:
        """Delete image and its metadata from S3"""
        try:
            image_key = f"images/{image_id}"
            thumb_key = f"thumbnails/{image_id}"
            metadata_key = f"metadata/{image_id}.json"
            
            # Delete all objects
            objects_to_delete = [
                {'Key': image_key},
                {'Key': thumb_key},
                {'Key': metadata_key}
            ]
            
            self.s3_client.delete_objects(
                Bucket=self.bucket_name,
                Delete={'Objects': objects_to_delete}
            )
            
            logger.info(f"Deleted image: {image_id}")
            return True
            
        except ClientError as e:
            logger.error(f"Failed to delete image: {e}")
            return False


# Create singleton instance
s3_service = S3Service()
