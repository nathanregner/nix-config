terraform {
  backend "s3" {
    bucket = "terraform-dcdf20ad-dcc3-4477-9ef9-4309d1e04799"
    key    = "nix-config/infrastructure/s3-cache"
    region = "us-west-2"
  }
}

resource "aws_s3_bucket" "nix_binary_cache" {
  bucket = "nregner-nix-binary-cache"
}

output "nix_binary_cache" {
  value = aws_s3_bucket.nix_binary_cache.bucket
}