from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = FastAPI(title="OpsPilot Demo Service", version="0.1.0")
REQUESTS = Counter("opspilot_http_requests_total", "HTTP requests", ["path"])


@app.get("/")
def root() -> dict[str, str]:
    REQUESTS.labels(path="/").inc()
    return {"service": "opspilot-demo", "message": "deployment healthy"}


@app.get("/health")
def health() -> dict[str, str]:
    REQUESTS.labels(path="/health").inc()
    return {"status": "healthy"}


@app.get("/ready")
def ready() -> dict[str, str]:
    REQUESTS.labels(path="/ready").inc()
    return {"status": "ready"}


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
