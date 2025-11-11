variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "dlq_enabled" {
  description = "Whether to create and attach a dead-letter queue"
  type        = bool
  default     = true
}

variable "dlq_name" {
  description = "Optional explicit name for the DLQ. When unset, defaults to <queue_name>-dlq"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "Max receive count before messages are sent to DLQ"
  type        = number
  default     = 5
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the main queue"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long to retain a message in the main queue"
  type        = number
  default     = 345600
}

variable "fifo" {
  description = "Whether the queue is FIFO"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "Default delay for messages on the main queue"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags to apply to the queue and related resources"
  type        = map(string)
  default     = {}
}

resource "aws_sqs_queue" "dlq" {
  count = var.dlq_enabled ? 1 : 0

  name                       = coalesce(var.dlq_name, "${var.queue_name}-dlq")
  message_retention_seconds  = 1209600 # 14 days
  tags                       = var.tags
}

locals {
  redrive_policy = var.dlq_enabled ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null
}

resource "aws_sqs_queue" "this" {
  name                        = var.queue_name
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  delay_seconds               = var.delay_seconds
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo ? var.content_based_deduplication : null
  redrive_policy              = var.dlq_enabled ? local.redrive_policy : null
  tags                        = var.tags
}

output "queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "The ARN of the main queue"
  value       = aws_sqs_queue.this.arn
}

output "dlq_arn" {
  description = "The ARN of the DLQ (if created)"
  value       = var.dlq_enabled ? aws_sqs_queue.dlq[0].arn : null
}


