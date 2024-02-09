resource "aws_iam_role" "ec2_role" {
  name        = "ec2_role"
  description = "EC2 Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "iam_allow" {
  name = "allow_policy_to_iam"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "iam:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iam_allow" {
  policy_arn = aws_iam_policy.iam_allow.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "web" {
  name = "allow_policy_to_iam"
  role = aws_iam_role.ec2_role.name
}