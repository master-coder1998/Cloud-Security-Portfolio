# Test cases for Terraform security policies

package terraform

# Test: S3 bucket without encryption should be denied
test_s3_encryption_required {
    deny["S3 bucket 'test-bucket' must have encryption enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [{
                    "type": "aws_s3_bucket",
                    "name": "test-bucket",
                    "values": {}
                }]
            }
        }
    }
}

# Test: Security group allowing SSH from 0.0.0.0/0 should be denied
test_sg_ssh_from_anywhere {
    deny["Security group 'test-sg' allows SSH (port 22) from 0.0.0.0/0"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [{
                    "type": "aws_security_group",
                    "name": "test-sg",
                    "values": {
                        "ingress": [{
                            "cidr_blocks": ["0.0.0.0/0"],
                            "from_port": 22,
                            "to_port": 22
                        }]
                    }
                }]
            }
        }
    }
}

# Test: RDS without encryption should be denied
test_rds_encryption_required {
    deny["RDS instance 'test-db' must have storage encryption enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [{
                    "type": "aws_db_instance",
                    "name": "test-db",
                    "values": {
                        "storage_encrypted": false
                    }
                }]
            }
        }
    }
}

# Test: Public RDS should be denied
test_rds_not_public {
    deny["RDS instance 'test-db' must not be publicly accessible"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [{
                    "type": "aws_db_instance",
                    "name": "test-db",
                    "values": {
                        "publicly_accessible": true
                    }
                }]
            }
        }
    }
}

# Test: IAM policy with wildcard should be denied
test_iam_wildcard_denied {
    deny["IAM policy 'test-policy' grants wildcard (*) permissions"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [{
                    "type": "aws_iam_policy",
                    "name": "test-policy",
                    "values": {
                        "policy": "{\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
                    }
                }]
            }
        }
    }
}

# Test: Resources without required tags should warn
test_missing_tags_warning {
    warn["Resource 'aws_instance.test' is missing required tags (Environment, Owner, Project)"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [{
                    "type": "aws_instance",
                    "address": "aws_instance.test",
                    "values": {
                        "tags": {}
                    }
                }]
            }
        }
    }
}
