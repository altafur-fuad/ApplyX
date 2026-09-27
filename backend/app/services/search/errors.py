class SearchError(Exception):
    """Base class for search provider errors."""
    pass

class SearchConfigurationError(SearchError):
    pass

class SearchAuthenticationError(SearchError):
    pass

class SearchQuotaError(SearchError):
    pass

class SearchRateLimitError(SearchError):
    pass

class SearchTimeoutError(SearchError):
    pass

class SearchUnavailableError(SearchError):
    pass

class SearchInvalidResponseError(SearchError):
    pass

class SearchUnsupportedError(SearchError):
    pass
