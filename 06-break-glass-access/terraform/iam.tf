/*
Skeleton IAM resources for Break-Glass access. Review and tighten before use.
*/

resource "aws_iam_role" "break_glass_role" {
  name = "break-glass-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { AWS = "arn:aws:iam::111111111111:role/BreakGlassController" },
        Action = "sts:AssumeRole",
        Condition = {
          Bool = { "aws:MultiFactorAuthPresent" = "true" }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "break_glass_policy" {
  name = "break-glass-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["iam:CreateAccessKey","iam:UpdateAccessKey","iam:PutUserPolicy","ec2:DescribeInstances","ssm:StartSession"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_break_glass" {
  role       = aws_iam_role.break_glass_role.name
  policy_arn = aws_iam_policy.break_glass_policy.arn
}
