# AWS Free Tier guardrails: AWS Budgets and CloudWatch billing alarms.

resource "aws_budgets_budget" "free_tier" {
  name              = "trusttunnel-free-tier-budget"
  budget_type       = "COST"
  limit_amount      = tostring(var.budget_amount)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_subscriber_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_subscriber_email]
  }
}

resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "trusttunnel-estimated-charges-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 hours
  statistic           = "Maximum"
  threshold           = var.budget_amount
  alarm_description   = "Billing alarm triggered when AWS charges exceed the monthly Free Tier guardrail budget."

  dimensions = {
    Currency = "USD"
  }
}
