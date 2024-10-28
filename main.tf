provider "aws" {
  region = "us-west-2" # Change to your preferred AWS region
}

# Security Group for Redshift
resource "aws_security_group" "redshift_sg" {
  name        = "redshift-sg"
  description = "Security group for Redshift Cluster"

  # Example rule to allow inbound access from any IP on port 5439 (default Redshift port)
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with a more restrictive CIDR for production use
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
  cluster_identifier = "my-redshift-cluster" # Choose a unique identifier
  database_name      = "mydatabase"
  master_username    = "adminuser"
  master_password    = "SuperSecretPassword123!" # Use a secure password

  node_type          = "dc2.large" # Change as per your requirements
  cluster_type       = "single-node" # Use "multi-node" for multi-node setup
  publicly_accessible = true

  # Use security group created above
  vpc_security_group_ids = [aws_security_group.redshift_sg.id]

  # Optional settings
  port                   = 5439
  skip_final_snapshot    = true
}

output "redshift_endpoint" {
  value = aws_redshift_cluster.redshift_cluster.endpoint
}

output "redshift_id" {
  value = aws_redshift_cluster.redshift_cluster.id
}
