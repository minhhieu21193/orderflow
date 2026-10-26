# Monthly cost budget with email alerts at 80% and 100% of actual spend, plus
# 100% of forecast spend so a runaway month is flagged before it happens.
#
# By default the budget covers the whole account: cost allocation tags
# (e.g. Env) only start filtering costs ~24h after they are activated in the
# Billing console, so a tag-filtered budget reads $0 on a fresh account.
# Once the tag is active, set cost_filter_tag to scope the budget to one env.

resource "aws_budgets_budget" "monthly" {
  name         = var.name
  budget_type  = "COST"
  limit_amount = format("%.2f", var.monthly_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "cost_filter" {
    for_each = var.cost_filter_tag == null ? [] : [var.cost_filter_tag]
    content {
      name   = "TagKeyValue"
      values = [format("user:%s$%s", cost_filter.value.key, cost_filter.value.value)]
    }
  }

  dynamic "notification" {
    for_each = {
      actual-80    = { type = "ACTUAL", threshold = 80 }
      actual-100   = { type = "ACTUAL", threshold = 100 }
      forecast-100 = { type = "FORECASTED", threshold = 100 }
    }
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = notification.value.type
      subscriber_email_addresses = var.alert_emails
    }
  }
}
