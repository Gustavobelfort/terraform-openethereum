output "ethereum-private_ip" {
  value = aws_instance.ethereum.*.private_ip
}

output "NAT-public_dns" {
  value = aws_instance.nat.public_dns
}

