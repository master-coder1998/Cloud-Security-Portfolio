/*
Cross-account IAM role(s) to allow workload accounts to put logs into the
central archive bucket. This is a skeleton; in production you should lock down
principals and add conditions (e.g. SourceAccount, aws:SourceArn).
*/

resource "aws_iam_role" "log_delivery_role" {
  name = "central-log-delivery-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "delivery.logs.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "log_write_policy" {
  name = "central-log-write-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = ["${aws_s3_bucket.log_archive.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_write" {
  role       = aws_iam_role.log_delivery_role.name
  policy_arn = aws_iam_policy.log_write_policy.arn
}
