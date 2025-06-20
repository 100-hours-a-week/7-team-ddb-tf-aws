data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "dolpin-terraform-state-bn2gz7v3he1rj0ia"
    key    = "shared/terraform/terraform.tfstate"
    region = "ap-northeast-2"
  }
}