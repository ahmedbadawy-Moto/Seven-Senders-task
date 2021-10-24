/*output "DNS" {
  value = aws_instance.Web_Server.*.public_dns
}*/

output "aws_vpc_id" {
  value = aws_vpc.WebServer_VPC.id
}
