terraform {
  backend "s3" {
    bucket = "ratl-fiaptech1-2024-terraform-state2"
    key    = "fiap/tech-challenge"
    region = "us-east-1"
  }
}