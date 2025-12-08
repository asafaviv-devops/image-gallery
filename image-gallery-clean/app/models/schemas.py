from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ImageMetadata(BaseModel):
    """Model for image metadata"""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    tags: List[str] = Field(default_factory=list)


class ImageResponse(BaseModel):
    """Model for image response"""
    id: str
    title: str
    description: Optional[str] = None
    tags: List[str] = []
    url: str
    thumbnail_url: Optional[str] = None
    created_at: str
    size: int
    content_type: str


class ImageUpdate(BaseModel):
    """Model for updating image metadata"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    tags: Optional[List[str]] = None


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    timestamp: str
    s3_connection: bool
