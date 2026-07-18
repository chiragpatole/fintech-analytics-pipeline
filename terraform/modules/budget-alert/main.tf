# ---------------------------------------------------------------------------
# Budget Alert Module
#
# Creates a Cloud Billing budget scoped to this project, with email alerts
# at 50% / 90% / 100% of spend. This is the guardrail that keeps a solo
# portfolio project from producing a surprise bill.
# ---------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "FinOps budget alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  display_name    = var.budget_display_name

  budget_filter {
    projects = ["projects/${var.project_number}"]
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [
      google_monitoring_notification_channel.email.id
    ]
    disable_default_iam_recipients = false # keep billing-account admins in the loop too
  }
}
