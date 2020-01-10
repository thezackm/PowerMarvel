#region Top of Script

#requires -Version 3

<#
.SYNOPSIS
    Function to build MD5 hash required by MArvel API

.DESCRIPTION
    https://developer.marvel.com/documentation/authorization
    https://blog.victorsilva.com.uy/marvel-from-powershell/

.EXAMPLE
    ./Get-Character.ps1 -PublicKey 'abcd' -PrivateKey '12345' -Name 'Shadowcat'

.NOTES
    Version:        1.0
    Author:         Zack Mutchler
    Creation Date:  01/09/2019
    Purpose/Change: Initial script development

#>

#endregion

#####-----------------------------------------------------------------------------------------#####

#region Script Parameters

param (
    [ parameter( Mandatory = $true ) ] [ string ] $PublicKey,
    [ parameter( Mandatory = $true ) ] [ string ] $PrivateKey,
    [ parameter( Mandatory = $true ) ] [ string ] $Name
)

#endregion Script Parameters

#####-----------------------------------------------------------------------------------------#####

#region Functions

function New-Hash {
    param (
        [ parameter( Mandatory = $true ) ] [ string ] $PublicKey,
        [ parameter( Mandatory = $true ) ] [ string ] $PrivateKey
    )

    # Make a hash table to hold our results
    [ hashtable ]$return = @{}

    # Build your timespan parameter
    $timeSpan = New-TimeSpan -End ( Get-Date -Year $( ( Get-Date ).Year ) -Month 1 -Day 1 )

    # Add the timeSpan to our results
    $return.timespan = $timeSpan

    # Build the MD5 Hash the Marvel API requires
    $hash = $timeSpan.ToString() + $PrivateKey + $PublicKey
    $string = New-Object System.Text.StringBuilder
    [ System.Security.Cryptography.HashAlgorithm ]::Create( "MD5" ).ComputeHash( [ System.Text.Encoding ]::UTF8.GetBytes( $hash ) ) `
    | ForEach-Object { [ Void ]$string.Append( $_.ToString( "x2" ) ) }

    # Add the md5 Hash to our results
    $return.md5 = $string.ToString()

    Return $return
}

#endregion Functions

#####-----------------------------------------------------------------------------------------#####

#region Execution

# Build our MD5 hash and Timespan
$hash = New-Hash -PublicKey $PublicKey -PrivateKey $PrivateKey

# Build our URL to Query
$characterURL = "https://gateway.marvel.com:443/v1/public/characters?name=$Name&apikey=$PublicKey&hash=$( $hash.md5 )&ts=$( $hash.timespan )"
$characterResponse = Invoke-RestMethod -Method Get -Uri $characterURL
Write-Host "CHARACTER DETAILS:" -ForegroundColor Green
$characterResponse.data.results | Format-List -Property id,name

# //TO-DO// parameterize ComicID based on results of Character Query
$comicsURL = "https://gateway.marvel.com:443/v1/public/comics/64142?apikey=$PublicKey&hash=$( $hash.md5 )&ts=$( $hash.timespan )"
$comicsResponse = Invoke-RestMethod -Method Get -Uri $comicsURL
Write-Host "COMICS DETAILS:" -ForegroundColor Green
$comicsResponse.data.results | Format-List -Property id,title

# //TO-DO// Series, Stories, Events

# //TO-DO// HTML outpus

#endregion Execution
