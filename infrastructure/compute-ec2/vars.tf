variable "region" {
  default = "us-east-1"
}

variable "zone" {
  default = "us-east-1a"
}

variable "amiID" {
  type = map(any)
  default = {
    us-east-1 = "ami-0c02fb55956c7d316" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
    us-west-2 = "ami-0b2f6494ff0b07a0e" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
  }

}

variable "web_user" {
  default = "ubuntu"

}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "jettoner.xyz"
}

variable "create_api_subdomain" {
  description = "Whether to create api subdomain"
  type        = bool
  default     = false
}