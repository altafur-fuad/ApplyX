# Connectors package
from .base import OpportunityConnector
from .remotive import RemotiveConnector
from .arbeitnow import ArbeitnowConnector

__all__ = ["OpportunityConnector", "RemotiveConnector", "ArbeitnowConnector"]

def get_all_connectors() -> list[OpportunityConnector]:
    return [RemotiveConnector(), ArbeitnowConnector()]

def get_connector(source_name: str) -> OpportunityConnector | None:
    for c in get_all_connectors():
        if c.source_identity() == source_name:
            return c
    return None
