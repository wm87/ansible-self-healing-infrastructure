#!/usr/bin/env python3
from flask import Flask, request, jsonify
import subprocess
import os
import json
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

SELFHEAL_SCRIPT = "/bigdata/tmp/ansible-self-healing-infrastructure/setup/selfhealing_szenario.sh"

@app.route("/selfheal-webhook", methods=["POST"])
def selfheal_webhook():
    try:
        payload = request.get_json(force=True)
        logging.info("Incoming webhook payload:\n%s", json.dumps(payload, indent=2, ensure_ascii=False))

        # Alle fehlerhaften Services aus dem Alert sammeln
        alerts = payload.get("alerts", [])
        if not alerts:
            return jsonify({"message": "No alerts to process."}), 200

        results = []
        for alert in alerts:
            labels = alert.get("labels", {})
            service = labels.get("service") or labels.get("job") or labels.get("alertname")
            scenario = labels.get("scenario", "restart")
            severity = labels.get("severity", "warning")

            logging.info("Triggering selfheal for service: %s, scenario: %s, severity: %s", service, scenario, severity)

            # Environment für das Selfheal-Skript
            env = os.environ.copy()
            env.update({
                "SERVICE": service,
                "SCENARIO": scenario,
                "SEVERITY": severity,
                "APPROVAL": "true",
                "SOURCE": "alertmanager"
            })

            # Skript ausführen
            result = subprocess.run(
                [SELFHEAL_SCRIPT],
                env=env,
                capture_output=True,
                text=True
            )

            results.append({
                "service": service,
                "scenario": scenario,
                "severity": severity,
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            })

        return jsonify({"results": results})

    except Exception as e:
        logging.exception("Webhook error")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
