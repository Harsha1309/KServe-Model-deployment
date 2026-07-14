
# Small, sandbox-friendly serving image.
# EKS node group is t3.medium (x86_64) — building on Apple Silicon/ARM defaults to
# an arm64 image unless you pass --platform, which will fail at pod runtime with
# "exec format error". Always build with:
# docker build --platform linux/amd64 -t <acct>.dkr.ecr.<region>.amazonaws.com/iris-classifier:v1 .
# Push :  docker push  <acct>.dkr.ecr.<region>.amazonaws.com/iris-classifier:v1
 
FROM python:3.11-slim
 
WORKDIR /app
 
# kserve pulls in ray[serve] -> psutil, which has no prebuilt wheel for every
# arch/python combo and falls back to compiling from source. Needs a compiler.
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*
 
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
 
COPY train.py predictor.py .
 
# Train at build time so the image is self-contained (no S3/PVC needed).
# For a real model, replace this with `COPY model.joblib /mnt/models/model.joblib`
# and drop train.py from the image entirely.
RUN mkdir -p /mnt/models && \
    python train.py && \
    mv model.joblib /mnt/models/model.joblib
 
ENV MODEL_PATH=/mnt/models/model.joblib
EXPOSE 8080
 
ENTRYPOINT ["python", "predictor.py", "--model_name", "iris-classifier", "--http_port", "8080"]