# Container for Hugging Face Spaces (Docker SDK) or any Docker host.
# Storage inside the container is temporary unless a volume is mounted at /home/user/app/data.
FROM python:3.12-slim

RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    SMARTMOTI_HOST=0.0.0.0 \
    SMARTMOTI_HTTPS=1 \
    PORT=7860
WORKDIR /home/user/app

RUN pip install --no-cache-dir --user --no-deps jaclang==0.16.7 \
    && pip install --no-cache-dir --user cryptography==50.0.2

COPY --chown=user . .

EXPOSE 7860
CMD ["python", "server.py"]
