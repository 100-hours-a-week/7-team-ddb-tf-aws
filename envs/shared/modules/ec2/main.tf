resource "aws_iam_role" "this" {
  name               = "${var.name}-ssm-role"
  assume_role_policy = file("${path.module}/policy/ssm_instance_assume_role.json")
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  key_name               = null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    delete_on_termination = true
    tags = {
      Name = "${var.name}-root-volume"
    }
  }

  tags = merge(var.common_tags, {
    Name = var.name
  })

  user_data = var.user_data
}
