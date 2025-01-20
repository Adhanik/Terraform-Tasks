
data "aws_vpc" "datavpc" {
  id = "vpc-01fb7b7e6dfa92c9b"
}

resource "aws_internet_gateway" "datasource-IGW" {
  vpc_id = data.aws_vpc.datavpc.id

  tags = {
    Name = "datasource-IGW"
  }
}

