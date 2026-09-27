import argparse
import asyncio
import sys
import logging
import os

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.services.search.diagnostics import get_safe_search_diagnostics
from app.services.search.factory import get_search_provider
from app.services.search.models import SearchRequest, SearchOptions
from app.services.search.errors import SearchError

async def run_smoke_test(real: bool = False):
    print("========================================")
    print("    ApplyX Search Provider Smoke Test")
    print("========================================")
    
    diagnostics = get_safe_search_diagnostics()
    
    print("\n[Diagnostics]")
    for k, v in diagnostics.items():
        print(f"  {k}: {v}")
        
    if not diagnostics.get("configured"):
        print("\n[FAIL] Error: No search provider configured.")
        sys.exit(1)
        
    if diagnostics.get("state") == "CONFIG_INVALID":
        print(f"\n[FAIL] Error: Provider configuration is invalid: {diagnostics.get('error')}")
        sys.exit(1)
        
    print("\n[OK] Local configuration is valid.")
    
    if not real:
        print("\n[Dry Run Completed]")
        print("Run with --real to perform an actual network request to the provider.")
        sys.exit(0)
        
    print("\n[Real Test]")
    print("Initializing search provider...")
    
    try:
        provider = get_search_provider(disable_fallback=True)
    except Exception as e:
        print(f"[FAIL] Initialization Failed: {e.__class__.__name__} - {str(e)}")
        sys.exit(1)
        
    print(f"Provider: {provider.provider_name()}")
    print("Sending smoke test request...")
    
    request = SearchRequest(
        query="site:example.com ApplyX test",
        options=SearchOptions(max_results=1)
    )
    
    try:
        response = await provider.search(request)
        print("\n[OK] Smoke Test Successful!")
        print(f"Results Count: {len(response.results)}")
        if response.results:
            r = response.results[0]
            print(f"  First Result: {r.title} ({r.url})")
            
        if response.usage:
            print("\n[Usage Metadata]")
            print(f"  Credits Used: {response.usage.credits_used}")
        else:
            print("\n[Usage Metadata] Not provided by adapter.")
            
    except SearchError as e:
        print(f"\n[FAIL] Remote Request Failed")
        print(f"  Normalized Error Class: {e.__class__.__name__}")
        print(f"  Details: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"\n[FAIL] Unexpected Remote Request Failure")
        print(f"  Error Class: {e.__class__.__name__}")
        print(f"  Details: {str(e)}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="ApplyX Search Provider Smoke Test")
    parser.add_argument("--real", action="store_true", help="Perform a real network request")
    args = parser.parse_args()
    
    asyncio.run(run_smoke_test(args.real))

if __name__ == "__main__":
    main()
