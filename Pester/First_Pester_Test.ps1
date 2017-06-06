# Import the new NITRO Module
Remove-Module -Name NitroModule
#Import-Module C:\GitHub\PS-NITRO\NitroModule

# Check the number of Functions in the Module
#(Get-Command -Module NitroModule).Count

# Import the Pester Module
Import-Module Pester

# Check available commands within the Pester Module
#Get-Command -Module Pester

# Check Get-Help properties for the NITRO Module Functions
# source: http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

Describe "NitroModule" -Tags "Module" {
    
    # Import the new NITRO Module
    Import-Module C:\GitHub\PS-NITRO\NitroModule
    
    # Retrieve all functions from the Module
    $FunctionsList = (get-command -Module NitroModule | Where-Object -FilterScript { $_.CommandType -eq 'Function' }).Name
    
    FOREACH ($Function in $FunctionsList)
    {
        # Retrieve the Help of the function
        $Help = Get-Help -Name $Function -Full
        
#        $Notes = ($Help.alertSet.alert.text -split '\n')
        
        # Parse the function using AST
        $AST = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content function:$Function), [ref]$null, [ref]$null)
        
        Context "$Function - Help"{
            
            It "Synopsis"{ $help.Synopsis | Should not BeNullOrEmpty }
            It "Description"{ $help.Description | Should not BeNullOrEmpty }
#            It "Link" { $help.Link | Should Be "http://www.cognitionit.com" }
#            It "Notes - Name" { $Notes[0].trim() | Should Be $Function }
#            It "Notes - Author" { $Notes[1].trim() | Should Be "Esther Barthel, MSc" }
#            It "Notes - Twitter" { $Notes[2].trim() | Should Be "@cognitionit_com" }
#            It "Notes - Github" { $Notes[3].trim() | Should Be "github.com/cognitionit" }
            
            # Get the parameters declared in the Comment Based Help
            $RiskMitigationParameters = 'Whatif', 'Confirm'
            $HelpParameters = $help.parameters.parameter | Where-Object name -NotIn $RiskMitigationParameters
            
            # Get the parameters declared in the AST PARAM() Block
            $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath
            
            $FunctionsList = (get-command -Module $ModuleName | Where-Object -FilterScript { $_.CommandType -eq 'Function' }).Name
            
            
            
            
            It "Parameter - Compare Count Help/AST" {
                $HelpParameters.name.count -eq $ASTParameters.count | Should Be $true
            }
            
            # Parameter Description
            If (-not [String]::IsNullOrEmpty($ASTParameters)) # IF ASTParameters are found
            {
                $HelpParameters | ForEach-Object {
                    It "Parameter $($_.Name) - Should contains description"{
                        $_.description | Should not BeNullOrEmpty
                    }
                }
                
            }
            
            # Examples
            it "Example - Count should be greater than 0"{
                $Help.examples.example.code.count | Should BeGreaterthan 0
            }
            
            # Examples - Remarks (small description that comes with the example)
            foreach ($Example in $Help.examples.example)
            {
                it "Example - Remarks on $($Example.Title)"{
                    $Example.remarks | Should not BeNullOrEmpty
                }
            }
        }
    }
}
