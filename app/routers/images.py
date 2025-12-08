from fastapi import APIRouter, UploadFile, File, Form, HTTPException, status
from typing import List, Optional
from app.models.schemas import ImageResponse, ImageUpdate
from app.services.s3_service import s3_service
from app.metrics import track_image_upload, track_image_deletion, track_s3_operation
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/images", tags=["images"])


@router.get("/", response_model=List[ImageResponse])
async def list_images():
    """Get all images from gallery"""
    try:
        images = await s3_service.list_images()
        return images
    except Exception as e:
        logger.error(f"Error listing images: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list images"
        )


@router.get("/{image_id}", response_model=ImageResponse)
async def get_image(image_id: str):
    """Get single image by ID"""
    try:
        image = await s3_service.get_image(image_id)
        
        if not image:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found"
            )
        
        return image
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting image: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get image"
        )


@router.post("/", response_model=ImageResponse, status_code=status.HTTP_201_CREATED)
async def upload_image(
    file: UploadFile = File(...),
    title: str = Form(...),
    description: Optional[str] = Form(None),
    tags: Optional[str] = Form(None)
):
    """Upload new image to gallery"""
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an image"
            )
        
        # Validate file size (max 10MB)
        file_data = await file.read()
        if len(file_data) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File size must be less than 10MB"
            )
        
        # Parse tags
        tags_list = []
        if tags:
            tags_list = [tag.strip() for tag in tags.split(',') if tag.strip()]
        
        # Upload to S3
        metadata = await s3_service.upload_image(
            file_data=file_data,
            filename=file.filename,
            content_type=file.content_type,
            title=title,
            description=description,
            tags=tags_list
        )
        
        # Track successful upload
        track_image_upload('success', len(file_data))
        
        # Get full metadata with URLs
        image = await s3_service.get_image(metadata['id'])
        
        return image
        
    except HTTPException:
        track_image_upload('failed', 0)
        raise
    except Exception as e:
        logger.error(f"Error uploading image: {e}")
        track_image_upload('error', 0)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload image: {str(e)}"
        )


@router.put("/{image_id}", response_model=ImageResponse)
async def update_image(image_id: str, update_data: ImageUpdate):
    """Update image metadata"""
    try:
        # Check if image exists
        existing_image = await s3_service.get_image(image_id)
        if not existing_image:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found"
            )
        
        # Update metadata
        updated_metadata = await s3_service.update_metadata(
            image_id=image_id,
            title=update_data.title,
            description=update_data.description,
            tags=update_data.tags
        )
        
        if not updated_metadata:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update image"
            )
        
        # Get full metadata with URLs
        image = await s3_service.get_image(image_id)
        
        return image
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating image: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update image"
        )


@router.delete("/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_image(image_id: str):
    """Delete image from gallery"""
    try:
        # Check if image exists
        existing_image = await s3_service.get_image(image_id)
        if not existing_image:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found"
            )
        
        # Delete from S3
        success = await s3_service.delete_image(image_id)
        
        if not success:
            track_image_deletion('failed')
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete image"
            )
        
        track_image_deletion('success')
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting image: {e}")
        track_image_deletion('error')
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete image"
        )
