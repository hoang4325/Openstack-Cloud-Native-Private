#!/usr/bin/env bash
set -euo pipefail
NS=troubleshooting-lab
case "${1:-snapshot}" in
  snapshot)
    kubectl config current-context
    kubectl get pods,deploy,svc,ingress,networkpolicy -n "$NS" -o wide || true
    kubectl get events -n "$NS" --sort-by=.lastTimestamp | tail -40 || true
    ;;
  help)
    echo 'Usage: ./triage.sh snapshot  # read-only; no fix operations'
    ;;
  *) echo 'Only snapshot is supported' >&2; exit 2;;
esac
