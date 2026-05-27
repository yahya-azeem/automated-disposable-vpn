# GCP Free Tier guardrails: GCP Billing Budgets.
# Note: Commented out because billing APIs require billing account ID which may vary,
# and it is not typically supported in local emulators.

/*
data "google_billing_account" "account" {
  billing_account = "000000-000000-000000"
}

resource "google_billing_budget" "free_tier" {
  billing_account = data.google_billing_account.account.id
  display_name    = "trusttunnel-free-tier-budget"

  budget_filter {
    projects = ["projects/${var.gcp_project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "FORECASTED_SPEND"
  }

  # Requires setting up a Pub/Sub topic and notification channel for emails.
}
*/
