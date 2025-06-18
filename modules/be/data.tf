data "template_file" "startup" {
  template = file("${path.module}/scripts/startup.sh")
}