
resource "aws_instance" "ec2_for_mysql_data" {
  ami           = var.aws_ami_id
  instance_type = "t3.micro"

  tags = {
    Name = "MySQL data checking"
  }

  iam_instance_profile = "${aws_iam_instance_profile.ec2_for_mysql_data_profile.name}"

  user_data = <<EOF
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y
yum install mysql httpd -y

echo '<h1>News from MySQL</h1>' > /var/www/html/index.html
echo '<pre>' >> /var/www/html/index.html

SHOW_DBS=$(mysql -u ${var.db_username} -p${var.db_password} -h ${aws_db_instance.db.address} -e "show databases;")
echo $SHOW_DBS >> /var/www/html/index.html

SHOW_TABLES=$(mysql -u ${var.db_username} -p${var.db_password} -h ${aws_db_instance.db.address} ${var.db_name} -e "show tables;")
echo $SHOW_TABLES >> /var/www/html/index.html

COUNT_CUST=$(mysql -u ${var.db_username} -p${var.db_password} -h ${aws_db_instance.db.address} ${var.db_name} -e "select count(*) from customers;")
echo $COUNT_CUST >> /var/www/html/index.html

echo '</pre>' >> /var/www/html/index.html

systemctl restart httpd.service

echo "-- Finished"

EOF
}

resource "aws_iam_role" "ec2_for_mysql_data_role" {
  name = "ec2_for_mysql_data_role"

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

resource "aws_iam_policy" "ec2_for_mysql_data_policy" {
  name        = "ec2_for_mysql_data_policy"
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

resource "aws_iam_role_policy_attachment" "ec2_for_mysql_data_policy_role_attachment" {
  role       = aws_iam_role.ec2_for_mysql_data_role.name
  policy_arn = aws_iam_policy.ec2_for_mysql_data_policy.arn
}

resource "aws_iam_instance_profile" "ec2_for_mysql_data_profile" {
  name = "ec2_for_mysql_data_profile"
  role = aws_iam_role.ec2_for_mysql_data_role.name
}

output "ec2_for_mysql_data_ip" {
  value = aws_instance.ec2_for_mysql_data.public_ip
}