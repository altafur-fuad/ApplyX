import argparse
import asyncio
import sys
import logging
from typing import Optional

# Setup minimal logging without exposing secrets
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Ensure paths are correct when running from scripts/
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.services.llm.diagnostics import get_safe_diagnostics
from app.services.llm.factory import get_llm_provider
from app.services.llm.models import LLMRequest, LLMMessage
from app.services.llm.errors import LLMError

async def run_smoke_test(real: bool = False):
    print("========================================")
    print("    ApplyX LLM Provider Smoke Test")
    print("========================================")
    
    # 1. Configuration Validation and Safe Diagnostics
    diagnostics = get_safe_diagnostics()
    
    print("\n[Diagnostics]")
    for k, v in diagnostics.items():
        print(f"  {k}: {v}")
        
    if not diagnostics.get("configured"):
        print("\n[FAIL] Error: No LLM provider configured.")
        sys.exit(1)
        
    if diagnostics.get("state") == "CONFIG_INVALID":
        print(f"\n[FAIL] Error: Provider configuration is invalid: {diagnostics.get('error')}")
        sys.exit(1)
    print("\n[OK] Local configuration is valid.")
    
    if not real:
        print("\n[Dry Run Completed]")
        print("Run with --real to perform an actual network request to the provider.")
        sys.exit(0)
        
    # 2. Real Smoke Test
    print("\n[Real Test]")
    print("Initializing provider...")
    
    try:
        # We explicitly disable fallback for the smoke test to test the actual configured primary provider
        provider = get_llm_provider(disable_fallback=True)
    except Exception as e:
        print(f"[FAIL] Initialization Failed: {e.__class__.__name__} - {str(e)}")
        sys.exit(1)
        
    print(f"Provider: {provider.provider_name()}")
    print(f"Model: {provider.model_name()}")
    print("Sending smoke test request...")
    
    request = LLMRequest(
        messages=[LLMMessage(role="user", content="Reply with exactly: ApplyX smoke test successful")]
    )
    
    try:
        response = await provider.complete(request)
        print("\n[OK] Smoke Test Successful!")
        print(f"Response: '{response.content.strip()}'")
        
        if response.usage:
            print("\n[Usage Metadata]")
            print(f"  Input Tokens: {response.usage.input_tokens}")
            print(f"  Output Tokens: {response.usage.output_tokens}")
            print(f"  Total Tokens: {response.usage.total_tokens}")
        else:
            print("\n[Usage Metadata] Not provided by adapter.")
            
    except LLMError as e:
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
    parser = argparse.ArgumentParser(description="ApplyX LLM Provider Smoke Test")
    parser.add_argument("--real", action="store_true", help="Perform a real network request")
    args = parser.parse_args()
    
    asyncio.run(run_smoke_test(args.real))

if __name__ == "__main__":
    main()
