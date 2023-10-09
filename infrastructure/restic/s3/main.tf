variable "bucket_prefix" {
  type = string
}

variable "username" {
  type = string
}

locals {
  bucket_name = var.bucket_prefix
  username    = "${var.username}-nix-restic"
}

resource "aws_iam_user" "nix_restic" {
  name = local.username
}

resource "aws_iam_access_key" "nix_restic" {
  user = aws_iam_user.nix_restic.name
}

data "aws_iam_policy_document" "nix_restic_append_only" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}/locks/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}"
    ]
  }
}

resource "aws_iam_policy" "nix_restic_append_only" {
  policy = data.aws_iam_policy_document.nix_restic_append_only.json
}

resource "aws_iam_policy_attachment" "nix_restic" {
  name       = local.username
  policy_arn = aws_iam_policy.nix_restic_append_only.arn
  users      = [aws_iam_user.nix_restic.name]
}

output "env" {
  value     = <<EOT
BUCKET_PREFIX=${var.bucket_prefix}
AWS_ACCESS_KEY_ID=${aws_iam_access_key.nix_restic.id}
AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.nix_restic.secret}
AWS_DEFAULT_REGION=us-west-2
EOT
  sensitive = true
}
