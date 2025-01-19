from datetime import datetime

def log_timing(operation: str, start_time: datetime) -> float:
    """Logs the time taken for an operation."""
    duration = (datetime.now() - start_time).total_seconds()
    print(f"{operation}: {duration:.2f} seconds")
    return duration
