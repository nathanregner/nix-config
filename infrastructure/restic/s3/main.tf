variable "bucket_name" {
  type = string
}

variable "username" {
  type = string
}

locals {
  username = "${var.username}-nix-restic"
}

resource "aws_s3_bucket" "restic" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "restic" {
  bucket = aws_s3_bucket.restic.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_user" "nix_restic" {
  name = local.username
}

resource "aws_iam_access_key" "nix_restic" {
  user = aws_iam_user.nix_restic.name
}

# https://restic.readthedocs.io/en/stable/080_examples.html#setting-up-restic-with-amazon-s3
data "aws_iam_policy_document" "nix_restic_rw" {
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.restic.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.restic.arn
    ]
  }
}

resource "aws_iam_policy" "nix_restic_rw" {
  policy = data.aws_iam_policy_document.nix_restic_rw.json
}

resource "aws_iam_policy_attachment" "nix_restic" {
  name       = local.username
  policy_arn = aws_iam_policy.nix_restic_rw.arn
  users      = [aws_iam_user.nix_restic.name]
}

output "env" {
  value     = <<EOT
AWS_ACCESS_KEY_ID=${aws_iam_access_key.nix_restic.id}
AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.nix_restic.secret}
AWS_DEFAULT_REGION=us-west-2
EOT
  sensitive = true
}
