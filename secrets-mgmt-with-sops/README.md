## Secret management in Terraform with Mozilla SOPS tool

This Terraform configuration demonstrates how to deploy an AWS RDS MySQL database using credentials securely stored and managed with SOPS. By integrating SOPS with Terraform, you can maintain secure, encrypted secrets without exposing sensitive information in your infrastructure code.

The MySQL database username and password values are set via variables read from a SOPS-encrypted file. SOPS is an open-source tool from Mozilla for a management of sensitive values in the code. To learn more about SOPS, see [Securing Secrets with SOPS: An Introduction](https://maxat-akbanov.com/securing-secrets-with-sops-an-introduction)

### **Prerequisites:**

1. **SOPS Installation:** Ensure that [SOPS](https://github.com/mozilla/sops) is installed on your machine.

2. **Encryption Keys:** Have your encryption keys set up. SOPS supports various backends like AWS KMS, GCP KMS, Azure Key Vault, or PGP keys. This example uses AWS KMS keys.

To create AWS KMS keys:
```bash
aws kms create-key \
    --region us-east-1 \
    --description "KMS key for encryption" \
    --key-usage ENCRYPT_DECRYPT \
    --origin AWS_KMS \
    --output json
```

To list KMS keys:
```bash
aws kms list-keys --region us-east-1
```

3. **Terraform Installation:** Make sure Terraform is installed and configured on your machine.

**NOTES:**  
- For handling the decryption process of SOPS, this example uses `carlpett/sops` Terraform provider. To learn more about this provider, see [sops](https://registry.terraform.io/providers/carlpett/sops/latest).
- The default encryption process is configured via `.sops.yaml` file. The AWS KMS key is specified in the following format: `- kms: "arn:aws:kms:<region>:<accountNo>:key/<KMS-ID>"`
- The contents of `secrets.enc.json` file is encrypted with AWS KMS key and committed to the repository. To decrypt values from encrypted file with `sops`:
```bash
sops -d secrets.enc.json
```
To be able to decrypt you need to have the corresponging AWS KMS decryption key.

**Directory Structure:**

```
.
├── main.tf
├── variables.tf
├── data.tf
├── resources.tf
├── secrets.enc.json
├── .sops.yaml
├── README.md
```

### `secrets.enc.json`

This file contains your database credentials encrypted with SOPS.

**Before Encryption (`secrets.enc.json`):**

```json
{
  "db_username": "myuser",
  "db_password": "mypassword"
}
```

**Encrypt the File:**

Use SOPS to encrypt the file. Assuming you have your keys set up, run:

```bash
sops -e -i secrets.enc.json
```

After encryption, `secrets.enc.json` will contain encrypted values.

---

### **Running Terraform**

Initialize and apply your Terraform configuration:

```bash
terraform init
terraform apply
```

During the `apply` phase SOPS will use the decryption keys from AWS KMS to read the username and password values.

### **Additional Resources:**
  - [SOPS GitHub Repository](https://github.com/mozilla/sops)
  - [Terraform SOPS Provider Documentation](https://registry.terraform.io/providers/carlpett/sops/latest/docs)