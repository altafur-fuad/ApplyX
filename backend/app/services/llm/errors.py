class LLMError(Exception):
    pass

class LLMConfigurationError(LLMError):
    pass

class LLMAuthenticationError(LLMError):
    pass

class LLMQuotaError(LLMError):
    pass

class LLMRateLimitError(LLMError):
    pass

class LLMTimeoutError(LLMError):
    pass

class LLMUnavailableError(LLMError):
    pass

class LLMInvalidResponseError(LLMError):
    pass

class LLMUnsupportedCapabilityError(LLMError):
    pass
