resource "aws_instance" "ec2_for_mysql_loading" {
  ami           = var.aws_ami_id
  instance_type = "t3.micro"

  tags = {
    Name = "MySQL data loading"
  }

  iam_instance_profile = "${aws_iam_instance_profile.ec2_for_mysql_loading_profile.name}"

  user_data = <<EOF
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y
yum install httpd mysql -y
systemctl restart httpd.service

time aws s3 cp s3://${aws_s3_bucket.foo_bucket.id}/mysqlsampledatabase.sql .

time mysql -u ${var.db_username} -p${var.db_password} -h ${aws_db_instance.initial_db.address} < mysqlsampledatabase.sql

SHOW_DBS=$(mysql -u ${var.db_username} -p${var.db_password} -h ${aws_db_instance.initial_db.address} -e "show databases;")

echo '<h1>News from MySQL</h1>' > /var/www/html/index.html
echo '<pre>' >> /var/www/html/index.html
echo $SHOW_DBS >> /var/www/html/index.html
echo '</pre>' >> /var/www/html/index.html

systemctl restart httpd.service

echo "-- Finished"

EOF
}

resource "aws_iam_role" "ec2_for_mysql_loading_role" {
  name = "ec2_for_mysql_loading_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid = ""
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_for_mysql_loading_policy" {
  name        = "ec2_for_mysql_loading_policy"
  path        = "/"
  description = "Policy to provide permissions to EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_for_mysql_loading_policy_role_attachment" {
  role       = aws_iam_role.ec2_for_mysql_loading_role.name
  policy_arn = aws_iam_policy.ec2_for_mysql_loading_policy.arn
}

resource "aws_iam_instance_profile" "ec2_for_mysql_loading_profile" {
  name = "ec2_for_mysql_loading_profile"
  role = aws_iam_role.ec2_for_mysql_loading_role.name
}

output "ec2_for_mysql_loading_ip" {
  value = aws_instance.ec2_for_mysql_loading.public_ip
}