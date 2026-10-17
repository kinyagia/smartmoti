"""Small standard-library helpers for Jac business workflows."""
from datetime import date, datetime, timezone, timedelta
from decimal import Decimal, InvalidOperation
import math
import uuid
from typing import Any
from dataclasses import asdict

def dataclass_payload(value: Any) -> dict[str, Any]:
    return asdict(value)

def identifier() -> str:
    return str(uuid.uuid4())

def now() -> str:
    return datetime.now(timezone.utc).isoformat()

def local_today() -> date:
    return datetime.now(timezone(timedelta(hours=3))).date()

def rounded(value: float, digits: int) -> float:
    return round(value, digits)

def text(value: Any, name: str, limit: int=500, required: bool=True) -> str:
    result = str(value or '').strip()
    if required and (not result):
        raise ValueError(f'{name} is required')
    if len(result) > limit:
        raise ValueError(f'{name} must be at most {limit} characters')
    return result

def number(value: Any, name: str, minimum: float=0, maximum: float=10000000) -> float:
    try:
        result = float(Decimal(str(value)))
    except (InvalidOperation, ValueError, TypeError):
        raise ValueError(f'{name} must be a number') from None
    if not math.isfinite(result) or not minimum <= result <= maximum:
        raise ValueError(f'{name} must be between {minimum} and {maximum}')
    return result
