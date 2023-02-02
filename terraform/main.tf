terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_s3_bucket" "s3_access_logs" {
  bucket = "logs.asherkhb.com"
}

resource "aws_s3_bucket" "website" {
  bucket = "asherkhb.com"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "website" {
  bucket = aws_s3_bucket.website.id

  target_bucket = data.aws_s3_bucket.s3_access_logs.id
  target_prefix = "root/"
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website.json
}

data "aws_iam_policy_document" "website" {
  statement {
    sid    = "Allow Public Access to All Objects"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]
  }
}

# TODO: aws_s3_bucket www.asherkhb.com

resource "aws_route53_zone" "main" {
  name    = "asherkhb.com"
  comment = ""
}

resource "aws_route53_record" "a_main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "asherkhb.com"
  type    = "A"
  alias {
    name = "s3-website-us-east-1.amazonaws.com"
    zone_id = aws_s3_bucket.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "a_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.asherkhb.com"
  type    = "A"
  alias {
    name = "asherkhb.com"
    zone_id = aws_route53_zone.main.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "txt_ms" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "asherkhb.com"
  type    = "TXT"
  ttl     = 3600
  records = ["MS=ms94411360"]
}
