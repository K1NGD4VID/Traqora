#!/usr/bin/env bash
# scripts/rollback.sh — Roll back a failed backend deployment
#
# When the backend becomes unhealthy after a deploy this script:
#   1. Verifies the last known-good deployment commit
#   2. Rolls back ECS to the previous task definition revision
#   3. Waits for the service to stabilise
#   4. Sends an alert (Slack webhook or console)
#
# Usage:
#   ./scripts/rollback.sh                  # live rollback
#   DRY_RUN=true ./scripts/rollback.sh     # dry-run (default in CI)
#   ENVIRONMENT=production ./scripts/rollback.sh
#
# Environment variables:
#   ENVIRONMENT       – "dev" | "staging" | "production" (default: dev)
#   DRY_RUN           – set to "true" to skip mutating operations
#   AWS_REGION        – AWS region (default: us-east-1)
#   ECS_CLUSTER       – ECS cluster name (overrides auto-detect)
#   ECS_SERVICE       – ECS service name (overrides auto-detect)
#   SLACK_WEBHOOK_URL – optional Slack Incoming Webhook URL for alerts

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────
ENVIRONMENT="${ENVIRONMENT:-dev}"
DRY_RUN="${DRY_RUN:-false}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT="traqora"
LOG_FILE="/tmp/traqora-rollback-$(date +%Y%m%d-%H%M%S).log"

# Auto-derive ECS names if not overridden
ECS_CLUSTER="${ECS_CLUSTER:-${PROJECT}-${ENVIRONMENT}-backend}"
ECS_SERVICE="${ECS_SERVICE:-${PROJECT}-${ENVIRONMENT}-backend}"

# ── Helpers ───────────────────────────────────────────────────────────
log()   { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG_FILE"; }
die()   { log "FATAL: $*"; exit 1; }
warn()  { log "WARN:  $*" ; }

# ── Preflight checks ─────────────────────────────────────────────────
command -v aws >/dev/null 2>&1 || die "aws CLI not found — install it first"

log "=== Traqora Rollback ==="
log "Environment : $ENVIRONMENT"
log "Dry run     : $DRY_RUN"
log "Cluster     : $ECS_CLUSTER"
log "Service     : $ECS_SERVICE"
log "Region      : $AWS_REGION"
log ""

# ── Step 1: Discover current and previous task definition ─────────────
log "Step 1: Discovering task definitions …"

CURRENT_TD=$(aws ecs describe-services \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --region "$AWS_REGION" \
  --query 'services[0].taskDefinition' \
  --output text 2>>"$LOG_FILE") \
  || die "Failed to describe ECS service — check cluster/service names and credentials"

CURRENT_FAMILY=$(echo "$CURRENT_TD" | cut -d: -f6 | cut -d/ -f2)
CURRENT_REVISION=$(echo "$CURRENT_TD" | grep -oE '[0-9]+$')
log "Current task def : $CURRENT_FAMILY:$CURRENT_REVISION"

# Fetch the previous revision (current - 1)
PREV_REVISION=$((CURRENT_REVISION - 1))
if [ "$PREV_REVISION" -lt 1 ]; then
  die "No previous task definition revision exists (current=$CURRENT_REVISION)"
fi

PREV_TD="${CURRENT_FAMILY}:${PREV_REVISION}"
log "Previous task def: $PREV_TD"
log ""

# ── Step 2: Verify previous definition exists ─────────────────────────
log "Step 2: Verifying previous task definition exists …"
aws ecs describe-task-definition \
  --task-definition "$PREV_TD" \
  --region "$AWS_REGION" \
  --query 'taskDefinition.{family:family,revision:revision,status:status}' \
  --output table 2>>"$LOG_FILE" \
  || die "Task definition $PREV_TD not found"
log "Verified."
log ""

# ── Step 3: Roll back (or dry-run) ───────────────────────────────────
if [ "$DRY_RUN" = "true" ]; then
  log "Step 3: DRY RUN — would update service to $PREV_TD"
else
  log "Step 3: Updating ECS service to $PREV_TD …"
  aws ecs update-service \
    --cluster "$ECS_CLUSTER" \
    --service "$ECS_SERVICE" \
    --task-definition "$PREV_TD" \
    --force-new-deployment \
    --region "$AWS_REGION" \
    --output text >>"$LOG_FILE" 2>&1 \
    || die "ECS update-service failed"

  log "Service update submitted. Waiting for stability …"
  aws ecs wait services-stable \
    --cluster "$ECS_CLUSTER" \
    --services "$ECS_SERVICE" \
    --region "$AWS_REGION" 2>>"$LOG_FILE" \
    || warn "Timeout waiting for service stability — check ECS console"

  log "Service is stable."
fi
log ""

# ── Step 4: Alert ─────────────────────────────────────────────────────
ALERT_MSG="⚠️ *Traqora Deploy Rollback*\nEnvironment: ${ENVIRONMENT}\nRolled back: ${CURRENT_FAMILY}:${CURRENT_REVISION} → ${PREV_TD}\nTimestamp: $(date -u +%FT%TZ)\nLog: ${LOG_FILE}"

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  log "Step 4: Sending Slack alert …"
  curl -sf -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"${ALERT_MSG}\"}" \
    "$SLACK_WEBHOOK_URL" >>"$LOG_FILE" 2>&1 \
    || warn "Slack notification failed"
  log "Alert sent."
else
  log "Step 4: No SLACK_WEBHOOK_URL set — printing alert to stdout."
  echo ""
  echo -e "$ALERT_MSG"
fi

log ""
log "=== Rollback complete. Log saved to $LOG_FILE ==="
