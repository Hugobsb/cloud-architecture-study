#!/usr/bin/env bash

set -e

NAMESPACE="monitoring"

echo "Fetching Grafana admin password..."

GRAFANA_PASSWORD=$(kubectl get secret kube-prometheus-stack-grafana \
  -n $NAMESPACE \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana password copied to clipboard"

# clipboard (linux/mac compatibility)
if command -v pbcopy >/dev/null 2>&1; then
  echo -n "$GRAFANA_PASSWORD" | pbcopy
elif command -v xclip >/dev/null 2>&1; then
  echo -n "$GRAFANA_PASSWORD" | xclip -selection clipboard
elif command -v wl-copy >/dev/null 2>&1; then
  echo -n "$GRAFANA_PASSWORD" | wl-copy
else
  echo "No clipboard utility found. Please copy the password manually: $GRAFANA_PASSWORD"
fi

echo "Starting port-forwards..."

kubectl port-forward svc/kube-prometheus-stack-grafana \
  -n $NAMESPACE \
  3000:80 >/dev/null 2>&1 &

GRAFANA_PID=$!

kubectl port-forward svc/kube-prometheus-stack-prometheus \
  -n $NAMESPACE \
  9090:9090 >/dev/null 2>&1 &

PROM_PID=$!

sleep 3

echo "Opening dashboards..."

# open browser cross-platform
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open http://localhost:3000
  xdg-open http://localhost:9090
elif command -v open >/dev/null 2>&1; then
  open http://localhost:3000
  open http://localhost:9090
fi

echo ""
echo "Grafana: http://localhost:3000"
echo "User: admin"
echo "Password: copied to clipboard"
echo ""
echo "Prometheus: http://localhost:9090"
echo ""
echo "Press Ctrl+C to stop port-forwarding"

wait
