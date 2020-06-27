
variable "aws_profile" {}

provider "aws" {
  profile = "moj-cp"
  // AWS region does not matter since we're only dealing with IAM but is
  // required for the provider.
  region = "eu-west-2"
}

data "aws_caller_identity" "current" {
}


resource "random_id" "id" {
  byte_length = 8
}


resource "aws_iam_user" "rds_user" {
  name = "${terraform.workspace}-rds-${random_id.id.hex}"
  path = "/cloud-platform/"
}

resource "aws_iam_access_key" "iam_access_key" {
  user = aws_iam_user.rds_user.name
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${terraform.workspace}-rds-user-policy-${random_id.id.hex}"
  path        = "/cloud-platform/"
  policy      = data.aws_iam_policy_document.policy.json
  description = "Policy for ${terraform.workspace}-rds-${random_id.id.hex}"
}

resource "aws_iam_policy_attachment" "attach_policy" {
  name       = "attached-policy"
  users      = [aws_iam_user.rds_user.name]
  policy_arn = aws_iam_policy.policy.arn
}

output "id" {
  value = aws_iam_access_key.iam_access_key.id
}

output "secret" {
  value = aws_iam_access_key.iam_access_key.secret
}

