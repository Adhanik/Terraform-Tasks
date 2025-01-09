
## Cloud Native tools

Some of the cloud native tools used for creating infrastructure on cloud are -

- AWS - Cloud Formation Template
- Azure - ARM
- GCP = Deployment Manager

## Disadvantages of working with Cloud Native tools

1. The problem with these cloud native tools is that all the configuration for creating infras (VPC, S.G, EC2, IAM) are kept in a single jSON/YAML file, which leads to complexity while debugging and is not very readable.

2. Also, the above tools work with their specific cloud provider only. 

3. Modules and workspace concept is not in AWS, Azure

# Terraform

Terraform has the following products -

- Packer - Image automation
- consul - cluster and service Discovery
- vault - secrets management


## Setting up provider

The next thing we will do is install TF. For this, we need to initialise a TF working dir using terraform init. 

## Creating a VPC

We will be creating VPC, Subnets, Route Table, IGW, and Security Groups.

1. The first feature we want is `Enable DNS Hostname`
enable_dns_hostnames - (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false.

2. Next we will create IGW, and attach it to the VPC we created above.

3. Next we will create Subnet.

### Subnet - Public vs Private

Terraform itself does not automatically determine whether a subnet or a route table is "public" or "private." These distinctions are based on the resources and configurations you explicitly provide. Here's how to create and distinguish public and private subnets and route tables in AWS using Terraform:

---

#### **Public Subnet**
A subnet is considered "public" if it is associated with a route table that has a route to the Internet via an **Internet Gateway (IGW)**.

1. **Your Subnet Definition**:
   The subnet you created does not inherently know it is public. It's the route table association and the route to the Internet Gateway that make it public.

   ```hcl
   resource "aws_subnet" "Public-subnet" {
     vpc_id     = aws_vpc.amit-terraform.id
     cidr_block = "10.0.1.0/24"

     tags = {
       Name = "Public-Subnet"
     }
   }
   ```

2. **Route Table**:
   Your route table defines it as "public" because you explicitly added a route to `0.0.0.0/0` via an **Internet Gateway**.

   ```hcl
   resource "aws_route_table" "Public-RouteTable" {
     vpc_id = aws_vpc.amit-terraform.id

     route {
       cidr_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.IGW-terraform.id
     }

     tags = {
       Name    = "Public-RouteTable"
       Service = "Terraform"
     }
   }
   ```

3. **Association**:
   The `aws_route_table_association` links the public route table to the subnet, making the subnet public.

   ```hcl
   resource "aws_route_table_association" "public-routetable-association" {
     subnet_id      = aws_subnet.Public-subnet.id
     route_table_id = aws_route_table.Public-RouteTable.id
   }
   ```

---

#### **Private Subnet**

We have not create a private subnet yet. A subnet is considered "private" if it does not have a direct route to the Internet (i.e., no route to an Internet Gateway). Instead, private subnets typically have a route to a **NAT Gateway** or **NAT Instance** for outbound Internet access.

1. **Private Subnet**:
   ```hcl
   resource "aws_subnet" "Private-subnet" {
     vpc_id     = aws_vpc.amit-terraform.id
     cidr_block = "10.0.2.0/24"

     tags = {
       Name = "Private-Subnet"
     }
   }
   ```

2. **Private Route Table**:
   The private route table will have a route to the NAT Gateway or NAT Instance for outbound Internet traffic.

   ```hcl
   resource "aws_route_table" "Private-RouteTable" {
     vpc_id = aws_vpc.amit-terraform.id

     route {
       cidr_block = "0.0.0.0/0"
       nat_gateway_id = aws_nat_gateway.NAT-terraform.id
     }

     tags = {
       Name    = "Private-RouteTable"
       Service = "Terraform"
     }
   }
   ```

3. **Association**:
   Link the private route table to the private subnet.

   ```hcl
   resource "aws_route_table_association" "private-routetable-association" {
     subnet_id      = aws_subnet.Private-subnet.id
     route_table_id = aws_route_table.Private-RouteTable.id
   }
   ```

---


4. Next we will create a Public Route Table. Since its public, we will be routing it to Internet using - cidr_block = "0.0.0.0/0"

When we create a route table, we need to create subnet association as well with it, which we will create using - Resource: aws_route_table_association

Since this is public route table, we will add our public subent to this route table.


5. Next we will create Security Group. Ingress means inbound, and egress means outbound. We have separately defined Ingress and egress, instead of using resource block for them.

## Creating resources

Next, we will create these resources on AWS

terraform init, terraform fmt, terraform validate, terraform plan, terraform apply


### **Key Points to Remember**

1. **Subnets**:
   - Subnets themselves are not inherently public or private. Their classification depends on their route table's configuration.

2. **Route Tables**:
   - A public route table must have a route to an Internet Gateway (`gateway_id`).
   - A private route table typically has a route to a NAT Gateway (`nat_gateway_id`) but no route to an Internet Gateway.

3. **Internet Gateway**:
   - Required for public subnets to enable direct Internet access.

   ```hcl
   resource "aws_internet_gateway" "IGW-terraform" {
     vpc_id = aws_vpc.amit-terraform.id

     tags = {
       Name = "Internet-Gateway"
     }
   }
   ```

4. **NAT Gateway** (for private subnets):
   - Required for private subnets to access the Internet indirectly.
   - Place the NAT Gateway in a public subnet.

   ```hcl
   resource "aws_nat_gateway" "NAT-terraform" {
     allocation_id = aws_eip.NAT-eip.id
     subnet_id     = aws_subnet.Public-subnet.id

     tags = {
       Name = "NAT-Gateway"
     }
   }
   ```

5. **Elastic IP (EIP)**:
   - Needed for the NAT Gateway.

   ```hcl
   resource "aws_eip" "NAT-eip" {
     vpc = true
   }
   ```

---