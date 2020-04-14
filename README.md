A few Usage notes: 

1. You must manually Must [manually](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account#creating-a-run-as-account-in-azure-portal) add an Azure Run as Account to the automation account after creation (not supported in Terraform)

2. After creating the RunAsAccount in Azure, add a variable, `var.run_as_account_sp_object_id`, set to the 
object ID of the run as account service principal created in step 1 and run `terraform apply`. Or just manually add an access policy for certificate 
management to the Key Vault for the run as service principal.

3. Ofen, some modules will fail to import to the Automation Account. To fix this, you must manually delete the modules that failed to import from the Automation Account, and rerun `terraform apply`. This re-running of apply can be combined with the above, provided that the creation made it far enough that the automation account exists.

This project was inspired from the below article. Most of the powershell in this repository started out 
as something from this [project](https://medium.com/@brentrobinson5/automating-certificate-management-with-azure-and-lets-encrypt-fee6729e2b78).
