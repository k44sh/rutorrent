variable "gitlab"                 { default = "registry.gitlab.com/cyberpnkz/rutorrent" }
variable "github"                 { default = "ghcr.io/k44sh/rutorrent" }
variable "dockerhub"              { default = "docker.io/k44sh/rutorrent" }
variable "source"                 { default = "https://github.com/k44sh/rutorrent" }
variable "CI_PROJECT_TITLE"       { default = "$CI_PROJECT_TITLE" }
variable "CI_PROJECT_URL"         { default = "$CI_PROJECT_URL" }
variable "CI_JOB_STARTED_AT"      { default = "$CI_JOB_STARTED_AT" }
variable "CI_COMMIT_SHA"          { default = "$CI_COMMIT_SHA" }
variable "CI_PROJECT_DESCRIPTION" { default = "$CI_PROJECT_DESCRIPTION" }
variable "tag"                    { default = "$tag" }

group "default" { targets = [ "local" ] }

target "default" {
  cache-from = [
    "type=registry,ref=${dockerhub}:latest",
    "type=registry,ref=${dockerhub}:cache",
    "type=registry,ref=${dockerhub}:edge",
    "type=registry,ref=${dockerhub}:dev"
    ]
  labels    = {
    "org.opencontainers.image.url" = "${source}"
    "org.opencontainers.image.source" = "${source}"
    "org.opencontainers.image.documentation" = "${source}"
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.vendor" = "k44sh"
  }
}

target "local" {
  inherits  = [ "default" ]
  output    = [ "type=docker" ]
  tags      = [ "rutorrent:local" ]
  labels    = { "org.opencontainers.image.version" = "local" }
}

target "registry" {
  inherits  = [ "default" ]
  output    = [ "type=image,push=true" ]
  cache-to  = [ "type=registry,mode=max,ref=${dockerhub}:cache" ]
  labels    = {
    "org.opencontainers.image.title" = "${CI_PROJECT_TITLE}"
    "org.opencontainers.image.created" = "${CI_JOB_STARTED_AT}"
    "org.opencontainers.image.revision" = "${CI_COMMIT_SHA}"
    "org.opencontainers.image.description" = "${CI_PROJECT_DESCRIPTION}"
  }
}

### Pipeline Targets

target "quick" {
  inherits   = [ "registry" ]
  cache-to   = [ "" ]
  tags       = [ "${gitlab}:${CI_COMMIT_SHA}" ]
  labels     = { "org.opencontainers.image.version" = "quick" }
  platforms  = [ "linux/amd64" ]
}

target "prod" {
  inherits  = [ "registry" ]
  tags      = [
    "${gitlab}:${CI_COMMIT_SHA}",
    "${gitlab}:${tag}",
    "${gitlab}:latest",
    "${github}:${tag}",
    "${github}:latest",
    "${dockerhub}:${tag}",
    "${dockerhub}:latest"
  ]
  labels    = { "org.opencontainers.image.version" = "${tag}" }
  platforms = [ 
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
}

target "dev" {
  inherits   = [ "registry" ]
  tags       = [
    "${gitlab}:${CI_COMMIT_SHA}",
    "${gitlab}:dev",
    "${github}:dev",
    "${dockerhub}:dev"
    ]
  labels     = { "org.opencontainers.image.version" = "dev" }
  platforms = [ 
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
}

target "edge" {
  inherits   = [ "registry" ]
  tags       = [
    "${gitlab}:${CI_COMMIT_SHA}",
    "${gitlab}:edge",
    "${github}:edge",
    "${dockerhub}:edge"
  ]
  labels     = { "org.opencontainers.image.version" = "edge" }
  platforms = [ 
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
}

### x86_x64 Targets

target "prod-amd64" {
  inherits  = [ "registry" ]
  cache-from = [
    "type=registry,ref=${dockerhub}:amd64-${tag}",
    "type=registry,ref=${dockerhub}:amd64-latest"
  ]
  tags      = [
    "${gitlab}:amd64-${tag}",
    "${gitlab}:amd64-latest",
    "${github}:amd64-${tag}",
    "${github}:amd64-latest",
    "${dockerhub}:amd64-${tag}",
    "${dockerhub}:amd64-latest"
  ]
  labels    = { "org.opencontainers.image.version" = "${tag}" }
  platforms = [ "linux/amd64" ]
}

target "dev-amd64" {
  inherits   = [ "registry" ]
  cache-from = [ "type=registry,ref=${dockerhub}:amd64-dev" ]
  tags       = [ 
    "${gitlab}:amd64-dev",
    "${github}:amd64-dev",
    "${dockerhub}:amd64-dev"
  ]
  labels     = { "org.opencontainers.image.version" = "dev" }
  platforms  = [ "linux/amd64" ]
}

target "edge-amd64" {
  inherits   = [ "registry" ]
  cache-from = [ "type=registry,ref=${dockerhub}:amd64-edge" ]
  tags       = [ 
    "${gitlab}:amd64-edge",
    "${github}:amd64-edge",
    "${dockerhub}:amd64-edge"
  ]
  labels     = { "org.opencontainers.image.version" = "edge" }
  platforms  = [ "linux/amd64" ]
}

### ARM Targets

target "prod-arm64" {
  inherits   = [ "registry" ]
  cache-from = [
    "type=registry,ref=${dockerhub}:arm64-${tag}",
    "type=registry,ref=${dockerhub}:arm64-latest"
  ]
  tags       = [
    "${gitlab}:arm64-${tag}",
    "${gitlab}:arm64-latest",
    "${github}:arm64-${tag}",
    "${github}:arm64-latest",
    "${dockerhub}:arm64-${tag}",
    "${dockerhub}:arm64-latest"
  ]
  labels     = { "org.opencontainers.image.version" = "${tag}" }
  platforms  = [ "linux/arm64" ]
}

target "prod-armv7" {
  inherits   = [ "registry" ]
  cache-from = [
    "type=registry,ref=${dockerhub}:armv7-${tag}",
    "type=registry,ref=${dockerhub}:armv7-latest"
  ]
  tags       = [
    "${gitlab}:armv7-${tag}",
    "${gitlab}:armv7-latest",
    "${github}:armv7-${tag}",
    "${github}:armv7-latest",
    "${dockerhub}:armv7-${tag}",
    "${dockerhub}:armv7-latest"
  ]
  labels     = { "org.opencontainers.image.version" = "${tag}" }
  platforms  = [ "linux/arm/v7" ]
}

target "dev-arm64" {
  inherits   = [ "registry" ]
  cache-from = [ "type=registry,ref=${dockerhub}:arm64-dev" ]
  tags       = [ 
    "${gitlab}:arm64-dev",
    "${github}:arm64-dev",
    "${dockerhub}:arm64-dev"
  ]
  labels     = { "org.opencontainers.image.version" = "dev" }
  platforms  = [ "linux/arm64" ]
}

target "dev-armv7" {
  inherits   = [ "registry" ]
  cache-from = [ "type=registry,ref=${dockerhub}:armv7-dev" ]
  tags       = [ 
    "${gitlab}:armv7-dev",
    "${github}:armv7-dev",
    "${dockerhub}:armv7-dev"
  ]
  labels     = { "org.opencontainers.image.version" = "dev" }
  platforms  = [ "linux/armv7" ]
}

target "edge-arm64" {
  inherits   = [ "registry" ]
  cache-from = [ "type=registry,ref=${dockerhub}:arm64-edge" ]
  tags       = [ 
    "${gitlab}:arm64-edge",
    "${github}:arm64-edge",
    "${dockerhub}:arm64-edge"
  ]
  labels     = { "org.opencontainers.image.version" = "edge" }
  platforms  = [ "linux/arm64" ]
}

target "edge-armv7" {
  inherits   = [ "registry" ]
  cache-from = [ "type=registry,ref=${dockerhub}:armv7-edge" ]
  tags       = [ 
    "${gitlab}:armv7-edge",
    "${github}:armv7-edge",
    "${dockerhub}:armv7-edge"
  ]
  labels     = { "org.opencontainers.image.version" = "edge" }
  platforms  = [ "linux/arm/v7" ]
}