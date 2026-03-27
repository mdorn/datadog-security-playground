FROM python:3.14-slim

ARG port

WORKDIR /app

ENV PYTHONUNBUFFERED=1

ENV UV_NO_DEV=1
ENV UV_LOCKED=1
ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_EDITABLE=1
ENV UV_PROJECT_ENVIRONMENT=/usr/local

RUN pip install uv==0.11.1

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-workspace

COPY src/ ./src/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync


EXPOSE 8000
ENTRYPOINT ["ddtrace-run"]
CMD [ "uvicorn", "appsec_test_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
