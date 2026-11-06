variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (pass with TF_VAR_subscription_id, never commit it)"
}

variable "owner_email" {
  type        = string
  description = "Value for the owner tag and budget alerts"
}

variable "allowed_locations" {
  type    = list(string)
  default = ["eastus", "eastus2"]
}

variable "cost_center" {
  type    = string
  default = "training"
}

variable "budget_amount" {
  type    = number
  default = 25
}