resource "random_pet" "foo_bucket_name" {
  prefix = "foo-bucket"
  length = 4
}

resource "aws_s3_bucket" "foo_bucket" {
  bucket = random_pet.foo_bucket_name.id
  force_destroy = true
}

resource "aws_s3_bucket_acl" "foo_bucket_acl" {
  bucket = aws_s3_bucket.foo_bucket.id
  acl    = "private"
}
