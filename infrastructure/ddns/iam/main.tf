variable "subdomain" {
  type = string
}

variable "username" {
  type = string
}

locals {
  username = "${var.username}-nix-ddns"
}

data "aws_route53_zone" "zone" {
  name = "nregner.net"
}

resource "aws_iam_user" "nix_ddns" {
  name = local.username
}

resource "aws_iam_access_key" "nix_ddns" {
  user = aws_iam_user.nix_ddns.name
}

data "aws_iam_policy_document" "nix_ddns" {
  statement {
    sid    = "Read"
    effect = "Allow"
    actions = [
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "Upsert"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [data.aws_route53_zone.zone.arn]
    # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/specifying-rrset-conditions.html
    condition {
      test     = "ForAllValues:StringLike"
      variable = "route53:ChangeResourceRecordSetsNormalizedRecordNames"
      values   = ["${var.subdomain}.${data.aws_route53_zone.zone.name}"]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["A"]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsActions"
      values   = ["UPSERT"]
    }
  }
}

resource "aws_iam_policy" "nix_ddns" {
  policy = data.aws_iam_policy_document.nix_ddns.json
}

resource "aws_iam_policy_attachment" "nix_ddns" {
  name       = local.username
  policy_arn = aws_iam_policy.nix_ddns.arn
  users      = [aws_iam_user.nix_ddns.name]
}

output "aws_env" {
  value     = <<EOT
HOSTED_ZONE_ID=${data.aws_route53_zone.zone.zone_id}
AWS_ACCESS_KEY_ID=${aws_iam_access_key.nix_ddns.id}
AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.nix_ddns.secret}
AWS_DEFAULT_REGION=us-west-2
EOT
  sensitive = true
}
