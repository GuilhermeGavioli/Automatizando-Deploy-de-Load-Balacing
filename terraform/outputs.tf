output "proxy_id" {
	value = aws_instance.proxy-server.id
}

output "proxy-private-ip" {
	value = aws_instance.proxy-server.private_ip
}

output "proxy_eip" {
	value = aws_eip.proxy-eip.public_ip
}

output "web-server-private-ips" {
	value = [for instance in aws_instance.web-server : instance.private_ip]
}

