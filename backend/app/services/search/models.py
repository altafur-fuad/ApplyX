from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class SearchOptions(BaseModel):
    max_results: int = 5
    search_depth: str = "basic" # "basic" or "advanced"
    include_domains: Optional[List[str]] = None
    exclude_domains: Optional[List[str]] = None
    include_raw_content: bool = False

class SearchRequest(BaseModel):
    query: str
    options: SearchOptions = Field(default_factory=SearchOptions)

class SearchResult(BaseModel):
    title: str
    url: str
    snippet: Optional[str] = None
    raw_content: Optional[str] = None
    source_name: str
    published_at: Optional[datetime] = None
    retrieved_at: datetime
    score: Optional[float] = None
    provider_metadata: Optional[Dict[str, Any]] = None

class SearchUsage(BaseModel):
    credits_used: Optional[float] = None

class SearchResponse(BaseModel):
    results: List[SearchResult]
    usage: Optional[SearchUsage] = None

class SearchCapabilities(BaseModel):
    web_search: bool = True
    content_snippets: bool = True
    raw_content: bool = False
    domain_filter: bool = False
    advanced_search: bool = False
