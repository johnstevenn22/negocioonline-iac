resource "aws_iam_group" "admins" {
  name = "${var.project_name}-admins"
}

resource "aws_iam_group_policy_attachment" "admin_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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
