#!/usr/bin/env python3
"""
Pre-commit hook to check if buildvariant tasks contain required language tags.
"""

import logging
import sys
import yaml
from pathlib import Path
from typing import List, Dict, Any

logging.basicConfig()
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG)


CURRENT_DIR = Path(__file__).parent.resolve()
CONFIG_YML = CURRENT_DIR / "config.yml"
VALID_LANGUAGES = {"python", "golang", "javascript", "csharp", "self"}


def load_yaml_file(file_path: str) -> Dict[Any, Any]:
    """Load and parse a YAML file."""
    with open(file_path, "r", encoding="utf-8") as file:
        return yaml.safe_load(file) or {}


def check_buildvariants(data: Dict[Any, Any]) -> List[str]:
    """
    Check if buildvariant tasks contain at least one required language tag
    as well as the language within the buildvariant name.

    Example Buildvariant structure in YAML:
    buildvariants:
    - name: test-semantic-kernel-python-rhel
        display_name: Semantic-Kernel RHEL Python
        tags: [python]
        expansions:
        DIR: semantic-kernel-python
        run_on:
        - rhel87-small
        tasks:
        - name: test-semantic-kernel-python-local
        - name: test-semantic-kernel-python-remote
          batchtime: 10080  # 1 week

    Args:
        data: Parsed YAML data

    Returns:
        List of error messages for tasks missing required tags
    """
    errors = []

    buildvariants = data.get("buildvariants", [])
    if not isinstance(buildvariants, list):
        return ["'buildvariants' should be a list"]

    for i, buildvariant in enumerate(buildvariants):
        if not isinstance(buildvariant, dict):
            errors.append(f"buildvariants[{i}] should contain sub-fields")
            continue

        buildvariant_name = buildvariant.get("name", "")
        if not buildvariant_name:
            errors.append(f"buildvariants[{i}] is missing 'name'")
            continue
        else:
            if all([f"-{lang}-" not in buildvariant_name for lang in VALID_LANGUAGES]):
                errors.append(
                    f"buildvariant '{buildvariant_name}' should contain one"
                    f" '-[{', '.join(VALID_LANGUAGES)}]-' in its name"
                    f"got: {buildvariant_name}",
                )

        buildvariant_display_name = buildvariant.get("display_name", buildvariant_name)

        tags = buildvariant.get("tags", [])

        if not isinstance(tags, list) or len(tags) != 1:
            errors.append(
                f"'tags' in buildvariant '{buildvariant_display_name}' should be a list of size 1"
            )
            continue

        if tags[0] not in VALID_LANGUAGES:
            errors.append(
                f"buildvariant '{buildvariant_display_name}' has invalid tag '{tags[0]}'. "
                f"Valid tags are: {', '.join(VALID_LANGUAGES)}"
            )
    return errors


def main():
    """Main function for the pre-commit hook."""
    total_errors = 0

    data = load_yaml_file(CONFIG_YML)
    if not data:
        raise FileNotFoundError(f"Failed to load or parse {CONFIG_YML}")

    errors = check_buildvariants(data)

    if errors:
        logger.error("❌ Errors found in %s:", CONFIG_YML)
        for error in errors:
            logger.error("  - %s", error)
        total_errors += len(errors)

    if total_errors > 0:
        logger.error("❌ Total errors found: %s", total_errors)
        return 1
    else:
        logger.info("✅ %s passed AI/ML testing pipeline validation", CONFIG_YML)


if __name__ == "__main__":
    sys.exit(main())
