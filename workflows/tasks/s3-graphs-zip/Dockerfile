FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir boto3

COPY main.py /app/main.py

ENTRYPOINT ["python", "/app/main.py"]
CMD ["--help"]
