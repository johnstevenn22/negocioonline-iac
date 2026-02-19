resource "aws_iam_group" "admins" {
  name = "${var.project_name}-admins"
}

resource "aws_iam_policy" "admin_policy" {
  name        = "${var.project_name}-admin-policy"
  description = "Admin policy with some restrictions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowMostServices"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-gov-west-1", "us-gov-east-1"]
          }
        }
      },
      {
        Sid    = "DenyDangerousActions"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization",
          "account:CloseAccount",
          "iam:DeleteAccountPasswordPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "admin_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

resource "aws_iam_group_policy_attachment" "developer_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group" "analysts" {
  name = "${var.project_name}-analysts"
}

resource "aws_iam_group_policy_attachment" "analyst_attach" {
  group      = aws_iam_group.analysts.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
