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

# website bucket

resource "aws_s3_bucket" "main" {
  bucket = var.domain
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id

  target_bucket = data.aws_s3_bucket.s3_access_logs.id
  target_prefix = "root/"
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
}

data "aws_iam_policy_document" "main" {
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
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

# www redirect bucket

resource "aws_s3_bucket" "www" {
  bucket = "www.${var.domain}"
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.id

  redirect_all_requests_to {
    host_name = aws_s3_bucket.main.id
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "www" {
  bucket = aws_s3_bucket.www.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "www" {
  bucket = aws_s3_bucket.www.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# route53

resource "aws_route53_zone" "main" {
  name    = var.domain
  comment = ""
}

resource "aws_route53_record" "a_main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = "s3-website-us-east-1.amazonaws.com"
    zone_id                = aws_s3_bucket.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "a_www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain}"
  type    = "A"
  alias {
    name                   = var.domain
    zone_id                = aws_route53_zone.main.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "txt_ms" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = 3600
  records = ["MS=ms94411360"]
}
