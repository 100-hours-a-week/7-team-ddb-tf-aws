locals {
  s3_resources = flatten([
    for arn in values(var.s3_buckets) : [
      arn,
      "${arn}/*"
    ]
  ])
}