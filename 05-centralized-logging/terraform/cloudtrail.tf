resource "aws_cloudtrail" "organization_trail" {
  name                          = "org-organization-trail"
  s3_bucket_name                = aws_s3_bucket.log_archive.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = true
}
