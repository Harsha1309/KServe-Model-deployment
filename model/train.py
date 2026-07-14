"""
Trains a small sklearn classifier and saves it as model.joblib.
Swap this out for your real training pipeline — the only contract
predictor.py cares about is: a joblib-loadable object with .predict()
(and .predict_proba() if you want probabilities).
"""
import joblib
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

acc = clf.score(X_test, y_test)
print(f"test accuracy: {acc:.4f}")

joblib.dump(clf, "model.joblib")
print("saved model.joblib")
