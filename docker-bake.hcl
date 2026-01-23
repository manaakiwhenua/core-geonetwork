// docker-bake.hcl for core-geonetwork (MetaSpace)
//
// Build targets for the GeoNetwork/MetaSpace application.
// Variables are provided by the github-workflows docker-build workflow.

variable "REGISTRY_PREFIX" {
  description = "Registry path prefix provided by build workflow"
}

variable "IMAGE_TAG" {
  description = "Image tag provided by build workflow"
}

variable "GIT_ORIGIN" {
  default = ""
}

variable "GIT_REVISION" {
  default = ""
}

// Build all application images
group "default" {
  targets = ["geonetwork"]
}

// Shared configuration
target "_common" {
  platforms = ["linux/amd64"]
  labels = {
    "org.opencontainers.image.source"      = "${GIT_ORIGIN}"
    "org.opencontainers.image.revision"    = "${GIT_REVISION}"
    "org.opencontainers.image.vendor"      = "Manaaki Whenua - Landcare Research"
    "org.opencontainers.image.title"       = "MetaSpace"
    "org.opencontainers.image.description" = "GeoNetwork-based metadata catalogue"
  }
}

// GeoNetwork application
target "geonetwork" {
  inherits   = ["_common"]
  context    = "."
  dockerfile = "Dockerfile"
  tags       = ["${REGISTRY_PREFIX}/geonetwork:${IMAGE_TAG}"]
}
