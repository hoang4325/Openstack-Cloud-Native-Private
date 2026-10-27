#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
NS=troubleshooting-lab
cmd="${1:-help}"
case "$cmd" in
  init)
    echo 'Kube context:'; kubectl config current-context
    kubectl apply -f "$ROOT/base.yaml" >/dev/null
    echo "Baseline created in $NS"
    ;;
  list)
    for p in "$ROOT"/manifests/*.yaml; do basename "$p" .yaml; done
    ;;
  start)
    id="${2:-}"
    [[ "$id" =~ ^[0-9]{1,2}$ ]] || { echo 'Use case ID 01..60'; exit 2; }
    n=$((10#$id))
    printf -v id '%02d' "$n"
    f="$ROOT/manifests/$id.yaml"
    [[ -f "$f" ]] || { echo 'No inject for this ticket. It may be query/runbook.'; exit 2; }
    case "$id" in
      31|32|33|38|39)
        [[ "${3:-}" == '--allow-monitoring' ]] || { echo 'Monitoring CRD case: requires --allow-monitoring and operator validation'; exit 2; }
        ;;
    esac
    kubectl get namespace "$NS" >/dev/null || { echo 'Run ./operator.sh init first'; exit 2; }
    mkdir -p "$ROOT/.operator-logs"
    if kubectl apply -f "$f" >"$ROOT/.operator-logs/$id.txt" 2>&1; then
      echo "Activated ticket INC-$id. Student may now investigate."
    else
      echo "Injection failed; operator only: $ROOT/.operator-logs/$id.txt" >&2; exit 1
    fi
    ;;
  stop)
    id="${2:-}"
    [[ "$id" =~ ^[0-9]{1,2}$ ]] || exit 2
    printf -v id '%02d' "$((10#$id))"
    f="$ROOT/manifests/$id.yaml"
    [[ -f "$f" ]] || exit 2
    kubectl delete -f "$f" --ignore-not-found=true --wait=false
    echo 'Declared resources deleted; any extra objects created by student require separate review.'
    ;;
  reset)
    echo 'This will DELETE namespace troubleshooting-lab including EVERY remaining lab resource.'
    read -r -p "Enter DELETE-$NS to continue: " confirm
    [[ "$confirm" == "DELETE-$NS" ]] || exit 1
    kubectl delete ns "$NS" --ignore-not-found
    ;;
  *)
    echo 'Usage: ./operator.sh init|list|start NN [--allow-monitoring]|stop NN|reset'
    exit 2
    ;;
esac
