terraform {
  backend "s3" {
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "profile" {
  version = "2012-10-17"
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.aws_bucket}/*"
    ]
    condition {
      test = "IpAddress"
      values = [
        "173.245.48.0/20",
        "103.21.244.0/22",
        "103.22.200.0/22",
        "103.31.4.0/22",
        "141.101.64.0/18",
        "108.162.192.0/18",
        "190.93.240.0/20",
        "188.114.96.0/20",
        "197.234.240.0/22",
        "198.41.128.0/17",
        "162.158.0.0/15",
        "104.16.0.0/13",
        "104.24.0.0/14",
        "172.64.0.0/13",
        "131.0.72.0/22"
      ]
      variable = "aws:SourceIp"
    }
  }
}

resource "aws_s3_bucket_policy" "profile" {
  bucket = aws_s3_bucket.profile.bucket
  policy = data.aws_iam_policy_document.profile.json
}

resource "aws_s3_object" "profile_html" {
  bucket       = aws_s3_bucket.profile.bucket
  key          = "index.html"
  source       = "ak/index.html"
  content_type = "text/html"
  source_hash  = filemd5("ak/index.html")
}

resource "aws_s3_object" "profile_css" {
  for_each     = fileset(path.module, "ak/css/*")
  bucket       = aws_s3_bucket.profile.bucket
  key          = trim(each.value, "ak/")
  source       = each.value
  content_type = "text/css"
  source_hash  = filemd5(each.value)
}

resource "aws_s3_object" "profile_js" {
  for_each     = fileset(path.module, "ak/js/*")
  bucket       = aws_s3_bucket.profile.bucket
  key          = trim(each.value, "ak/")
  source       = each.value
  content_type = "text/javascript"
  source_hash  = filemd5(each.value)
}

resource "aws_s3_object" "profile_assets" {
  for_each    = fileset(path.module, "ak/img/assets/*")
  source      = each.value
  bucket      = aws_s3_bucket.profile.bucket
  key         = trim(each.value, "ak/")
  source_hash = filemd5(each.value)
  content_type = lookup(
    {
      "png"         = "image/png",
      "ico"         = "image/x-icon"
      "webmanifest" = "text/plain"
    },
    split(".", each.value)[1],
  "text/plain")
}

resource "aws_s3_object" "profile_gpg" {
  for_each            = fileset(path.module, "ak/files/*")
  bucket              = aws_s3_bucket.profile.bucket
  key                 = trim(each.value, "ak/")
  source              = each.value
  content_type        = "application/octet-stream"
  content_disposition = "attachment; filename='patrick.asc'"
  source_hash         = filemd5(each.value)
}

resource "aws_s3_object" "profile_src" {
  for_each    = fileset(path.module, "ak/src/*")
  source      = each.value
  bucket      = aws_s3_bucket.profile.bucket
  key         = trim(each.value, "ak/")
  source_hash = filemd5(each.value)
  content_type = lookup(
    {
      "js" = "text/javascript"
    },
    split(".", each.value)[1],
  "text/plain")
}

resource "aws_s3_bucket" "profile" {
  bucket = var.aws_bucket
  tags = {
    deployed_with_terraform = true
    deployed_from_github    = true
    description             = "profile s3 bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "profile" {
  bucket = aws_s3_bucket.profile.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "profile" {
  bucket = aws_s3_bucket.profile.bucket

  cors_rule {
    allowed_headers = [
      "Authorization",
      "Content-Length"
    ]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_acl" "profile_acl" {
  bucket = aws_s3_bucket.profile.bucket
  acl    = "public-read"
}