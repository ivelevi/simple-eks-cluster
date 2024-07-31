provider "aws" {
  region = ""   # Your region
}

# NOTE: This is the creation of the state, so the state of itself cannot be stored (who watches the watchmen?)
# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "YOUR-terraformstate"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name = "YOUR-terraformstate"
  }
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-locks"
  }
}

output "s3_bucket_id" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
