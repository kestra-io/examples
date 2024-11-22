resource "aws_s3_bucket" "s3" {
  bucket        = "declarative-orchestration"
}


resource "kestra_flow" "uploadCsv" {
  keep_original_source = true
  flow_id              = "upload_csv"
  namespace            = var.namespace
  content              = <<EOF
id: upload_csv
namespace: company.team
tasks:
  - id: csv
    type: io.kestra.plugin.aws.s3.Upload
    region: ${var.region}
    bucket: ${aws_s3_bucket.s3.bucket}
    from: myfile.csv
    key: myfile.csv
EOF
}