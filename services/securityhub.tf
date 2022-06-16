resource "aws_securityhub_account" "fauna-securityhub" {}

resource "aws_securityhub_standards_subscription" "aws_foundational_security" {
    standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
    depends_on = [
      aws_securityhub_account.fauna-securityhub
    ]
}

resource "aws_securityhub_standards_control" "name" {
    standards_control_arn = "arn:aws:securityhub:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:control/aws-foundational-security-best-practices/v/1.0.0/EC2.9"
    control_status = "DISABLED"
    disabled_reason = "ACG Sandbox PoC will need a public IPv4 address"
    depends_on = [
      aws_securityhub_standards_subscription.aws_foundational_security
    ]
}