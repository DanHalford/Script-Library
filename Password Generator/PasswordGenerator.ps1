
# Must be set if the CheckAcceptable option is used.
$openaiKey = ""

<#
.SYNOPSIS
Internal function that generates a random password using the options specified.

.DESCRIPTION
Generates a random password containing uppercase letters, lowercase letters, numbers, and symbols.
The password is generated using a wordlist, and the words are chosen at random. The words are then combined with numbers and symbols to create a password. The password is then checked against the OpenAI API to ensure that the words chosen are appropriate.

.PARAMETER NoUpperCase
Do not include capital letters in the password.

.PARAMETER NoLowerCase
Do not include lowercase letters in the password.

.PARAMETER NoNumbers
Do not include numbers in the password.

.PARAMETER NoSymbols
Do not include symbols in the password.

.PARAMETER ValidSymbols
String containing a list of symbols that can be used in the password.

.PARAMETER WordList
String array of the words the password can be geenrated from.

.PARAMETER CheckAcceptable
Call OpenAI API to check if the random words chosen are appropriate.
#>
Function Get-NewPassword(
        [bool]$NoUpperCase,
        [bool]$NoLowerCase,
        [bool]$NoNumbers,
        [bool]$NoSymbols,
        [string]$ValidSymbols,
        [string[]]$WordList,
        [bool]$CheckAcceptable
) {
    $Block1 = $WordList | Get-Random
    $Block2 = $WordList | Get-Random
    if ($CheckAcceptable) {
        while ((Confirm-PasswordAcceptable -word1 $Block1 -word2 $Block2) -eq $false) {
            $Block1 = $WordList | Get-Random
            $Block2 = $WordList | Get-Random
        }
    }
    
    $Block3 = Get-Random -Minimum 100 -Maximum 9999
    $Block4 = $ValidSymbols.ToCharArray() | Get-Random
    
    $Block1 = $NoUpperCase -eq $true -and $NoLowerCase -eq $false ? $Block1.ToLower() : $Block1.ToUpper()
    $Block2 = $NoUpperCase -eq $false -and $NoLowerCase -eq $true ? $Block2.ToUpper() : $Block2.ToLower()

    $WordParts = @($Block1, $Block2)
    if ($NoNumbers -eq $false) {
        $WordParts += $Block3
    }
    $WordParts = $WordParts | Get-Random -Count $WordParts.Count
    $NewPassword = $NoSymbols -eq $false ? $WordParts -join $Block4 : $WordParts -join ""
    Return $NewPassword
}

<#
.SYNOPSIS
Calls the OpenAI API to check if the random words chosen are appropriate.

.PARAMETER word1
The first word to check.

.PARAMETER word2
The second word to check.

.OUTPUTS
Returns $true if the words are acceptable, $false if they are not, and $null if there is an error.
#>
Function Confirm-PasswordAcceptable() {
    Param(
        [string]$word1,
        [string]$word2
    )
    $systemPrompt = "Answer only 'Acceptable' or 'Unaccaptable', with no additonal explanation."
    $userPrompt = "Consider these two words: $($word1) $($word2). Do the words have any negative connotations, either individually or in conjunction."
    $payload = [ordered]@{
        "model" = "gpt-3.5-turbo"
        "messages" = @(
            @{
                "role" = "system"
                "content" = $systemPrompt
            },
            @{
                "role" = "user"
                "content" = $userPrompt
            }
        )
    }
    $headers = @{
        "Authorization" = "Bearer $($openaiKey)"
        "Content-Type" = "application/json"
    }
    try {
        $response = Invoke-WebRequest -Uri "https://api.openai.com/v1/chat/completions" -Headers $headers -Method POST -Body ($payload | ConvertTo-Json -Depth 4)
        if ($response.StatusCode -eq 200) {
            $reply = $response.Content | ConvertFrom-Json
            if ($reply.choices[0].message.content -eq "Acceptable") {
                return $true
            }
            else {
                return $false
            }
        }
    }
    catch {
        Write-Error "Error sending request: $_"
        Write-Output $_.Exception.Response
        return $null
    }
}

<#
.SYNOPSIS
Generates a random password.

.DESCRIPTION
Generates a random password containing uppercase letters, lowercase letters, numbers, and symbols.
The password is generated using a wordlist and inclusion of different character types is controlled by the parameters.
Optionally, password is then checked against the OpenAI API to ensure that the words chosen are appropriate.

.PARAMETER MinimumLength
Minimum length of the password.

.PARAMETER MaximumLength
Maximum length of the password.

.PARAMETER NoSymbols
Do not include symbols in the password.

.PARAMETER NoUpperCase
Do not include capital letters in the password. Cannot be combined with NoLowerCase.

.PARAMETER NoLowerCase
Do not include lowercase letters in the password. Cannot be combined with NoUpperCase.

.PARAMETER NoNumbers
Do not include numbers in the password.

.PARAMETER WordListPath
Path to the wordlist to use. Default is ./wordlist.txt.

.PARAMETER ValidSymbols
The symbols that can be included in the password. Default is: !@#$%^&*_+-=

.PARAMETER CheckAcceptable
Use OpenAI API to check if the random words chosen are appropriate. The API key must be set in the script if this option is selected.

.EXAMPLE
Get-Password -MinimumLength 15 -MaximumLength 20 -WordListPath "./wordlist.txt" -ValidSymbols "-+=."" -CheckAcceptable

.NOTES
General notes
#>
Function Get-Password() {
    Param(
        [Parameter(HelpMessage = "Minimum length of the password.")]
        [int]$MinimumLength = 15,

        [Parameter(HelpMessage = "Maximum length of the password.")]
        [int]$MaximumLength = 32,

        [Parameter(HelpMessage = "Do not include symbols in the password.")]
        [switch]$NoSymbols = $false,

        [Parameter(HelpMessage = "Do not include capital letters in the password.")]
        [switch]$NoUpperCase = $false,

        [Parameter(HelpMessage = "Do not include lowercase letters in the password.")]
        [switch]$NoLowerCase = $false,

        [Parameter(HelpMessage = "Do not include numbers in the password.")]
        [switch]$NoNumbers = $false,

        [Parameter(HelpMessage = "Path to the wordlist to use.")]
        [string]$WordListPath = "./wordlist.txt",

        [Parameter(HelpMessage = "The symbold that cab be included in the password.")]
        [string]$ValidSymbols = "!@#$%^&*_+-=",

        [Parameter(HelpMessage = "Call OpenAI API to check if the random words chosen are appropriate.")]
        [switch]$CheckAcceptable = $false
    )

    if ($NoUpperCase -and $NoLowerCase) {
        Write-Error -Message "NoUpperCase and NoLowerCase cannot both be set to true."
        Exit
    }
    if ($NoSymbols -and $NoNumbers) {
        Write-Warning -Message "NoSymbols and NoNumbers are both set. This will result in a less secure password."
    }
    if ($MinimumLength -gt $MaximumLength) {
        Write-Error -Message "MinimumLength cannot be greater than MaximumLength."
        Exit
    }
    if ($NoNumbers -eq $false -and $NoSymbols -eq $false -and $MinimumLength -lt 11) {
        Write-Error -Message "MinimumLength cannot be less than 11 with the default settings. To allow shorter passwords, select the NoNumbers or NoSymbols options."
        Exit
    }
    if ($NoNumbers -eq $false -and $NoSymbols -eq $true -and $MinimumLength -lt 9) {
        Write-Error -Message "MinimumLength cannot be less than 9 with the settings specified. To allow shorter passwords, select the NoNumbers option."
        Exit
    }
    if ($CheckAcceptable -eq $true -and $openaiKey -eq "") {
        Write-Error -Message "OpenAI API key is not set. Please set the key in the script."
        Exit
    }
    $WordList = Get-Content -Path $WordListPath
    $NewPassword = Get-NewPassword -NoUpperCase $NoUpperCase -NoLowerCase $NoLowerCase -NoNumbers $NoNumbers -NoSymbols $NoSymbols -ValidSymbols $ValidSymbols -WordList $WordList -CheckAcceptable $CheckAcceptable
    while ($NewPassword.Length -lt $MinimumLength -or $NewPassword.Length -gt $MaximumLength) {
        $NewPassword = Get-NewPassword -NoUpperCase $NoUpperCase -NoLowerCase $NoLowerCase -NoNumbers $NoNumbers -NoSymbols $NoSymbols -ValidSymbols $ValidSymbols -WordList $WordList -CheckAcceptable $CheckAcceptable
    }
    Return $NewPassword
}
