FROM python:3.13-alpine

RUN apk add --no-cache \
    gcc \
    musl-dev \
    linux-headers \
    && pip install --no-cache-dir \
    pytz \
    requests \
    geopy \
    nomadnet \
    && apk del gcc musl-dev linux-headers

WORKDIR /app

COPY nomadnetwork/ ./nomadnetwork/

RUN chmod +x ./nomadnetwork/storage/pages/nomadnet.mu \
    && chmod +x ./nomadnetwork/storage/pages/meshchat.mu \
    && chmod +x ./nomadnetwork/storage/pages/fullchat.mu \
    && chmod +x ./nomadnetwork/storage/pages/last100.mu

RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

COPY .reticulum/ /home/appuser/.reticulum/

RUN chown -R appuser:appuser /app /home/appuser/.reticulum

USER appuser

EXPOSE 4242

CMD ["nomadnet", "-d", "--config", "./nomadnetwork"]

