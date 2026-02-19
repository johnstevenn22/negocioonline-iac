#!/bin/bash

set -e

REGION="us-east-2"
ACCOUNT_ID="088862083573"

echo " Verificando e importando recursos existentes..."

import_if_not_exists() {
    local resource_address=$1
    local resource_id=$2
    
    if ! terraform state show "$resource_address" &>/dev/null; then
        echo " Importando: $resource_address"
        terraform import "$resource_address" "$resource_id" || echo "  No se pudo importar $resource_address (puede que no exista)"
    else
        echo " Ya existe en state: $resource_address"
    fi
}

import_if_not_exists "aws_cloudwatch_log_group.api_gateway_logs" "/aws/apigateway/pedidos-online"
import_if_not_exists "aws_cloudwatch_log_group.backend" "/ecs/pedidos-online-backend"
import_if_not_exists "aws_cloudwatch_log_group.frontend" "/ecs/pedidos-online-frontend"
import_if_not_exists "aws_cloudwatch_log_group.waf_logs" "aws-waf-logs-pedidos-online"
import_if_not_exists "aws_cloudwatch_log_group.vpc_flow_logs" "/aws/vpc/pedidos-online-prod"

import_if_not_exists "aws_iam_role.backup_role" "pedidos-online-backup-role"
import_if_not_exists "aws_iam_role.ecs_execution_role" "pedidos-online-ecs-execution-role"
import_if_not_exists "aws_iam_role.ecs_task_role" "pedidos-online-ecs-task-role"
import_if_not_exists "aws_iam_role.rds_monitoring_role" "pedidos-online-rds-monitoring-role"
import_if_not_exists "aws_iam_role.lambda_role" "pedidos-online-lambda-role"
import_if_not_exists "aws_iam_role.vpc_flow_logs_role" "pedidos-online-vpc-flow-logs-role"

import_if_not_exists "aws_ecr_repository.backend" "pedidos-online-backend"
import_if_not_exists "aws_ecr_repository.frontend" "pedidos-online-frontend"

import_if_not_exists "aws_db_subnet_group.main" "pedidos-online-db-subnet-group"
import_if_not_exists "aws_db_parameter_group.postgres" "pedidos-online-postgres-params"

import_if_not_exists "aws_elasticache_subnet_group.main" "pedidos-online-redis-subnet-group"

import_if_not_exists "aws_iam_group.admins" "pedidos-online-admins"
import_if_not_exists "aws_iam_group.developers" "pedidos-online-developers"
import_if_not_exists "aws_iam_group.analysts" "pedidos-online-analysts"

import_if_not_exists "aws_iam_policy.admin_policy" "arn:aws:iam::${ACCOUNT_ID}:policy/pedidos-online-admin-policy"

echo " Buscando Target Groups..."
BACKEND_TG_ARN=$(aws elbv2 describe-target-groups --names pedidos-online-backend-tg --region $REGION --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ -n "$BACKEND_TG_ARN" ] && [ "$BACKEND_TG_ARN" != "None" ]; then
    import_if_not_exists "aws_lb_target_group.backend_tg" "$BACKEND_TG_ARN"
fi

FRONTEND_TG_ARN=$(aws elbv2 describe-target-groups --names pedidos-online-frontend-tg --region $REGION --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ -n "$FRONTEND_TG_ARN" ] && [ "$FRONTEND_TG_ARN" != "None" ]; then
    import_if_not_exists "aws_lb_target_group.frontend_tg" "$FRONTEND_TG_ARN"
fi

echo " Buscando ALB..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names pedidos-online-alb --region $REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    import_if_not_exists "aws_lb.main_alb" "$ALB_ARN"
fi

echo " Buscando WAF Web ACL..."
WAF_ID=$(aws wafv2 list-web-acls --scope REGIONAL --region $REGION --query "WebACLs[?Name=='pedidos-online-web-acl'].Id" --output text 2>/dev/null || echo "")
if [ -n "$WAF_ID" ] && [ "$WAF_ID" != "None" ]; then
    import_if_not_exists "aws_wafv2_web_acl.main" "${WAF_ID}/pedidos-online-web-acl/REGIONAL"
fi

echo " Buscando SQS Queues..."
ERROR_QUEUE_URL=$(aws sqs get-queue-url --queue-name pedidos-online-error-queue --region $REGION --query 'QueueUrl' --output text 2>/dev/null || echo "")
if [ -n "$ERROR_QUEUE_URL" ] && [ "$ERROR_QUEUE_URL" != "None" ]; then
    import_if_not_exists "aws_sqs_queue.error_queue" "$ERROR_QUEUE_URL"
fi

DLQ_URL=$(aws sqs get-queue-url --queue-name pedidos-online-lambda-dlq --region $REGION --query 'QueueUrl' --output text 2>/dev/null || echo "")
if [ -n "$DLQ_URL" ] && [ "$DLQ_URL" != "None" ]; then
    import_if_not_exists "aws_sqs_queue.lambda_dlq" "$DLQ_URL"
fi

echo " Buscando Backup Plan..."
BACKUP_PLAN_ID=$(aws backup list-backup-plans --region $REGION --query "BackupPlansList[?BackupPlanName=='pedidos-online-backup-plan'].BackupPlanId" --output text 2>/dev/null || echo "")
if [ -n "$BACKUP_PLAN_ID" ] && [ "$BACKUP_PLAN_ID" != "None" ]; then
    import_if_not_exists "aws_backup_plan.main_plan" "$BACKUP_PLAN_ID"
fi

import_if_not_exists "aws_signer_signing_profile.lambda_signing" "pedidosonlinelambdasigningprod"

echo " Importación completada!"
