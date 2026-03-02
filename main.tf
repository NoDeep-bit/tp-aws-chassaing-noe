provider "aws" {
  region = "us-east-1"
}

############################
# IAM
############################

resource "aws_iam_user" "user" {
  name = "iam-chassaing-noe"
}

resource "aws_iam_group" "group" {
  name = "iam-chassaing-noe"
}

resource "aws_iam_user_group_membership" "membership" {
  user = aws_iam_user.user.name

  groups = [
    aws_iam_group.group.name
  ]
}

resource "aws_iam_group_policy_attachment" "policy" {
  group      = aws_iam_group.group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

############################
# SECURITY GROUP (SSH + HTTP)
############################

resource "aws_security_group" "sg" {
  name = "ec2-chassaing-noe"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# EC2
############################

resource "aws_instance" "ec2" {
  ami           = "ami-053b0d53c279acc90" # Ubuntu 22.04 us-east-1
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "ec2-chassaing-noe"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install apache2 -y
              echo "<h1>Bonjour Master 2 informatique UCAD</h1>" > /var/www/html/index.html
              systemctl start apache2
              EOF
}

############################
# S3
############################

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-chassaing-noe-2026"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.bucket.id
  key    = "index.html"
  content = "<h1>Bonjour Master 2 informatique UCAD</h1>"
  content_type = "text/html"
}

############################
# LIFECYCLE RULE
############################

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "lifecycle-rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 120
      storage_class = "GLACIER"
    }

    expiration {
      days = 130
    }
  }
}