import json
import pytest
from unittest.mock import patch, MagicMock
from app.agents.document import DocumentAgent
from app.agents.models import DocumentGenerationResult, GeneratedSection
from app.services.llm.models import LLMResponse

@pytest.mark.asyncio
@patch("app.agents.document.save_generated_document")
@patch("app.services.llm.providers.mock.MockLLMProvider.complete")
async def test_document_generation_success(mock_complete, mock_save):
    # Setup mock LLM response
    result_mock = DocumentGenerationResult(
        kind="cover_letter",
        title="Cover Letter - Software Engineer",
        content="Generated content.",
        source_facts_used=["skill: python"],
        generated_sections=[
            GeneratedSection(title="Introduction", content="I am writing to apply...", uncertainty_warnings=None)
        ]
    )
    mock_complete.return_value = LLMResponse(
        content=result_mock.model_dump_json(),
        parsed=result_mock,
        model="mock"
    )

    mock_save.return_value = {"id": "mock-doc-id", "version": 1}

    agent = DocumentAgent()
    profile = {"skills": ["python"]}
    opportunity = {"title": "Software Engineer"}
    fit = {"fit_reasons": ["Has python"]}
    
    task_input = {
        "document_kind": "cover_letter",
        "instruction": "Draft a strong letter",
        "application_id": "app-123"
    }

    result = await agent.execute(profile, opportunity, fit, user_id="user-123", task_input=task_input)

    assert "document_result" in result
    assert result["document_result"]["title"] == "Cover Letter - Software Engineer"
    assert result["saved_document"]["id"] == "mock-doc-id"
    
    mock_save.assert_called_once()
    kwargs = mock_save.call_args.kwargs
    assert kwargs["user_id"] == "user-123"
    assert kwargs["application_id"] == "app-123"
    assert "## Introduction" in kwargs["content"]

@pytest.mark.asyncio
@patch("app.services.llm.providers.mock.MockLLMProvider.complete")
async def test_document_generation_malformed(mock_complete):
    # Setup mock to return garbage JSON
    mock_complete.return_value = LLMResponse(
        content="This is not JSON",
        parsed=None,
        model="mock"
    )

    agent = DocumentAgent()
    
    with pytest.raises(ValueError) as excinfo:
        await agent.execute({}, {}, {}, user_id="u1", task_input={})
    
    assert "Malformed document LLM output" in str(excinfo.value)
