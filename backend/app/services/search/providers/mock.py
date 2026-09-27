from datetime import datetime, timezone
from app.services.search.base import SearchProvider
from app.services.search.models import SearchRequest, SearchResponse, SearchResult, SearchCapabilities

class MockSearchProvider(SearchProvider):
    def provider_name(self) -> str:
        return "mock"

    def capabilities(self) -> SearchCapabilities:
        return SearchCapabilities(
            web_search=True,
            content_snippets=True,
            raw_content=True,
            domain_filter=True,
            advanced_search=False
        )

    async def search(self, request: SearchRequest) -> SearchResponse:
        now = datetime.now(timezone.utc)
        return SearchResponse(
            results=[
                # 1. Complete opportunity
                SearchResult(
                    title="Software Engineering Intern",
                    url="https://jobs.example.com/swe-intern-2027",
                    snippet="Example Corp is hiring a Software Engineering Intern. Location: Remote. Requirements: Python, FastAPI. Deadline: 2026-12-01.",
                    source_name="example_board",
                    retrieved_at=now
                ),
                # 2. Distinct opportunity (different org)
                SearchResult(
                    title="Data Science Intern",
                    url="https://careers.dataco.example/intern",
                    snippet="DataCo is looking for a Data Science intern in New York (On-site). Requirements: SQL, Python.",
                    source_name="dataco_careers",
                    retrieved_at=now
                ),
                # 3. Duplicate of 1 (same URL)
                SearchResult(
                    title="Software Engineering Intern - Example Corp",
                    url="https://jobs.example.com/swe-intern-2027",
                    snippet="We are hiring a SWE Intern. Remote role.",
                    source_name="aggregator_site",
                    retrieved_at=now
                ),
                # 4. Incomplete opportunity
                SearchResult(
                    title="Frontend Developer",
                    url="https://startup.example.com/jobs/1",
                    snippet="Looking for a frontend developer. React skills preferred.",
                    source_name="startup_site",
                    retrieved_at=now
                ),
                # 5. Duplicate of 2 (same title and org but different URL, still considered duplicate if exact match)
                SearchResult(
                    title="Data Science Intern",
                    url="https://aggregator.example/dataco-ds-intern",
                    snippet="DataCo is looking for a Data Science intern in New York.",
                    source_name="aggregator_site",
                    retrieved_at=now
                )
            ]
        )
