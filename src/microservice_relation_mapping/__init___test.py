"""Tests for __init__.py, built against contract v0.

Coverage:
  - Happy path and load-bearing behavior: package version is importable without
    side effects.

Run with:
    uv run pytest
"""

from microservice_relation_mapping import __version__


def test_package_version_is_exported() -> None:
    """Load-bearing: packaging and early tooling inspect package identity."""
    assert __version__ == "0.1.0"
