variable "BITBUCKET_PROJECT_KEY" { default = "MET"}
variable "BITBUCKET_REPO_SLUG" { default = "metaspace"}

variable "BITBUCKET_BUILD_NUMBER" { default = "" }
variable "GIT_COMMIT_HASH_SHORT" { default = ""}

variable "IMAGE_PREFIX" {
  default = "artifactory.landcareresearch.co.nz/docker/${lower(BITBUCKET_PROJECT_KEY)}/${BITBUCKET_REPO_SLUG}"
  validation {
    condition     = BITBUCKET_PROJECT_KEY != ""
    error_message = "BITBUCKET_PROJECT_KEY must be set"
  }
  validation {
    condition     = BITBUCKET_REPO_SLUG != ""
    error_message = "BITBUCKET_REPO_SLUG must be set"
  }
}

target default {

    args = {
        BUILD_NUMBER = "${BITBUCKET_BUILD_NUMBER}"
        GIT_COMMIT_ID  = "${GIT_COMMIT_HASH_SHORT}"
    }

    tags = [
      notequal("",GIT_COMMIT_HASH_SHORT) ? "${IMAGE_PREFIX}_geonetwork:${GIT_COMMIT_HASH_SHORT}": "",
      notequal("",BITBUCKET_BUILD_NUMBER) ? "${IMAGE_PREFIX}_geonetwork:build-${BITBUCKET_BUILD_NUMBER}": "",
      "${IMAGE_PREFIX}_geonetwork:latest"
    ]

    cache-from = [
      "type=registry,ref=${IMAGE_PREFIX}_geonetwork:latest"
    ]

    context    = "."
    dockerfile = "Dockerfile"

}
