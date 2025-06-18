data "template_file" "startup" {
  template = file("${path.module}/script/startup.sh")
}