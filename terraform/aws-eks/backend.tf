terraform {
  backend "s3" {
    bucket         = "enterprise-k8s-platform-tfstate"
    key            = "aws-eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "enterprise-k8s-platform-tflock"
  }
}
