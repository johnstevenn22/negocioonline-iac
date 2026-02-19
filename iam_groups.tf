# Grupo 1: Administradores (Full Access)
resource "aws_iam_group" "admins" {
  name = "Admins-Group"
}

resource "aws_iam_group_policy_attachment" "admin_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Grupo 2: Usuarios de Servicio (Acceso a recursos específicos)
resource "aws_iam_group" "users" {
  name = "Service-Users-Group"
}

resource "aws_iam_group_policy_attachment" "user_attach" {
  group      = aws_iam_group.users.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess" # Acceso casi total excepto IAM
}

# Grupo 3: Analistas (Solo lectura / View Only)
resource "aws_iam_group" "analysts" {
  name = "Analysts-Group"
}

resource "aws_iam_group_policy_attachment" "analyst_attach" {
  group      = aws_iam_group.analysts.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}