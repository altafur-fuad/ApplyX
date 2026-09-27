from pydantic import BaseModel, Field
from typing import Any, Dict, List, Optional, Type

class LLMMessage(BaseModel):
    role: str
    content: str

class LLMTool(BaseModel):
    name: str
    description: str
    input_schema: Dict[str, Any]

class LLMToolCall(BaseModel):
    id: str
    name: str
    arguments: str # JSON string of arguments

class LLMCapabilities(BaseModel):
    structured_output: bool = False
    tool_calling: bool = False
    streaming: bool = False
    vision: bool = False
    web_search: bool = False
    json_mode: bool = False

class LLMRequest(BaseModel):
    messages: List[LLMMessage]
    model: str = "mock"
    temperature: float = 0.0
    max_tokens: int = 1024
    response_format: Optional[str] = None # "json"
    response_model: Optional[Type[BaseModel]] = None
    tools: Optional[List[LLMTool]] = None
    tool_choice: Optional[str] = None

class LLMUsage(BaseModel):
    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0
    cached_tokens: Optional[int] = None

class LLMResponse(BaseModel):
    content: str
    model: str
    usage: LLMUsage = Field(default_factory=LLMUsage)
    finish_reason: Optional[str] = None
    parsed: Optional[Any] = None
    tool_calls: Optional[List[LLMToolCall]] = None
