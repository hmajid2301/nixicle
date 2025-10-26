# # BetterStack Monitoring and Logging Configuration
#
# # Variables for BetterStack configuration
# variable "betterstack_api_token" {
#   description = "BetterStack API token for uptime monitoring"
#   type        = string
#   sensitive   = true
# }
#
# variable "logtail_api_token" {
#   description = "Logtail API token for log management"
#   type        = string
#   sensitive   = true
# }
#
# variable "project_name" {
#   description = "Name of the project (used for resource naming)"
#   type        = string
#   default     = "nixicle"
# }
#
# variable "domain" {
#   description = "Primary domain to monitor"
#   type        = string
#   default     = "homelab.haseebmajid.dev"
# }
#
# variable "api_health_endpoint" {
#   description = "API health check endpoint"
#   type        = string
#   default     = "/health"
# }
#
# variable "contact_email" {
#   description = "Contact email for status page"
#   type        = string
#   default     = "admin@haseebmajid.dev"
# }
#
# variable "monitor_regions" {
#   description = "Regions to monitor from"
#   type        = list(string)
#   default     = ["us", "eu"]
# }
#
# variable "check_frequency" {
#   description = "Monitor check frequency in seconds"
#   type        = number
#   default     = 60
# }
#
# variable "api_check_frequency" {
#   description = "API monitor check frequency in seconds"
#   type        = number
#   default     = 30
# }
#
# variable "heartbeat_period" {
#   description = "Heartbeat period in seconds"
#   type        = number
#   default     = 60
# }
#
# variable "heartbeat_grace" {
#   description = "Heartbeat grace period in seconds"
#   type        = number
#   default     = 30
# }
#
# variable "status_page_subdomain" {
#   description = "Status page subdomain"
#   type        = string
#   default     = "status"
# }
#
# variable "timezone" {
#   description = "Timezone for status page"
#   type        = string
#   default     = "UTC"
# }
#
# variable "enable_email_notifications" {
#   description = "Enable email notifications for monitors"
#   type        = bool
#   default     = true
# }
#
# variable "logtail_source_name" {
#   description = "Name for the Logtail source"
#   type        = string
#   default     = "Application Logs"
# }
#
# variable "logtail_platform" {
#   description = "Platform type for Logtail source"
#   type        = string
#   default     = "opentelemetry"
#
#   validation {
#     condition = contains(["http", "opentelemetry", "syslog"], var.logtail_platform)
#     error_message = "Platform must be one of: http, opentelemetry, syslog"
#   }
# }
#
# # Provider configuration for BetterStack
# provider "betterstack" {
#   api_token = var.betterstack_api_token
# }
#
# provider "logtail" {
#   api_token = var.logtail_api_token
# }
#
# # Website Monitor
# resource "betterstack_monitor" "website" {
#   url             = "https://${var.domain}"
#   monitor_type    = "status"
#   request_type    = "GET"
#   check_frequency = var.check_frequency
#
#   email           = var.enable_email_notifications
#   paused          = false
#   regions         = var.monitor_regions
#   recovery_period = 0
#   confirmation_period = 30
# }
#
# # API Health Monitor
# resource "betterstack_monitor" "api_health" {
#   url             = "https://${var.domain}${var.api_health_endpoint}"
#   monitor_type    = "status"
#   request_type    = "GET"
#   check_frequency = var.api_check_frequency
#
#   email                 = var.enable_email_notifications
#   paused                = false
#   regions               = var.monitor_regions
#   recovery_period       = 0
#   confirmation_period   = 30
#   expected_status_codes = [200]
# }
#
# # Logtail Source
# resource "logtail_source" "app_logs" {
#   name     = var.logtail_source_name
#   platform = var.logtail_platform
# }
#
# # Heartbeat Monitor
# resource "betterstack_heartbeat" "app_heartbeat" {
#   name   = "${var.project_name}-app-heartbeat"
#   period = var.heartbeat_period
#   grace  = var.heartbeat_grace
#   email  = var.enable_email_notifications
# }
#
# # Status Page
# resource "betterstack_status_page" "main" {
#   company_name = var.project_name
#   company_url  = "https://${var.domain}"
#   contact_url  = "mailto:${var.contact_email}"
#
#   timezone    = var.timezone
#   subdomain   = var.status_page_subdomain
#   design      = "v2"
#   layout      = "vertical"
#   subscribable = true
# }
#
# # Status Page Sections
# resource "betterstack_status_page_section" "website" {
#   status_page_id = betterstack_status_page.main.id
#   name          = "Website"
#   position      = 1
# }
#
# resource "betterstack_status_page_section" "api" {
#   status_page_id = betterstack_status_page.main.id
#   name          = "API"
#   position      = 2
# }
#
# # Status Page Resources
# resource "betterstack_status_page_resource" "website_monitor" {
#   status_page_id = betterstack_status_page.main.id
#   resource_id    = betterstack_monitor.website.id
#   resource_type  = "Monitor"
#
#   status_page_section_id = betterstack_status_page_section.website.id
#   position = 1
# }
#
# resource "betterstack_status_page_resource" "api_health_monitor" {
#   status_page_id = betterstack_status_page.main.id
#   resource_id    = betterstack_monitor.api_health.id
#   resource_type  = "Monitor"
#
#   status_page_section_id = betterstack_status_page_section.api.id
#   position = 1
# }
#
# # Outputs
# output "logtail_source_token" {
#   description = "Logtail source token for sending logs"
#   value       = logtail_source.app_logs.token
#   sensitive   = true
# }
#
# output "logtail_source_endpoint" {
#   description = "Logtail OTLP endpoint (if OpenTelemetry platform)"
#   value       = var.logtail_platform == "opentelemetry" ? logtail_source.app_logs.otlp_endpoint : null
#   sensitive   = false
# }
#
# output "heartbeat_url" {
#   description = "Heartbeat URL for application to ping"
#   value       = betterstack_heartbeat.app_heartbeat.url
#   sensitive   = false
# }
#
# output "website_monitor_id" {
#   description = "Website monitor ID"
#   value       = betterstack_monitor.website.id
# }
#
# output "api_health_monitor_id" {
#   description = "API health monitor ID"
#   value       = betterstack_monitor.api_health.id
# }
#
# output "status_page_url" {
#   description = "Public status page URL"
#   value       = betterstack_status_page.main.url
# }
#
# output "status_page_subdomain" {
#   description = "Status page subdomain"
#   value       = betterstack_status_page.main.subdomain
# }
#
# output "monitors" {
#   description = "All monitor information"
#   value = {
#     website = {
#       id  = betterstack_monitor.website.id
#       url = betterstack_monitor.website.url
#     }
#     api_health = {
#       id  = betterstack_monitor.api_health.id
#       url = betterstack_monitor.api_health.url
#     }
#   }
# }

