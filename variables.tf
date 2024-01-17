variable "awsRegion" {
  default = "us-east-1"
}

variable "ami" {
  default = "ami-0005e0cfe09cc9050" # Amazon Linux
}
variable "instanceType" {
  default = "t2.micro"
}

variable "keyName" {
  default = "my-linux-key"
}
