output "jenkins_public_ip" {
  description = "Public IP of Jenkins EC2"
  value       = module.Server.jenkins_public_ip
}