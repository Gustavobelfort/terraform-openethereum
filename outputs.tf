output "OpenEthereum-private_ip" {
  value = aws_instance.ethereum.*.private_ip
}

output "NAT-public_dns" {
  value = aws_instance.nat.public_dns
}

output "Api_Gateway-base_url" {
  value = aws_api_gateway_deployment.openethereum.invoke_url
}
