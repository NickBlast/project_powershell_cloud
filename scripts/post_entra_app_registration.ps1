<# 
.DESCRIPTION
The purpose of this script is to create a new application registration in Entra ID for external application use to connect to azure or m365 services via graph api. We need to achive the following tasks in the first iteration of this script: ( The form should pop up in front of all open windows and should be user friendly )
1. Prompt the user to input the following information via a windows form:
    - Business application id (from ServiceNow CMDB) : AKA = AppId
    - Environment (dv = Development, qa = QA, ut = UAT, pd = production) : AKA = Env
    - Scope (m365 = Microsoft 365, tnr, mg = management group, sub = subscription, rg = resource group) : AKA = Scope
    - Business application name abbreviation (from ServiceNow CMDB) : AKA = AppName
    - Access level (read, write, admin) : AKA = Access
    - Description of the application and the purpose of the registration
    - Redirect URI (for web applications) - optional

2. Construct the name of the application registration using the provided inputs in the following format:
   <appId>-<env>-<scope>-<appName>-<access>

3. Create the application registration in Entra ID with the constructed name and provided description and redirect URI (if applicable).
#>

# Import necessary modules
Import-Module "$PSScriptRoot/../modules/entra_connection/entra_connection.psd1" -Force
Import-Module "$PSScriptRoot/../modules/logging/logging.psd1" -Force    
Import-Module Microsoft.Graph

# Function to create a Windows Form for user input
function CreateAppRegistrationForm {
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Entra App Registration"
    $form.Size = New-Object System.Drawing.Size(400, 500)
    $form.StartPosition = "CenterScreen"

    # Define labels and textboxes for each input
    $labels = @("Business Application ID (AppId):", "Environment (dv, qa, ut, pd):", "Scope (m365, tnr, mg, sub, rg):", "Business Application Name Abbreviation (AppName):", "Access Level (read, write, admin):", "Description:", "Redirect URI (optional):")
    $textboxes = @()

    for ($i = 0; $i -lt $labels.Count; $i++) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $labels[$i]
        $label.Location = New-Object System.Drawing.Point(10, 20 + ($i * 50))
        $label.Size = New-Object System.Drawing.Size(360, 20)
        $form.Controls.Add($label)

        $textbox = New-Object System.Windows.Forms.TextBox
        $textbox.Location = New-Object System.Drawing.Point(10, 40 + ($i * 50))
        $textbox.Size = New-Object System.Drawing.Size(360, 20)
        if ($i -eq 5) { # Description textbox should be multiline
            $textbox.Multiline = $true
            $textbox.Height = 60
        }
        $form.Controls.Add($textbox)
        $textboxes += $textbox
    }

    # Add Submit button
    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Submit"
    $submitButton.Location = New-Object System.Drawing.Point(150, 420)
    $submitButton.Add_Click({
        $form.Tag = @(
            $textboxes[0].Text,
            $textboxes[1].Text,
            $textboxes[2].Text,
            $textboxes[3].Text,
            $textboxes[4].Text,
            $textboxes[5].Text,
            $textboxes[6].Text
        )
        $form.Close()
    })
    $form.Controls.Add($submitButton)
    
    $form.Topmost = $true
    $form.Add_Shown({$form.Activate()})
    [void]$form.ShowDialog()

    return $form.Tag
}