locals {
  s3_buckets = {
    "${module.loki_backup.bucket_name}"   = module.loki_backup.bucket_arn
    "${module.thanos_backup.bucket_name}" = module.thanos_backup.bucket_arn
  }
}
