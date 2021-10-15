
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "website_main" {
  bucket = "asherkhb.com"
  acl    = "public-read"
  policy = file("website_bucket_policy.json")

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket" "website_redirect" {
  bucket                   = "www.asherkhb.com"
  redirect_all_requests_to = "${aws_s3_bucket.website_main.website_endpoint}"
}
