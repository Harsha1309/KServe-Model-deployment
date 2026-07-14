"""
Custom KServe predictor.

Implements the kserve.Model interface so it works with:
  - the standard V1 REST payload: {"instances": [[...], [...]]}
  - readiness/liveness probes KServe wires up automatically

Run locally:
    python predictor.py --model_name iris-classifier

The InferenceService's storage-less "custom container" pattern is used
here: the model file is baked into the image at build time (see
Dockerfile), so there's no storage-initializer / S3 / PVC needed for
this demo. Swap in `kserve.Storage` if you want to pull weights from
S3/GCS/PVC at startup instead.
"""
import argparse
import logging
import os
from typing import Dict

import joblib
import numpy as np
from kserve import Model, ModelServer, model_server

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_PATH = os.environ.get("MODEL_PATH", "/mnt/models/model.joblib")


class SklearnModel(Model):
    def __init__(self, name: str):
        super().__init__(name)
        self.name = name
        self.ready = False
        self.model = None
        self.load()

    def load(self):
        logger.info(f"loading model from {MODEL_PATH}")
        self.model = joblib.load(MODEL_PATH)
        self.ready = True

    def predict(self, payload: Dict, headers: Dict[str, str] = None) -> Dict:
        instances = payload["instances"]
        inputs = np.array(instances)

        predictions = self.model.predict(inputs).tolist()
        response = {"predictions": predictions}

        if hasattr(self.model, "predict_proba"):
            response["probabilities"] = self.model.predict_proba(inputs).tolist()

        return response


if __name__ == "__main__":
    # model_server.parser already defines --model_name (and --http_port, etc.)
    # as standard KServe CLI args — don't redefine it, just use it.
    parser = argparse.ArgumentParser(parents=[model_server.parser])
    args, _ = parser.parse_known_args()

    model_name = args.model_name or os.environ.get("MODEL_NAME", "iris-classifier")
    model = SklearnModel(model_name)
    ModelServer().start([model])