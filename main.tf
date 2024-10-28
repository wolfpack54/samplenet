provider "aws" {
  region = "us-west-2" # Set your preferred AWS region
}

# S3 Bucket for Audit Logs
resource "aws_s3_bucket" "redshift_audit_logs" {
  bucket = "redshift-audit-logs-bucket" # Ensure this bucket name is globally unique
}

# SNS Topic for Redshift Notifications
resource "aws_sns_topic" "redshift_topic" {
  name = "redshift-cluster-alerts"
}

# CloudWatch Alarm for Redshift Cluster (e.g., CPU utilization)
resource "aws_cloudwatch_metric_alarm" "redshift_cpu_alarm" {
  alarm_name          = "RedshiftCPUUtilizationAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "75" # Alert if CPU utilization > 75%

  alarm_actions = [aws_sns_topic.redshift_topic.arn]
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.redshift_cluster.cluster_identifier
  }
}

# Subnet Group for Redshift Cluster
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "redshift-subnet-group"
  description = "Subnet group for Redshift cluster in multi-AZ"

  subnet_ids = [
    "subnet-12345abcde", # Replace with actual subnet IDs
    "subnet-67890fghij"
  ]
}

# Parameter Group for Redshift Cluster
resource "aws_redshift_parameter_group" "redshift_parameter_group" {
  name   = "redshift-custom-parameters"
  family = "redshift-1.0"

  parameter {
    name  = "enable_user_activity_logging"
    value = "true" # Enable audit logging for user activity
  }

  # Add additional parameters as needed
}

# Security Group for Redshift
resource "aws_security_group" "redshift_sg" {
  name        = "redshift-sg"
  description = "Security group for Redshift Cluster"

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to a more restrictive CIDR in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Redshift Cluster
resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier      = "multi-az-redshift-cluster"
  database_name           = "mydatabase"
  master_username         = "adminuser"
  master_password         = "SuperSecretPassword123!" # Use a secure password
  node_type               = "dc2.large" # Adjust instance type as needed
  cluster_type            = "multi-node"
  number_of_nodes         = 2 # Specify the number of nodes for multi-node setup

  vpc_security_group_ids  = [aws_security_group.redshift_sg.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift_subnet_group.name
  publicly_accessible     = true
  logging {
    enable = true
    bucket_name = aws_s3_bucket.redshift_audit_logs.bucket
    s3_key_prefix = "audit-logs/"
  }

  automated_snapshot_retention_period = 1
  parameter_group_name               = aws_redshift_parameter_group.redshift_parameter_group.name
}

# Route 53 Record for Redshift Cluster
resource "aws_route53_record" "redshift_dns_record" {
  zone_id = "Z12345ABCDEFG" # Replace with your Route 53 hosted zone ID
  name    = "redshift-cluster.example.com" # Replace with your desired DNS name
  type    = "CNAME"
  ttl     = 300

  records = [aws_redshift_cluster.redshift_cluster.endpoint]
}

# Outputs
output "redshift_endpoint" {
  value = aws_redshift_cluster.redshift_cluster.endpoint
}

output "s3_audit_logs_bucket" {
  value = aws_s3_bucket.redshift_audit_logs.bucket
}

output "cloudwatch_alarm" {
  value = aws_cloudwatch_metric_alarm.redshift_cpu_alarm.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.redshift_topic.arn
}
