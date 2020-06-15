provider "aws" {
  region     = "ap-south-1"
  profile = "ninja"
 }
 
resource "tls_private_key" "example_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "new_key" {
	key_name = "new_key"
	public_key = tls_private_key.example_key.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.example_key.private_key_pem
  filename = "kill.pem"
  file_permission = 0400
}

//security group create

resource "aws_security_group" "allow_tls" {
  name        = "new_group"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-e9919381"

  ingress {
    description = "Allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "new_group"
  }
}
  //instance lunch


resource "aws_instance" "new_instance" {
  ami = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
  key_name = aws_key_pair.new_key.key_name
  security_groups = ["new_group"]
  tags = {
    Name = "new-terraform"
   }
}
//ebs volume crete

resource "aws_ebs_volume" "terraform" {
  availability_zone = aws_instance.new_instance.availability_zone
  size              = 1

  tags = {
    Name = "terraform"
  }
}
//ebs volume mount

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.terraform.id
  instance_id = aws_instance.new_instance.id
}

resource "null_resource" "null" {

 depends_on = [
     aws_instance.new_instance,
  ]
    connection {
     type     = "ssh"
     user     = "ec2-user"
     private_key = file("d:/terraform/final/kill.pem")
     host     = aws_instance.new_instance.public_ip
  }
	provisioner "remote-exec" {
		inline = [
		    "sudo yum install httpd git -y",
		    "sudo mkfs -t ext4 /dev/xvdh",
        "mount /dev/xvdh /var/www/html",
        "echo /dev/xvdh /var/www/html ext4 defaults,nofail 0 2 >> /etc/fstab",
        "sudo rm -rf /var/www/html/*",
        "sudo git clone https://github.com/NINJAFURRY/terraform-images.git /var/www/html/",
        "sudo service httpd start",
        ]
	}
}

resource "aws_s3_bucket" "b" {
  bucket = "test-example1234-bucket"
  acl    = "public-read"

  tags = {
    Name        = "test-example1234-bucket"
    Environment = "Dev"
  }
 }
  resource "aws_s3_bucket_object" "object" {
   depends_on = [ aws_s3_bucket.b, ]
  bucket = "test-example1234-bucket"
  key    = "object.png"
  source = "D:/terraform/images/terra.png"
  acl = "public-read"
  } 

  locals {
  s3_origin_id = "S3-test-example1234-bucket"
}

# origin access id
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "this is OAI to be used in cloudfront"
}

# creating cloudfront 
resource "aws_cloudfront_distribution" "s3_distribution" {

  depends_on = [ aws_cloudfront_origin_access_identity.oai,]

  origin {
    domain_name = aws_s3_bucket.b.bucket_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("d:/terraform/final/kill.pem")
    host     = aws_instance.new_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su << EOF",
      "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.object.key}'>\" >> /var/www/html/index.html",
      "EOF"
    ]
  }


  enabled             = true
  is_ipv6_enabled     = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    viewer_protocol_policy = "redirect-to-https"
  }

  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


# IP
output "IP_of_inst" {
  value = aws_instance.new_instance.public_ip
}