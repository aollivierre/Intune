function ConvertTo-JsonLiteral { 
    <#
    .SYNOPSIS
    Converts an object to a JSON-formatted string.

    .DESCRIPTION
    The ConvertTo-Json cmdlet converts any object to a string in JavaScript Object Notation (JSON) format. The properties are converted to field names, the field values are converted to property values, and the methods are removed.

    .PARAMETER Object
    Specifies the objects to convert to JSON format. Enter a variable that contains the objects, or type a command or expression that gets the objects. You can also pipe an object to ConvertTo-JsonLiteral

    .PARAMETER Depth
    Specifies how many levels of contained objects are included in the JSON representation. The default value is 0.

    .PARAMETER AsArray
    Outputs the object in array brackets, even if the input is a single object.

    .PARAMETER DateTimeFormat
    Changes DateTime string format. Default "yyyy-MM-dd HH:mm:ss"

    .PARAMETER NumberAsString
    Provides an alternative serialization option that converts all numbers to their string representation.

    .PARAMETER BoolAsString
    Provides an alternative serialization option that converts all bool to their string representation.

    .PARAMETER PropertyName
    Uses PropertyNames provided by user (only works with Force)

    .PARAMETER NewLineFormat
    Provides a way to configure how new lines are converted for property names

    .PARAMETER NewLineFormatProperty
    Provides a way to configure how new lines are converted for values

    .PARAMETER PropertyName
    Allows passing property names to be used for custom objects (hashtables and alike are unaffected)

    .PARAMETER ArrayJoin
    Forces any array to be a string regardless of depth level

    .PARAMETER ArrayJoinString
    Uses defined string or char for array join. By default it uses comma with a space when used.

    .PARAMETER Force
    Forces using property names from first object or given thru PropertyName parameter

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -Depth 3

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -NewLineFormat $NewLineFormat = @{
        NewLineCarriage = '\r\n'
        NewLine         = "\n"
        Carriage        = "\r"
    } -NumberAsString -BoolAsString

    .EXAMPLE
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -NumberAsString -BoolAsString -DateTimeFormat "yyyy-MM-dd HH:mm:ss"

    .EXAMPLE
    # Keep in mind this advanced replace will break ConvertFrom-Json, but it's sometimes useful for projects like PSWriteHTML
    Get-Process | Select-Object -First 2 | ConvertTo-JsonLiteral -NewLineFormat $NewLineFormat = @{
        NewLineCarriage = '\r\n'
        NewLine         = "\n"
        Carriage        = "\r"
    } -NumberAsString -BoolAsString -AdvancedReplace @{ '.' = '\.'; '$' = '\$' }

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param([alias('InputObject')][Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0, Mandatory)][Array] $Object,
        [int] $Depth,
        [switch] $AsArray,
        [string] $DateTimeFormat = "yyyy-MM-dd HH:mm:ss",
        [switch] $NumberAsString,
        [switch] $BoolAsString,
        [System.Collections.IDictionary] $NewLineFormat = @{NewLineCarriage = '\r\n'
            NewLine                                                         = "\n"
            Carriage                                                        = "\r"
        },
        [System.Collections.IDictionary] $NewLineFormatProperty = @{NewLineCarriage = '\r\n'
            NewLine                                                                 = "\n"
            Carriage                                                                = "\r"
        },
        [System.Collections.IDictionary] $AdvancedReplace,
        [string] $ArrayJoinString,
        [switch] $ArrayJoin,
        [string[]]$PropertyName,
        [switch] $Force)
    Begin {
        $TextBuilder = [System.Text.StringBuilder]::new()
        $CountObjects = 0
        filter IsNumeric() { return $_ -is [byte] -or $_ -is [int16] -or $_ -is [int32] -or $_ -is [int64] -or $_ -is [sbyte] -or $_ -is [uint16] -or $_ -is [uint32] -or $_ -is [uint64] -or $_ -is [float] -or $_ -is [double] -or $_ -is [decimal] }
        filter IsOfType() { return $_ -is [bool] -or $_ -is [char] -or $_ -is [datetime] -or $_ -is [string] -or $_ -is [timespan] -or $_ -is [URI] -or $_ -is [byte] -or $_ -is [int16] -or $_ -is [int32] -or $_ -is [int64] -or $_ -is [sbyte] -or $_ -is [uint16] -or $_ -is [uint32] -or $_ -is [uint64] -or $_ -is [float] -or $_ -is [double] -or $_ -is [decimal] }
        [int] $MaxDepth = $Depth
        [int] $InitialDepth = 0
    }
    Process {
        for ($a = 0; $a -lt $Object.Count; $a++) {
            $CountObjects++
            if ($CountObjects -gt 1) { $null = $TextBuilder.Append(',') }
            if ($Object[$a] -is [System.Collections.IDictionary]) {
                $null = $TextBuilder.AppendLine("{")
                for ($i = 0; $i -lt ($Object[$a].Keys).Count; $i++) {
                    $Property = ([string[]]$Object[$a].Keys)[$i]
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $Value = ConvertTo-StringByType -Value $Object[$a][$Property] -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $InitialDepth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -Force:$Force -ArrayJoin:$ArrayJoin -ArrayJoinString $ArrayJoinString -AdvancedReplace $AdvancedReplace
                    $null = $TextBuilder.Append("$Value")
                    if ($i -ne ($Object[$a].Keys).Count - 1) { $null = $TextBuilder.AppendLine(',') }
                }
                $null = $TextBuilder.Append("}")
            } elseif ($Object[$a] | IsOfType) {
                $Value = ConvertTo-StringByType -Value $Object[$a] -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $InitialDepth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -Force:$Force -ArrayJoin:$ArrayJoin -ArrayJoinString $ArrayJoinString -AdvancedReplace $AdvancedReplace
                $null = $TextBuilder.Append($Value)
            } else {
                $null = $TextBuilder.AppendLine("{")
                if ($Force -and -not $PropertyName) { $PropertyName = $Object[0].PSObject.Properties.Name } elseif ($Force -and $PropertyName) {} else { $PropertyName = $Object[$a].PSObject.Properties.Name }
                $PropertyCount = 0
                foreach ($Property in $PropertyName) {
                    $PropertyCount++
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $Value = ConvertTo-StringByType -Value $Object[$a].$Property -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $InitialDepth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -NewLineFormat $NewLineFormat -NewLineFormatProperty $NewLineFormatProperty -Force:$Force -ArrayJoin:$ArrayJoin -ArrayJoinString $ArrayJoinString -AdvancedReplace $AdvancedReplace
                    $null = $TextBuilder.Append("$Value")
                    if ($PropertyCount -ne $PropertyName.Count) { $null = $TextBuilder.AppendLine(',') }
                }
                $null = $TextBuilder.Append("}")
            }
            $InitialDepth = 0
        }
    }
    End { if ($CountObjects -gt 1 -or $AsArray) { "[$($TextBuilder.ToString())]" } else { $TextBuilder.ToString() } }
}
function Remove-EmptyValue { 
    [alias('Remove-EmptyValues')]
    [CmdletBinding()]
    param([alias('Splat', 'IDictionary')][Parameter(Mandatory)][System.Collections.IDictionary] $Hashtable,
        [string[]] $ExcludeParameter,
        [switch] $Recursive,
        [int] $Rerun,
        [switch] $DoNotRemoveNull,
        [switch] $DoNotRemoveEmpty,
        [switch] $DoNotRemoveEmptyArray,
        [switch] $DoNotRemoveEmptyDictionary)
    foreach ($Key in [string[]] $Hashtable.Keys) { if ($Key -notin $ExcludeParameter) { if ($Recursive) { if ($Hashtable[$Key] -is [System.Collections.IDictionary]) { if ($Hashtable[$Key].Count -eq 0) { if (-not $DoNotRemoveEmptyDictionary) { $Hashtable.Remove($Key) } } else { Remove-EmptyValue -Hashtable $Hashtable[$Key] -Recursive:$Recursive } } else { if (-not $DoNotRemoveNull -and $null -eq $Hashtable[$Key]) { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmpty -and $Hashtable[$Key] -is [string] -and $Hashtable[$Key] -eq '') { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmptyArray -and $Hashtable[$Key] -is [System.Collections.IList] -and $Hashtable[$Key].Count -eq 0) { $Hashtable.Remove($Key) } } } else { if (-not $DoNotRemoveNull -and $null -eq $Hashtable[$Key]) { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmpty -and $Hashtable[$Key] -is [string] -and $Hashtable[$Key] -eq '') { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmptyArray -and $Hashtable[$Key] -is [System.Collections.IList] -and $Hashtable[$Key].Count -eq 0) { $Hashtable.Remove($Key) } } } }
    if ($Rerun) { for ($i = 0; $i -lt $Rerun; $i++) { Remove-EmptyValue -Hashtable $Hashtable -Recursive:$Recursive } }
}
function ConvertTo-StringByType { 
    <#
    .SYNOPSIS
    Private function to use within ConvertTo-JsonLiteral

    .DESCRIPTION
    Private function to use within ConvertTo-JsonLiteral

    .PARAMETER Value
    Value to convert to JsonValue

     .PARAMETER Depth
    Specifies how many levels of contained objects are included in the JSON representation. The default value is 0.

    .PARAMETER AsArray
    Outputs the object in array brackets, even if the input is a single object.

    .PARAMETER DateTimeFormat
    Changes DateTime string format. Default "yyyy-MM-dd HH:mm:ss"

    .PARAMETER NumberAsString
    Provides an alternative serialization option that converts all numbers to their string representation.

    .PARAMETER BoolAsString
    Provides an alternative serialization option that converts all bool to their string representation.

    .PARAMETER PropertyName
    Uses PropertyNames provided by user (only works with Force)

    .PARAMETER ArrayJoin
    Forces any array to be a string regardless of depth level

    .PARAMETER ArrayJoinString
    Uses defined string or char for array join. By default it uses comma with a space when used.

    .PARAMETER Force
    Forces using property names from first object or given thru PropertyName parameter

    .EXAMPLE
    $Value = ConvertTo-StringByType -Value $($Object[$a][$i]) -DateTimeFormat $DateTimeFormat

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param([Object] $Value,
        [int] $Depth,
        [int] $MaxDepth,
        [string] $DateTimeFormat,
        [switch] $NumberAsString,
        [switch] $BoolAsString,
        [System.Collections.IDictionary] $NewLineFormat = @{NewLineCarriage = '\r\n'
            NewLine                                                         = "\n"
            Carriage                                                        = "\r"
        },
        [System.Collections.IDictionary] $NewLineFormatProperty = @{NewLineCarriage = '\r\n'
            NewLine                                                                 = "\n"
            Carriage                                                                = "\r"
        },
        [System.Collections.IDictionary] $AdvancedReplace,
        [System.Text.StringBuilder] $TextBuilder,
        [string[]] $PropertyName,
        [switch] $ArrayJoin,
        [string] $ArrayJoinString,
        [switch] $Force)
    Process {
        if ($null -eq $Value) { "`"`"" } elseif ($Value -is [string]) {
            $Value = $Value.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormat.NewLineCarriage).Replace("`n", $NewLineFormat.NewLine).Replace("`r", $NewLineFormat.Carriage)
            foreach ($Key in $AdvancedReplace.Keys) { $Value = $Value.Replace($Key, $AdvancedReplace[$Key]) }
            "`"$Value`""
        } elseif ($Value -is [DateTime]) { "`"$($($Value).ToString($DateTimeFormat))`"" } elseif ($Value -is [bool]) { if ($BoolAsString) { "`"$($Value)`"" } else { $Value.ToString().ToLower() } } elseif ($Value -is [System.Collections.IDictionary]) {
            if ($MaxDepth -eq 0 -or $Depth -eq $MaxDepth) { "`"$($Value)`"" } else {
                $Depth++
                $null = $TextBuilder.AppendLine("{")
                for ($i = 0; $i -lt ($Value.Keys).Count; $i++) {
                    $Property = ([string[]]$Value.Keys)[$i]
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $OutputValue = ConvertTo-StringByType -Value $Value[$Property] -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $Depth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -Force:$Force -ArrayJoinString $ArrayJoinString
                    $null = $TextBuilder.Append("$OutputValue")
                    if ($i -ne ($Value.Keys).Count - 1) { $null = $TextBuilder.AppendLine(',') }
                }
                $null = $TextBuilder.Append("}")
            }
        } elseif ($Value -is [System.Collections.IList] -or $Value -is [System.Collections.ReadOnlyCollectionBase]) {
            if ($ArrayJoin) {
                $Value = $Value -join $ArrayJoinString
                $Value = "$Value".Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                "`"$Value`""
            } else {
                if ($MaxDepth -eq 0 -or $Depth -eq $MaxDepth) {
                    $Value = "$Value".Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    "`"$Value`""
                } else {
                    $CountInternalObjects = 0
                    $null = $TextBuilder.Append("[")
                    foreach ($V in $Value) {
                        $CountInternalObjects++
                        if ($CountInternalObjects -gt 1) { $null = $TextBuilder.Append(',') }
                        if ($Force -and -not $PropertyName) { $PropertyName = $V.PSObject.Properties.Name } elseif ($Force -and $PropertyName) {} else { $PropertyName = $V.PSObject.Properties.Name }
                        $OutputValue = ConvertTo-StringByType -Value $V -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $Depth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -Force:$Force -PropertyName $PropertyName -ArrayJoinString $ArrayJoinString
                        $null = $TextBuilder.Append($OutputValue)
                    }
                    $null = $TextBuilder.Append("]")
                }
            }
        } elseif ($Value -is [System.Enum]) { "`"$($($Value).ToString())`"" } elseif (($Value | IsNumeric) -eq $true) {
            $Value = $($Value).ToString().Replace(',', '.')
            if ($NumberAsString) { "`"$Value`"" } else { $Value }
        } elseif ($Value -is [PSObject]) {
            if ($MaxDepth -eq 0 -or $Depth -eq $MaxDepth) { "`"$($Value)`"" } else {
                $Depth++
                $CountInternalObjects = 0
                $null = $TextBuilder.AppendLine("{")
                if ($Force -and -not $PropertyName) { $PropertyName = $Value.PSObject.Properties.Name } elseif ($Force -and $PropertyName) {} else { $PropertyName = $Value.PSObject.Properties.Name }
                foreach ($Property in $PropertyName) {
                    $CountInternalObjects++
                    if ($CountInternalObjects -gt 1) { $null = $TextBuilder.AppendLine(',') }
                    $DisplayProperty = $Property.Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
                    $null = $TextBuilder.Append("`"$DisplayProperty`":")
                    $OutputValue = ConvertTo-StringByType -Value $Value.$Property -DateTimeFormat $DateTimeFormat -NumberAsString:$NumberAsString -BoolAsString:$BoolAsString -Depth $Depth -MaxDepth $MaxDepth -TextBuilder $TextBuilder -Force:$Force -ArrayJoinString $ArrayJoinString
                    $null = $TextBuilder.Append("$OutputValue")
                }
                $null = $TextBuilder.Append("}")
            }
        } else {
            $Value = $Value.ToString().Replace('\', "\\").Replace('"', '\"').Replace([System.Environment]::NewLine, $NewLineFormatProperty.NewLineCarriage).Replace("`n", $NewLineFormatProperty.NewLine).Replace("`r", $NewLineFormatProperty.Carriage)
            "`"$Value`""
        }
    }
}
function Add-TeamsBody {
    [CmdletBinding()]
    param (
        [string] $MessageTitle,
        [string] $ThemeColor,
        [string] $MessageText,
        [string] $MessageSummary,
        [System.Collections.IDictionary[]] $Sections,
        [switch] $HideOriginalBody
    )

    $Body = [ordered] @{
        sections = $Sections
    }
    if ($ThemeColor) {
        $body.themeColor = $ThemeColor
    }
    if ($MessageTitle) {
        $Body.title = $MessageTitle
    }
    if ($HideOriginalBody.IsPresent) {
        $Body.hideOriginalBody = $HideOriginalBody.IsPresent
    }
    if ($MessageSummary -ne '') {
        $Body.summary = $MessageSummary
    } else {
        if ($MessageTitle -ne '') {
            $Body.summary = $MessageTitle
        } elseif ($MessageText -ne '') {
            $Body.summary = $MessageText
        }
    }
    if ($MessageText -ne '') {
        $Body.text = $MessageText
    }
    return $Body | ConvertTo-Json -Depth 6
}
function Convert-Color {
    <#
    .Synopsis
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
    .Description
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
    .Parameter RBG
    Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
    .Parameter HEX
    Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
    .Example
    .\convert-color -hex FFFFFF
    Converts hex value FFFFFF to RGB

    .Example
    .\convert-color -RGB 123,200,255
    Converts Red = 123 Green = 200 Blue = 255 to Hex value

    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "RGB", Position = 0)]
        [ValidateScript( { $_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$' })]
        $RGB,
        [Parameter(ParameterSetName = "HEX", Position = 0)]
        [ValidateScript( { $_ -match '[A-Fa-f0-9]{6}' })]
        [string]
        $HEX
    )
    switch ($PsCmdlet.ParameterSetName) {
        "RGB" {
            if ($null -eq $RGB[2]) {
                Write-Error "Value missing. Please enter all three values seperated by comma."
            }
            $red = [convert]::Tostring($RGB[0], 16)
            $green = [convert]::Tostring($RGB[1], 16)
            $blue = [convert]::Tostring($RGB[2], 16)
            if ($red.Length -eq 1) {
                $red = '0' + $red
            }
            if ($green.Length -eq 1) {
                $green = '0' + $green
            }
            if ($blue.Length -eq 1) {
                $blue = '0' + $blue
            }
            Write-Output $red$green$blue
        }
        "HEX" {
            $red = $HEX.Remove(2, 4)
            $Green = $HEX.Remove(4, 2)
            $Green = $Green.remove(0, 2)
            $Blue = $hex.Remove(0, 4)
            $Red = [convert]::ToInt32($red, 16)
            $Green = [convert]::ToInt32($green, 16)
            $Blue = [convert]::ToInt32($blue, 16)
            Write-Output $red, $Green, $blue
        }
    }
}
function ConvertFrom-Color {
    [alias('Convert-FromColor')]
    [CmdletBinding()]
    param (
        [ValidateScript( {
                if ($($_ -in $Script:RGBColors.Keys -or $_ -match "^#([A-Fa-f0-9]{6})$" -or $_ -eq "") -eq $false) {
                    throw "The Input value is not a valid colorname nor an valid color hex code."
                } else { $true }
            })]
        [alias('Colors')][string[]] $Color,
        [switch] $AsDecimal
    )
    $Colors = foreach ($C in $Color) {
        $Value = $Script:RGBColors."$C"
        if ($C -match "^#([A-Fa-f0-9]{6})$") {
            return $C
        }
        if ($null -eq $Value) {
            return
        }
        $HexValue = Convert-Color -RGB $Value
        Write-Verbose "Convert-FromColor - Color Name: $C Value: $Value HexValue: $HexValue"
        if ($AsDecimal) {
            [Convert]::ToInt64($HexValue, 16)
        } else {
            "#$($HexValue)"
        }
    }
    $Colors
}
Register-ArgumentCompleter -CommandName ConvertFrom-Color -ParameterName Color -ScriptBlock { $Script:RGBColors.Keys }
function Get-Image {
    [CmdletBinding()]
    param(
        [string] $PathToImages,
        [string] $FileName,
        [string] $FileExtension
    )
    Write-Verbose "Get-Image - PathToImages $PathToImages FileName $FileName FileExtension $FileExtension"
    $ImagePath = [IO.Path]::Combine( $PathToImages, "$($FileName)$FileExtension")
    Write-Verbose "Get-Image - ImagePath $ImagePath"
    if (Test-Path $ImagePath) {
        if ($PSEdition -eq 'Core') {
            $Image = [convert]::ToBase64String((Get-Content $ImagePath -AsByteStream))
        } else {
            $Image = [convert]::ToBase64String((Get-Content $ImagePath -Encoding byte))
        }
        Write-Verbose "Get-Image - Image Type: $($Image.GetType())"
        return "data:image/png;base64,$Image"
    }
    return ''
}
function Repair-Text {
    [CmdletBinding()]
    param(
        [string] $Text
    )
    if ($Text -ne $null) {
        $Text = $Text.ToString().Replace('"', '\"').Replace('\', '\\').Replace("`n", '\n\n').Replace("`r", '').Replace("`t", '\t')
        $Text = [System.Text.RegularExpressions.Regex]::Unescape($($Text))
    }
    if ($Text -eq '') { $Text = ' ' }
    return $Text
}
$Script:RGBColors = [ordered] @{
    None                   = $null
    AirForceBlue           = 93, 138, 168
    Akaroa                 = 195, 176, 145
    AlbescentWhite         = 227, 218, 201
    AliceBlue              = 240, 248, 255
    Alizarin               = 227, 38, 54
    Allports               = 18, 97, 128
    Almond                 = 239, 222, 205
    AlmondFrost            = 159, 129, 112
    Amaranth               = 229, 43, 80
    Amazon                 = 59, 122, 87
    Amber                  = 255, 191, 0
    Amethyst               = 153, 102, 204
    AmethystSmoke          = 156, 138, 164
    AntiqueWhite           = 250, 235, 215
    Apple                  = 102, 180, 71
    AppleBlossom           = 176, 92, 82
    Apricot                = 251, 206, 177
    Aqua                   = 0, 255, 255
    Aquamarine             = 127, 255, 212
    Armygreen              = 75, 83, 32
    Arsenic                = 59, 68, 75
    Astral                 = 54, 117, 136
    Atlantis               = 164, 198, 57
    Atomic                 = 65, 74, 76
    AtomicTangerine        = 255, 153, 102
    Axolotl                = 99, 119, 91
    Azure                  = 240, 255, 255
    Bahia                  = 176, 191, 26
    BakersChocolate        = 93, 58, 26
    BaliHai                = 124, 152, 171
    BananaMania            = 250, 231, 181
    BattleshipGrey         = 85, 93, 80
    BayOfMany              = 35, 48, 103
    Beige                  = 245, 245, 220
    Bermuda                = 136, 216, 192
    Bilbao                 = 42, 128, 0
    BilobaFlower           = 181, 126, 220
    Bismark                = 83, 104, 114
    Bisque                 = 255, 228, 196
    Bistre                 = 61, 43, 31
    Bittersweet            = 254, 111, 94
    Black                  = 0, 0, 0
    BlackPearl             = 31, 38, 42
    BlackRose              = 85, 31, 47
    BlackRussian           = 23, 24, 43
    BlanchedAlmond         = 255, 235, 205
    BlizzardBlue           = 172, 229, 238
    Blue                   = 0, 0, 255
    BlueDiamond            = 77, 26, 127
    BlueMarguerite         = 115, 102, 189
    BlueSmoke              = 115, 130, 118
    BlueViolet             = 138, 43, 226
    Blush                  = 169, 92, 104
    BokaraGrey             = 22, 17, 13
    Bole                   = 121, 68, 59
    BondiBlue              = 0, 147, 175
    Bordeaux               = 88, 17, 26
    Bossanova              = 86, 60, 92
    Boulder                = 114, 116, 114
    Bouquet                = 183, 132, 167
    Bourbon                = 170, 108, 57
    Brass                  = 181, 166, 66
    BrickRed               = 199, 44, 72
    BrightGreen            = 102, 255, 0
    BrightRed              = 146, 43, 62
    BrightTurquoise        = 8, 232, 222
    BrilliantRose          = 243, 100, 162
    BrinkPink              = 250, 110, 121
    BritishRacingGreen     = 0, 66, 37
    Bronze                 = 205, 127, 50
    Brown                  = 165, 42, 42
    BrownPod               = 57, 24, 2
    BuddhaGold             = 202, 169, 6
    Buff                   = 240, 220, 130
    Burgundy               = 128, 0, 32
    BurlyWood              = 222, 184, 135
    BurntOrange            = 255, 117, 56
    BurntSienna            = 233, 116, 81
    BurntUmber             = 138, 51, 36
    ButteredRum            = 156, 124, 56
    CadetBlue              = 95, 158, 160
    California             = 224, 141, 60
    CamouflageGreen        = 120, 134, 107
    Canary                 = 255, 255, 153
    CanCan                 = 217, 134, 149
    CannonPink             = 145, 78, 117
    CaputMortuum           = 89, 39, 32
    Caramel                = 255, 213, 154
    Cararra                = 237, 230, 214
    Cardinal               = 179, 33, 52
    CardinGreen            = 18, 53, 36
    CareysPink             = 217, 152, 160
    CaribbeanGreen         = 0, 222, 164
    Carmine                = 175, 0, 42
    CarnationPink          = 255, 166, 201
    CarrotOrange           = 242, 142, 28
    Cascade                = 141, 163, 153
    CatskillWhite          = 226, 229, 222
    Cedar                  = 67, 48, 46
    Celadon                = 172, 225, 175
    Celeste                = 207, 207, 196
    Cello                  = 55, 79, 107
    Cement                 = 138, 121, 93
    Cerise                 = 222, 49, 99
    Cerulean               = 0, 123, 167
    CeruleanBlue           = 42, 82, 190
    Chantilly              = 239, 187, 204
    Chardonnay             = 255, 200, 124
    Charlotte              = 167, 216, 222
    Charm                  = 208, 116, 139
    Chartreuse             = 127, 255, 0
    ChartreuseYellow       = 223, 255, 0
    ChelseaCucumber        = 135, 169, 107
    Cherub                 = 246, 214, 222
    Chestnut               = 185, 78, 72
    ChileanFire            = 226, 88, 34
    Chinook                = 150, 200, 162
    Chocolate              = 210, 105, 30
    Christi                = 125, 183, 0
    Christine              = 181, 101, 30
    Cinnabar               = 235, 76, 66
    Citron                 = 159, 169, 31
    Citrus                 = 141, 182, 0
    Claret                 = 95, 25, 51
    ClassicRose            = 251, 204, 231
    ClayCreek              = 145, 129, 81
    Clinker                = 75, 54, 33
    Clover                 = 74, 93, 35
    Cobalt                 = 0, 71, 171
    CocoaBrown             = 44, 22, 8
    Cola                   = 60, 48, 36
    ColumbiaBlue           = 166, 231, 255
    CongoBrown             = 103, 76, 71
    Conifer                = 178, 236, 93
    Copper                 = 218, 138, 103
    CopperRose             = 153, 102, 102
    Coral                  = 255, 127, 80
    CoralRed               = 255, 64, 64
    CoralTree              = 173, 111, 105
    Coriander              = 188, 184, 138
    Corn                   = 251, 236, 93
    CornField              = 250, 240, 190
    Cornflower             = 147, 204, 234
    CornflowerBlue         = 100, 149, 237
    Cornsilk               = 255, 248, 220
    Cosmic                 = 132, 63, 91
    Cosmos                 = 255, 204, 203
    CostaDelSol            = 102, 93, 30
    CottonCandy            = 255, 188, 217
    Crail                  = 164, 90, 82
    Cranberry              = 205, 96, 126
    Cream                  = 255, 255, 204
    CreamCan               = 242, 198, 73
    Crimson                = 220, 20, 60
    Crusta                 = 232, 142, 90
    Cumulus                = 255, 255, 191
    Cupid                  = 246, 173, 198
    CuriousBlue            = 40, 135, 200
    Cyan                   = 0, 255, 255
    Cyprus                 = 6, 78, 64
    DaisyBush              = 85, 53, 146
    Dandelion              = 250, 218, 94
    Danube                 = 96, 130, 182
    DarkBlue               = 0, 0, 139
    DarkBrown              = 101, 67, 33
    DarkCerulean           = 8, 69, 126
    DarkChestnut           = 152, 105, 96
    DarkCoral              = 201, 90, 73
    DarkCyan               = 0, 139, 139
    DarkGoldenrod          = 184, 134, 11
    DarkGray               = 169, 169, 169
    DarkGreen              = 0, 100, 0
    DarkGreenCopper        = 73, 121, 107
    DarkGrey               = 169, 169, 169
    DarkKhaki              = 189, 183, 107
    DarkMagenta            = 139, 0, 139
    DarkOliveGreen         = 85, 107, 47
    DarkOrange             = 255, 140, 0
    DarkOrchid             = 153, 50, 204
    DarkPastelGreen        = 3, 192, 60
    DarkPink               = 222, 93, 131
    DarkPurple             = 150, 61, 127
    DarkRed                = 139, 0, 0
    DarkSalmon             = 233, 150, 122
    DarkSeaGreen           = 143, 188, 143
    DarkSlateBlue          = 72, 61, 139
    DarkSlateGray          = 47, 79, 79
    DarkSlateGrey          = 47, 79, 79
    DarkSpringGreen        = 23, 114, 69
    DarkTangerine          = 255, 170, 29
    DarkTurquoise          = 0, 206, 209
    DarkViolet             = 148, 0, 211
    DarkWood               = 130, 102, 68
    DeepBlush              = 245, 105, 145
    DeepCerise             = 224, 33, 138
    DeepKoamaru            = 51, 51, 102
    DeepLilac              = 153, 85, 187
    DeepMagenta            = 204, 0, 204
    DeepPink               = 255, 20, 147
    DeepSea                = 14, 124, 97
    DeepSkyBlue            = 0, 191, 255
    DeepTeal               = 24, 69, 59
    Denim                  = 36, 107, 206
    DesertSand             = 237, 201, 175
    DimGray                = 105, 105, 105
    DimGrey                = 105, 105, 105
    DodgerBlue             = 30, 144, 255
    Dolly                  = 242, 242, 122
    Downy                  = 95, 201, 191
    DutchWhite             = 239, 223, 187
    EastBay                = 76, 81, 109
    EastSide               = 178, 132, 190
    EchoBlue               = 169, 178, 195
    Ecru                   = 194, 178, 128
    Eggplant               = 162, 0, 109
    EgyptianBlue           = 16, 52, 166
    ElectricBlue           = 125, 249, 255
    ElectricIndigo         = 111, 0, 255
    ElectricLime           = 208, 255, 20
    ElectricPurple         = 191, 0, 255
    Elm                    = 47, 132, 124
    Emerald                = 80, 200, 120
    Eminence               = 108, 48, 130
    Endeavour              = 46, 88, 148
    EnergyYellow           = 245, 224, 80
    Espresso               = 74, 44, 42
    Eucalyptus             = 26, 162, 96
    Falcon                 = 126, 94, 96
    Fallow                 = 204, 153, 102
    FaluRed                = 128, 24, 24
    Feldgrau               = 77, 93, 83
    Feldspar               = 205, 149, 117
    Fern                   = 113, 188, 120
    FernGreen              = 79, 121, 66
    Festival               = 236, 213, 64
    Finn                   = 97, 64, 81
    FireBrick              = 178, 34, 34
    FireBush               = 222, 143, 78
    FireEngineRed          = 211, 33, 45
    Flamingo               = 233, 92, 75
    Flax                   = 238, 220, 130
    FloralWhite            = 255, 250, 240
    ForestGreen            = 34, 139, 34
    Frangipani             = 250, 214, 165
    FreeSpeechAquamarine   = 0, 168, 119
    FreeSpeechRed          = 204, 0, 0
    FrenchLilac            = 230, 168, 215
    FrenchRose             = 232, 83, 149
    FriarGrey              = 135, 134, 129
    Froly                  = 228, 113, 122
    Fuchsia                = 255, 0, 255
    FuchsiaPink            = 255, 119, 255
    Gainsboro              = 220, 220, 220
    Gallery                = 219, 215, 210
    Galliano               = 204, 160, 29
    Gamboge                = 204, 153, 0
    Ghost                  = 196, 195, 208
    GhostWhite             = 248, 248, 255
    Gin                    = 216, 228, 188
    GinFizz                = 247, 231, 206
    Givry                  = 230, 208, 171
    Glacier                = 115, 169, 194
    Gold                   = 255, 215, 0
    GoldDrop               = 213, 108, 43
    GoldenBrown            = 150, 113, 23
    GoldenFizz             = 240, 225, 48
    GoldenGlow             = 248, 222, 126
    GoldenPoppy            = 252, 194, 0
    Goldenrod              = 218, 165, 32
    GoldenSand             = 233, 214, 107
    GoldenYellow           = 253, 238, 0
    GoldTips               = 225, 189, 39
    GordonsGreen           = 37, 53, 41
    Gorse                  = 255, 225, 53
    Gossamer               = 49, 145, 119
    GrannySmithApple       = 168, 228, 160
    Gray                   = 128, 128, 128
    GrayAsparagus          = 70, 89, 69
    Green                  = 0, 128, 0
    GreenLeaf              = 76, 114, 29
    GreenVogue             = 38, 67, 72
    GreenYellow            = 173, 255, 47
    Grey                   = 128, 128, 128
    GreyAsparagus          = 70, 89, 69
    GuardsmanRed           = 157, 41, 51
    GumLeaf                = 178, 190, 181
    Gunmetal               = 42, 52, 57
    Hacienda               = 155, 135, 12
    HalfAndHalf            = 232, 228, 201
    HalfBaked              = 95, 138, 139
    HalfColonialWhite      = 246, 234, 190
    HalfPearlLusta         = 240, 234, 214
    HanPurple              = 63, 0, 255
    Harlequin              = 74, 255, 0
    HarleyDavidsonOrange   = 194, 59, 34
    Heather                = 174, 198, 207
    Heliotrope             = 223, 115, 255
    Hemp                   = 161, 122, 116
    Highball               = 134, 126, 54
    HippiePink             = 171, 75, 82
    Hoki                   = 110, 127, 128
    HollywoodCerise        = 244, 0, 161
    Honeydew               = 240, 255, 240
    Hopbush                = 207, 113, 175
    HorsesNeck             = 108, 84, 30
    HotPink                = 255, 105, 180
    HummingBird            = 201, 255, 229
    HunterGreen            = 53, 94, 59
    Illusion               = 244, 152, 173
    InchWorm               = 202, 224, 13
    IndianRed              = 205, 92, 92
    Indigo                 = 75, 0, 130
    InternationalKleinBlue = 0, 24, 168
    InternationalOrange    = 255, 79, 0
    IrisBlue               = 28, 169, 201
    IrishCoffee            = 102, 66, 40
    IronsideGrey           = 113, 112, 110
    IslamicGreen           = 0, 144, 0
    Ivory                  = 255, 255, 240
    Jacarta                = 61, 50, 93
    JackoBean              = 65, 54, 40
    JacksonsPurple         = 46, 45, 136
    Jade                   = 0, 171, 102
    JapaneseLaurel         = 47, 117, 50
    Jazz                   = 93, 43, 44
    JazzberryJam           = 165, 11, 94
    JellyBean              = 68, 121, 142
    JetStream              = 187, 208, 201
    Jewel                  = 0, 107, 60
    Jon                    = 79, 58, 60
    JordyBlue              = 124, 185, 232
    Jumbo                  = 132, 132, 130
    JungleGreen            = 41, 171, 135
    KaitokeGreen           = 30, 77, 43
    Karry                  = 255, 221, 202
    KellyGreen             = 70, 203, 24
    Keppel                 = 93, 164, 147
    Khaki                  = 240, 230, 140
    Killarney              = 77, 140, 87
    KingfisherDaisy        = 85, 27, 140
    Kobi                   = 230, 143, 172
    LaPalma                = 60, 141, 13
    LaserLemon             = 252, 247, 94
    Laurel                 = 103, 146, 103
    Lavender               = 230, 230, 250
    LavenderBlue           = 204, 204, 255
    LavenderBlush          = 255, 240, 245
    LavenderPink           = 251, 174, 210
    LavenderRose           = 251, 160, 227
    LawnGreen              = 124, 252, 0
    LemonChiffon           = 255, 250, 205
    LightBlue              = 173, 216, 230
    LightCoral             = 240, 128, 128
    LightCyan              = 224, 255, 255
    LightGoldenrodYellow   = 250, 250, 210
    LightGray              = 211, 211, 211
    LightGreen             = 144, 238, 144
    LightGrey              = 211, 211, 211
    LightPink              = 255, 182, 193
    LightSalmon            = 255, 160, 122
    LightSeaGreen          = 32, 178, 170
    LightSkyBlue           = 135, 206, 250
    LightSlateGray         = 119, 136, 153
    LightSlateGrey         = 119, 136, 153
    LightSteelBlue         = 176, 196, 222
    LightYellow            = 255, 255, 224
    Lilac                  = 204, 153, 204
    Lime                   = 0, 255, 0
    LimeGreen              = 50, 205, 50
    Limerick               = 139, 190, 27
    Linen                  = 250, 240, 230
    Lipstick               = 159, 43, 104
    Liver                  = 83, 75, 79
    Lochinvar              = 86, 136, 125
    Lochmara               = 38, 97, 156
    Lola                   = 179, 158, 181
    LondonHue              = 170, 152, 169
    Lotus                  = 124, 72, 72
    LuckyPoint             = 29, 41, 81
    MacaroniAndCheese      = 255, 189, 136
    Madang                 = 193, 249, 162
    Madras                 = 81, 65, 0
    Magenta                = 255, 0, 255
    MagicMint              = 170, 240, 209
    Magnolia               = 248, 244, 255
    Mahogany               = 215, 59, 62
    Maire                  = 27, 24, 17
    Maize                  = 230, 190, 138
    Malachite              = 11, 218, 81
    Malibu                 = 93, 173, 236
    Malta                  = 169, 154, 134
    Manatee                = 140, 146, 172
    Mandalay               = 176, 121, 57
    MandarianOrange        = 146, 39, 36
    Mandy                  = 191, 79, 81
    Manhattan              = 229, 170, 112
    Mantis                 = 125, 194, 66
    Manz                   = 217, 230, 80
    MardiGras              = 48, 25, 52
    Mariner                = 57, 86, 156
    Maroon                 = 128, 0, 0
    Matterhorn             = 85, 85, 85
    Mauve                  = 244, 187, 255
    Mauvelous              = 255, 145, 175
    MauveTaupe             = 143, 89, 115
    MayaBlue               = 119, 181, 254
    McKenzie               = 129, 97, 60
    MediumAquamarine       = 102, 205, 170
    MediumBlue             = 0, 0, 205
    MediumCarmine          = 175, 64, 53
    MediumOrchid           = 186, 85, 211
    MediumPurple           = 147, 112, 219
    MediumRedViolet        = 189, 51, 164
    MediumSeaGreen         = 60, 179, 113
    MediumSlateBlue        = 123, 104, 238
    MediumSpringGreen      = 0, 250, 154
    MediumTurquoise        = 72, 209, 204
    MediumVioletRed        = 199, 21, 133
    MediumWood             = 166, 123, 91
    Melon                  = 253, 188, 180
    Merlot                 = 112, 54, 66
    MetallicGold           = 211, 175, 55
    Meteor                 = 184, 115, 51
    MidnightBlue           = 25, 25, 112
    MidnightExpress        = 0, 20, 64
    Mikado                 = 60, 52, 31
    MilanoRed              = 168, 55, 49
    Ming                   = 54, 116, 125
    MintCream              = 245, 255, 250
    MintGreen              = 152, 255, 152
    Mischka                = 168, 169, 173
    MistyRose              = 255, 228, 225
    Moccasin               = 255, 228, 181
    Mojo                   = 149, 69, 53
    MonaLisa               = 255, 153, 153
    Mongoose               = 179, 139, 109
    Montana                = 53, 56, 57
    MoodyBlue              = 116, 108, 192
    MoonYellow             = 245, 199, 26
    MossGreen              = 173, 223, 173
    MountainMeadow         = 28, 172, 120
    MountainMist           = 161, 157, 148
    MountbattenPink        = 153, 122, 141
    Mulberry               = 211, 65, 157
    Mustard                = 255, 219, 88
    Myrtle                 = 25, 89, 5
    MySin                  = 255, 179, 71
    NavajoWhite            = 255, 222, 173
    Navy                   = 0, 0, 128
    NavyBlue               = 2, 71, 254
    NeonCarrot             = 255, 153, 51
    NeonPink               = 255, 92, 205
    Nepal                  = 145, 163, 176
    Nero                   = 20, 20, 20
    NewMidnightBlue        = 0, 0, 156
    Niagara                = 58, 176, 158
    NightRider             = 59, 47, 47
    Nobel                  = 152, 152, 152
    Norway                 = 169, 186, 157
    Nugget                 = 183, 135, 39
    OceanGreen             = 95, 167, 120
    Ochre                  = 202, 115, 9
    OldCopper              = 111, 78, 55
    OldGold                = 207, 181, 59
    OldLace                = 253, 245, 230
    OldLavender            = 121, 104, 120
    OldRose                = 195, 33, 72
    Olive                  = 128, 128, 0
    OliveDrab              = 107, 142, 35
    OliveGreen             = 181, 179, 92
    Olivetone              = 110, 110, 48
    Olivine                = 154, 185, 115
    Onahau                 = 196, 216, 226
    Opal                   = 168, 195, 188
    Orange                 = 255, 165, 0
    OrangePeel             = 251, 153, 2
    OrangeRed              = 255, 69, 0
    Orchid                 = 218, 112, 214
    OuterSpace             = 45, 56, 58
    OutrageousOrange       = 254, 90, 29
    Oxley                  = 95, 167, 119
    PacificBlue            = 0, 136, 220
    Padua                  = 128, 193, 151
    PalatinatePurple       = 112, 41, 99
    PaleBrown              = 160, 120, 90
    PaleChestnut           = 221, 173, 175
    PaleCornflowerBlue     = 188, 212, 230
    PaleGoldenrod          = 238, 232, 170
    PaleGreen              = 152, 251, 152
    PaleMagenta            = 249, 132, 239
    PalePink               = 250, 218, 221
    PaleSlate              = 201, 192, 187
    PaleTaupe              = 188, 152, 126
    PaleTurquoise          = 175, 238, 238
    PaleVioletRed          = 219, 112, 147
    PalmLeaf               = 53, 66, 48
    Panache                = 233, 255, 219
    PapayaWhip             = 255, 239, 213
    ParisDaisy             = 255, 244, 79
    Parsley                = 48, 96, 48
    PastelGreen            = 119, 221, 119
    PattensBlue            = 219, 233, 244
    Peach                  = 255, 203, 164
    PeachOrange            = 255, 204, 153
    PeachPuff              = 255, 218, 185
    PeachYellow            = 250, 223, 173
    Pear                   = 209, 226, 49
    PearlLusta             = 234, 224, 200
    Pelorous               = 42, 143, 189
    Perano                 = 172, 172, 230
    Periwinkle             = 197, 203, 225
    PersianBlue            = 34, 67, 182
    PersianGreen           = 0, 166, 147
    PersianIndigo          = 51, 0, 102
    PersianPink            = 247, 127, 190
    PersianRed             = 192, 54, 44
    PersianRose            = 233, 54, 167
    Persimmon              = 236, 88, 0
    Peru                   = 205, 133, 63
    Pesto                  = 128, 117, 50
    PictonBlue             = 102, 153, 204
    PigmentGreen           = 0, 173, 67
    PigPink                = 255, 218, 233
    PineGreen              = 1, 121, 111
    PineTree               = 42, 47, 35
    Pink                   = 255, 192, 203
    PinkFlare              = 191, 175, 178
    PinkLace               = 240, 211, 220
    PinkSwan               = 179, 179, 179
    Plum                   = 221, 160, 221
    Pohutukawa             = 102, 12, 33
    PoloBlue               = 119, 158, 203
    Pompadour              = 129, 20, 83
    Portage                = 146, 161, 207
    PotPourri              = 241, 221, 207
    PottersClay            = 132, 86, 60
    PowderBlue             = 176, 224, 230
    Prim                   = 228, 196, 207
    PrussianBlue           = 0, 58, 108
    PsychedelicPurple      = 223, 0, 255
    Puce                   = 204, 136, 153
    Pueblo                 = 108, 46, 31
    PuertoRico             = 67, 179, 174
    Pumpkin                = 255, 99, 28
    Purple                 = 128, 0, 128
    PurpleMountainsMajesty = 150, 123, 182
    PurpleTaupe            = 93, 57, 84
    QuarterSpanishWhite    = 230, 224, 212
    Quartz                 = 220, 208, 255
    Quincy                 = 106, 84, 69
    RacingGreen            = 26, 36, 33
    RadicalRed             = 255, 32, 82
    Rajah                  = 251, 171, 96
    RawUmber               = 123, 63, 0
    RazzleDazzleRose       = 254, 78, 218
    Razzmatazz             = 215, 10, 83
    Red                    = 255, 0, 0
    RedBerry               = 132, 22, 23
    RedDamask              = 203, 109, 81
    RedOxide               = 99, 15, 15
    RedRobin               = 128, 64, 64
    RichBlue               = 84, 90, 167
    Riptide                = 141, 217, 204
    RobinsEggBlue          = 0, 204, 204
    RobRoy                 = 225, 169, 95
    RockSpray              = 171, 56, 31
    RomanCoffee            = 131, 105, 83
    RoseBud                = 246, 164, 148
    RoseBudCherry          = 135, 50, 96
    RoseTaupe              = 144, 93, 93
    RosyBrown              = 188, 143, 143
    Rouge                  = 176, 48, 96
    RoyalBlue              = 65, 105, 225
    RoyalHeath             = 168, 81, 110
    RoyalPurple            = 102, 51, 152
    Ruby                   = 215, 24, 104
    Russet                 = 128, 70, 27
    Rust                   = 192, 64, 0
    RusticRed              = 72, 6, 7
    Saddle                 = 99, 81, 71
    SaddleBrown            = 139, 69, 19
    SafetyOrange           = 255, 102, 0
    Saffron                = 244, 196, 48
    Sage                   = 143, 151, 121
    Sail                   = 161, 202, 241
    Salem                  = 0, 133, 67
    Salmon                 = 250, 128, 114
    SandyBeach             = 253, 213, 177
    SandyBrown             = 244, 164, 96
    Sangria                = 134, 1, 17
    SanguineBrown          = 115, 54, 53
    SanMarino              = 80, 114, 167
    SanteFe                = 175, 110, 77
    Sapphire               = 6, 42, 120
    Saratoga               = 84, 90, 44
    Scampi                 = 102, 102, 153
    Scarlet                = 255, 36, 0
    ScarletGum             = 67, 28, 83
    SchoolBusYellow        = 255, 216, 0
    Schooner               = 139, 134, 128
    ScreaminGreen          = 102, 255, 102
    Scrub                  = 59, 60, 54
    SeaBuckthorn           = 249, 146, 69
    SeaGreen               = 46, 139, 87
    Seagull                = 140, 190, 214
    SealBrown              = 61, 12, 2
    Seance                 = 96, 47, 107
    SeaPink                = 215, 131, 127
    SeaShell               = 255, 245, 238
    Selago                 = 250, 230, 250
    SelectiveYellow        = 242, 180, 0
    SemiSweetChocolate     = 107, 68, 35
    Sepia                  = 150, 90, 62
    Serenade               = 255, 233, 209
    Shadow                 = 133, 109, 77
    Shakespeare            = 114, 160, 193
    Shalimar               = 252, 255, 164
    Shamrock               = 68, 215, 168
    ShamrockGreen          = 0, 153, 102
    SherpaBlue             = 0, 75, 73
    SherwoodGreen          = 27, 77, 62
    Shilo                  = 222, 165, 164
    ShipCove               = 119, 139, 165
    Shocking               = 241, 156, 187
    ShockingPink           = 255, 29, 206
    ShuttleGrey            = 84, 98, 111
    Sidecar                = 238, 224, 177
    Sienna                 = 160, 82, 45
    Silk                   = 190, 164, 147
    Silver                 = 192, 192, 192
    SilverChalice          = 175, 177, 174
    SilverTree             = 102, 201, 146
    SkyBlue                = 135, 206, 235
    SlateBlue              = 106, 90, 205
    SlateGray              = 112, 128, 144
    SlateGrey              = 112, 128, 144
    Smalt                  = 0, 48, 143
    SmaltBlue              = 74, 100, 108
    Snow                   = 255, 250, 250
    SoftAmber              = 209, 190, 168
    Solitude               = 235, 236, 240
    Sorbus                 = 233, 105, 44
    Spectra                = 53, 101, 77
    SpicyMix               = 136, 101, 78
    Spray                  = 126, 212, 230
    SpringBud              = 150, 255, 0
    SpringGreen            = 0, 255, 127
    SpringSun              = 236, 235, 189
    SpunPearl              = 170, 169, 173
    Stack                  = 130, 142, 132
    SteelBlue              = 70, 130, 180
    Stiletto               = 137, 63, 69
    Strikemaster           = 145, 92, 131
    StTropaz               = 50, 82, 123
    Studio                 = 115, 79, 150
    Sulu                   = 201, 220, 135
    SummerSky              = 33, 171, 205
    Sun                    = 237, 135, 45
    Sundance               = 197, 179, 88
    Sunflower              = 228, 208, 10
    Sunglow                = 255, 204, 51
    SunsetOrange           = 253, 82, 64
    SurfieGreen            = 0, 116, 116
    Sushi                  = 111, 153, 64
    SuvaGrey               = 140, 140, 140
    Swamp                  = 35, 43, 43
    SweetCorn              = 253, 219, 109
    SweetPink              = 243, 153, 152
    Tacao                  = 236, 177, 118
    TahitiGold             = 235, 97, 35
    Tan                    = 210, 180, 140
    Tangaroa               = 0, 28, 61
    Tangerine              = 228, 132, 0
    TangerineYellow        = 253, 204, 13
    Tapestry               = 183, 110, 121
    Taupe                  = 72, 60, 50
    TaupeGrey              = 139, 133, 137
    TawnyPort              = 102, 66, 77
    TaxBreak               = 79, 102, 106
    TeaGreen               = 208, 240, 192
    Teak                   = 176, 141, 87
    Teal                   = 0, 128, 128
    TeaRose                = 255, 133, 207
    Temptress              = 60, 20, 33
    Tenne                  = 200, 101, 0
    TerraCotta             = 226, 114, 91
    Thistle                = 216, 191, 216
    TickleMePink           = 245, 111, 161
    Tidal                  = 232, 244, 140
    TitanWhite             = 214, 202, 221
    Toast                  = 165, 113, 100
    Tomato                 = 255, 99, 71
    TorchRed               = 255, 3, 62
    ToryBlue               = 54, 81, 148
    Tradewind              = 110, 174, 161
    TrendyPink             = 133, 96, 136
    TropicalRainForest     = 0, 127, 102
    TrueV                  = 139, 114, 190
    TulipTree              = 229, 183, 59
    Tumbleweed             = 222, 170, 136
    Turbo                  = 255, 195, 36
    TurkishRose            = 152, 119, 123
    Turquoise              = 64, 224, 208
    TurquoiseBlue          = 118, 215, 234
    Tuscany                = 175, 89, 62
    TwilightBlue           = 253, 255, 245
    Twine                  = 186, 135, 89
    TyrianPurple           = 102, 2, 60
    Ultramarine            = 10, 17, 149
    UltraPink              = 255, 111, 255
    Valencia               = 222, 82, 70
    VanCleef               = 84, 61, 55
    VanillaIce             = 229, 204, 201
    VenetianRed            = 209, 0, 28
    Venus                  = 138, 127, 128
    Vermilion              = 251, 79, 20
    VeryLightGrey          = 207, 207, 207
    VidaLoca               = 94, 140, 49
    Viking                 = 71, 171, 204
    Viola                  = 180, 131, 149
    ViolentViolet          = 50, 23, 77
    Violet                 = 238, 130, 238
    VioletRed              = 255, 57, 136
    Viridian               = 64, 130, 109
    VistaBlue              = 159, 226, 191
    VividViolet            = 127, 62, 152
    WaikawaGrey            = 83, 104, 149
    Wasabi                 = 150, 165, 60
    Watercourse            = 0, 106, 78
    Wedgewood              = 67, 107, 149
    WellRead               = 147, 61, 65
    Wewak                  = 255, 152, 153
    Wheat                  = 245, 222, 179
    Whiskey                = 217, 154, 108
    WhiskeySour            = 217, 144, 88
    White                  = 255, 255, 255
    WhiteSmoke             = 245, 245, 245
    WildRice               = 228, 217, 111
    WildSand               = 229, 228, 226
    WildStrawberry         = 252, 65, 154
    WildWatermelon         = 255, 84, 112
    WildWillow             = 172, 191, 96
    Windsor                = 76, 40, 130
    Wisteria               = 191, 148, 228
    Wistful                = 162, 162, 208
    Yellow                 = 255, 255, 0
    YellowGreen            = 154, 205, 50
    YellowOrange           = 255, 174, 66
    YourPink               = 244, 194, 194
}
function ConvertTo-TeamsFact {
    <#
    .SYNOPSIS
    Convert a PSCustomObject or a Hashtable to Teams facts.

    .DESCRIPTION
    Teams facts are name-value pairs. This function helps convert a PSObject or a Hashtable to Teams facts (only one level deep).

    .PARAMETER InputObject
    The Hashtable or PSObject that is output by another cmdlet.

    .EXAMPLE
    Get-ChildItem | Select-Object -First 1 | ConvertTo-TeamsFact

    .EXAMPLE
    @{ Product = 'Microsoft Teams'; Developer = 'Microsoft Corporation'; ReleaseYear = '2018' } | ConvertTo-TeamsFact

    .NOTES
    Ram Iyer (https://ramiyer.me)
    #>

    [CmdletBinding()]
    param (
        # The input object
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        $InputObject
    )
    foreach ($Object in $InputObject) {
        if ($Object -is [System.Collections.IDictionary]) {
            $Facts = foreach ($Key in $Object.Keys) {
                New-TeamsFact -Name $Key -Value $Object.$Key
            }
            #} elseif (($Object -is [int]) -or ($Object -is [long]) -or ($Object -is [string]) -or ($Object -is [char]) -or ($Object -is [bool]) -or ($Object -is [byte]) -or ($Object -is [double]) -or ($Object -is [decimal]) -or ($Object -is [single]) -or ($Object -is [array]) -or ($Object -is [xml])) {
        } elseif ($Object.GetType().Name -match 'bool|byte|char|datetime|decimal|double|xml|float|int|long|sbyte|short|string|timespan|uint|ulong|URI|ushort') {
            # Because PowerShell implicitly converts datatypes to PSObject
            Write-Error -Message 'The input is neither a PSObject nor a Hashtable. Operation aborted.' -Category InvalidData -ErrorAction Stop
        } else {
            # Assumes that the input is a PSObject; anyway there would be an implicit conversion if not caught in the previous block
            $Facts = foreach ($Property in $Object.PsObject.Properties) {
                New-TeamsFact -Name $Property.Name -Value $Property.Value
            }
        }
        $Facts
    }
}
function ConvertTo-TeamsSection {
    <#
    .SYNOPSIS
    Convert an array of PSCustomObject or a Hashtable to separate Teams sections.

    .DESCRIPTION
    Teams sections are chunks of information that appear within a Teams message. This function helps convert an array of PSObject or an array of Hashtables to Teams sections (only one level deep).

    .PARAMETER InputObject
    The Hashtable or PSObject that is output by another cmdlet.

    .EXAMPLE
    Get-ChildItem -Directory | ConvertTo-TeamsSection -SectionTitleProperty Name

    .NOTES
    Ram Iyer (https://ramiyer.me)
    #>
    param (
        # The input object
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        $InputObject,

        # The property to use for title
        [Parameter(Mandatory = $false, Position = 1)]
        [string]
        $SectionTitleProperty
    )

    process {
        #$TotalCount = $InputObject.Count
        #$CurrentCount = 1

        foreach ($Item in $InputObject) {
            $SectionParams = @{
                ActivityDetails = $Item | ConvertTo-TeamsFact
            }
            if ($SectionTitleProperty) {
                $SectionParams.ActivityTitle = "$(($SectionTitleProperty -creplace '([A-Z])', ' $1').Trim()) $($Item.$SectionTitleProperty)"
            }
            New-TeamsSection @SectionParams
        }
    }
}
function New-AdaptiveAction {
    [cmdletBinding()]
    param(
        [scriptblock] $Body,
        [scriptblock] $Actions,
        [ValidateSet('Action.ShowCard', 'Action.Submit', 'Action.OpenUrl', 'Action.ToggleVisibility')][string] $Type = 'Action.ShowCard',
        [string] $ActionUrl,
        [string] $Title
    )
    if ($ActionUrl) {
        # We help user so the actioon choses itself
        $Type = 'Action.OpenUrl'
    }
    $TeamObject = [ordered] @{
        type  = $Type
        title = $Title
        url   = $ActionUrl
        card  = [ordered]@{}
    }
    if ($Body -or $Actions) {
        $TeamObject['card']['type'] = 'AdaptiveCard'
        if ($Body) {
            $TeamObject['card']['body'] = & $Body
        }
        if ($Actions) {
            $TeamObject['card']['actions'] = & $Actions
        }
    }
    Remove-EmptyValue -Hashtable $TeamObject -Recursive -Rerun 1
    $TeamObject
}
function New-AdaptiveActionSet {
    [cmdletBinding()]
    param(
        [scriptblock] $Action
    )

    if ($Action) {
        $OutputAction = & $Action
        if ($OutputAction) {
            $TeamObject = [ordered] @{
                type    = 'ActionSet'
                actions = @(
                    $OutputAction
                )
            }
            Remove-EmptyValue -Hashtable $TeamObject
            $TeamObject
        }
    }
}
function New-AdaptiveCard {
    <#
    .SYNOPSIS
    An Adaptive Card, containing a free-form body of card elements, and an optional set of actions.

    .DESCRIPTION
    An Adaptive Card, containing a free-form body of card elements, and an optional set of actions.

    .PARAMETER Body
    The card elements to show in the primary card region.

    .PARAMETER Action
    The Actions to show in the card’s action bar.

    .PARAMETER Uri
    WebHook Uri to send Adaptive Card to. When provided sends Adaptive Card. When not provided JSON is returned.

    .PARAMETER FallBackText
    Text shown when the client doesn’t support the version specified (may contain markdown).

    .PARAMETER MinimumHeight
    Specifies the minimum height of the card.

    .PARAMETER Speak
    Specifies what should be spoken for this entire card. This is simple text or SSML fragment.

    .PARAMETER Language
    The 2-letter ISO-639-1 language used in the card. Used to localize any date/time functions.

    .PARAMETER VerticalContentAlignment
    Defines how the content should be aligned vertically within the container. Only relevant for fixed-height cards, or cards with a minHeight specified.

    .PARAMETER BackgroundUrl
    Specifies a background image. Acceptable formats are PNG, JPEG, and GIF

    .PARAMETER BackgroundFillMode
    Controls how background is displayed

    "cover": The background image covers the entire width of the container. Its aspect ratio is preserved. Content may be clipped if the aspect ratio of the image doesn't match the aspect ratio of the container. verticalAlignment is respected (horizontalAlignment is meaningless since it's stretched width). This is the default mode and is the equivalent to the current model.
    "repeatHorizontally": The background image isn't stretched. It is repeated in the x axis as many times as necessary to cover the container's width. verticalAlignment is honored (default is top), horizontalAlignment is ignored.
    "repeatVertically": The background image isn't stretched. It is repeated in the y axis as many times as necessary to cover the container's height. verticalAlignment is ignored, horizontalAlignment is honored (default is left).
    "repeat": The background image isn't stretched. It is repeated first in the x axis then in the y axis as many times as necessary to cover the entire container. Both horizontalAlignment and verticalAlignment are honored (defaults are left and top).

    .PARAMETER BackgroundHorizontalAlignment
    Controls how background is aligned horizontally

    .PARAMETER BackgroundVerticalAlignment
    Controls how background is aligned vertically

    .PARAMETER SelectAction
    An Action that will be invoked when the card is tapped or selected.

    .PARAMETER SelectActionId
    Provide ID for Select Action

    .PARAMETER SelectActionUrl
    Provide URL to open when using SelectAction with Action.OpenUrl

    .PARAMETER SelectActionTitle
    Provide Title for Select Action

    .PARAMETER FullWidth
    Provide ability to make card full width. By default it set to small.

    .PARAMETER AllowImageExpand
    Defines that image may expand

    .EXAMPLE
    New-AdaptiveCard -Uri $Env:TEAMSPESTERID -VerticalContentAlignment center {
        New-AdaptiveTextBlock -Size ExtraLarge -Weight Bolder -Text 'Test' -Color Attention -HorizontalAlignment Center
        New-AdaptiveColumnSet {
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Dark
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Light
            }
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Warning
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Good
            }
        }
    } -SelectAction Action.OpenUrl -SelectActionUrl 'https://evotec.xyz' -Verbose

    .EXAMPLE
    New-AdaptiveCard -Uri $Env:TEAMSPESTERID -VerticalContentAlignment center {
        New-AdaptiveTextBlock -Size ExtraLarge -Weight Bolder -Text 'Test' -Color Attention -HorizontalAlignment Center
        New-AdaptiveColumnSet {
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Dark
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Light
            }
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Warning
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Good
            }
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1 <at>Name</at>' -Color Warning
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1 <at>Zenon Jaskuła</at>' -Color Warning
            }
        }
        New-AdaptiveMention -Text 'Zenon Jaskuła' -UserPrincipalName 'przemyslaw.klys@evotec.test'
        New-AdaptiveMention -Text 'Name' -UserPrincipalName 'przemyslaw.klys@evotec.test'
    } -Verbose -FullWidth

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [scriptblock] $Body,
        [scriptblock] $Action,
        [string] $Uri,
        [string] $FallBackText,
        [int] $MinimumHeight,
        [string] $Speak,
        [string] $Language,
        [ValidateSet('top', 'center', 'bottom')][string] $VerticalContentAlignment,

        [string] $BackgroundUrl,
        [ValidateSet('Cover', 'RepeatHorizontally', 'RepeatVertically', 'Repeat')][string] $BackgroundFillMode,
        [ValidateSet('left', 'center', 'right')][string] $BackgroundHorizontalAlignment,
        [ValidateSet('top', 'center', 'bottom')][string] $BackgroundVerticalAlignment,

        [ValidateSet('Action.Submit', 'Action.OpenUrl', 'Action.ToggleVisibility')][string] $SelectAction,
        [string] $SelectActionId,
        [string] $SelectActionUrl,
        [string] $SelectActionTitle,
        [switch] $FullWidth,
        [switch] $AllowImageExpand
    )
    $Mentions = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
    $Wrapper = [ordered]@{
        "type"        = "message"
        "attachments" = @(
            [ordered] @{
                "contentType" = 'application/vnd.microsoft.card.adaptive'
                "content"     = [ordered]@{
                    '$schema' = "http://adaptivecards.io/schemas/adaptive-card.json"
                    type      = "AdaptiveCard"
                    version   = "1.2" # Currently maximum supported is 1.2 for Teams, available is 1.3
                    body      = @(
                        if ($Body) {
                            $OutputBody = & $Body
                            foreach ($B in $OutputBody) {
                                if ($B.type -eq 'mention') {
                                    $Mentions.Add($B)
                                } else {
                                    $B
                                }
                            }
                        }
                    )
                    actions   = @(
                        if ($Action) {
                            & $Action
                        }
                    )
                    msteams   = [ordered]@{

                    }
                }
            }
        )
    }
    if ($AllowImageExpand) {
        $Wrapper['attachments'][0]['content']['msteams']['allowExpand'] = $true
    }
    if ($FullWidth) {
        $Wrapper['attachments'][0]['content']['msteams']['width'] = 'Full'
    }
    if ($MinimumHeight) {
        $Wrapper['attachments'][0]['content']['minHeight'] = "$($MinimumHeight)px"
    }
    # if ($FallBackText) {
    $Wrapper['attachments'][0]['content']['fallbackText'] = $FallBackText
    #  }
    #  if ($Language) {
    $Wrapper['attachments'][0]['content']['lang'] = $Language
    # }
    # if ($Speak) {
    $Wrapper['attachments'][0]['content']['speak'] = $Speak
    # }
    # if ($VerticalContentAlignment) {
    $Wrapper['attachments'][0]['content']['verticalContentAlignment'] = $VerticalContentAlignment
    #}
    #if ($BackgroundUrl) {
    $Wrapper['attachments'][0]['content']['backgroundImage'] = [ordered] @{
        "fillMode"            = $BackgroundFillMode
        "horizontalAlignment" = $BackgroundHorizontalAlignment
        "verticalAlignment"   = $BackgroundVerticalAlignment
        "url"                 = $BackgroundUrl
    }
    #}
    if ($SelectActionUrl) {
        # We help user so the actioon choses itself
        $SelectAction = 'Action.OpenUrl'
    }
    $Wrapper['attachments'][0]['content']['selectAction'] = [ordered] @{
        type  = $SelectAction
        id    = $SelectActionId
        title = $SelectActionTitle
        url   = $SelectActionUrl
    }

    if ($Mentions.Count -gt 0) {
        # this somewhat works, except it doesn't
        $Wrapper['attachments'][0]['content']["msteams"]["entities"] = @(
            foreach ($Mention in $Mentions) {
                $Mention
            }
            <#
                @{
                    "type"      = "mention"
                    "text"      = "<at>przemyslaw.klys</at>"
                    "mentioned" = @{
                        #"id"   = "8:orgid:49f7e27a-ce6c-45ef-9936-6ef3e940583d"
                        #"id" = '29:49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                        #"id" = '29:orgid:49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                        #"id" = '19:b6b525a2187848ddb257f59e374363bd'
                        #"id" = 'orgid:49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                        #"id" = '49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                        #"name" = "przemyslaw.klys"

                        id   = 'przemyslaw.klys@evotec.pl'
                        name = 'Przemysław Kłys'

                    }
                }
            #>
        )
    }
    <#
    #>
    <# this doesn't work, but tested
    $Wrapper["msteams"] = @{
        "entities" = @(
            @{
                "type"      = "mention"
                "text"      = "<at>przemyslaw.klys</at>"
                "mentioned" = @{
                    "id"   = "8:orgid:49f7e27a-ce6c-45ef-9936-6ef3e940583d"
                    #"id" = '29:49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                    #"id" = 'orgid:49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                    #"id" = '49f7e27a-ce6c-45ef-9936-6ef3e940583d'
                    "name" = "przemyslaw.klys"
                }
            }
        )
    }
    #>

    Remove-EmptyValue -Hashtable $Wrapper['attachments'][0]['content'] -Recursive -Rerun 1
    $JsonBody = $Wrapper | ConvertTo-JsonLiteral -Depth 20 #ConvertTo-Json -Depth 20
    #$New = $JsonBody | Format-Json -Indentation 4
    # $JsonBody = $Wrapper | ConvertTo-Json -Depth 20
    # If URI is not given we return JSON. This is because it's possible to use nested Adaptive Cards in actions
    if ($Uri) {
        Send-TeamsMessageBody -Uri $URI -Body $JsonBody #-Verbose
    } else {
        $JsonBody
    }
}

<#
    "channelId" = @{
        "entities" = @(
            @{
                "type"      = "mention"
                "text"      = "<at>Name</at>"
                "mentioned" = @{
                    "id"   = "29:124124124124"
                    "name" = "Mungo"
                }
            }
        )
    }
#>


#"msteams" = @{
#"entities" = @(
<#
                                @{
                                    "type"      = "mention"
                                    "text"      = "<at>przemyslawklys</at>"
                                    "mentioned" = @{
                                        "id"   = "8:orgid:49f7e27a-ce6c-45ef-9936-6ef3e940583d"
                                        "name" = "przemyslawklys"
                                    }
                                }
                                #>
# Azure ID: 49f7e27a-ce6c-45ef-9936-6ef3e940583d
# AD GUID: d425e1e4-d6b3-4e58-bb24-f96c995fd3a0
<#
                                @{
                                    "type"      = "mention"
                                    "text"      = "<at>Przemysław</at>"
                                    "mentioned" = @{
                                        "id"   = "29:124124124124"
                                        "name" = "Mungo"
                                    }
                                }
                                #>
#)
#}
function New-AdaptiveColumn {
    [cmdletBinding()]
    param(
        [scriptblock] $Items,
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        [ValidateSet('Stretch', 'Auto', 'Weighted')][string] $Width,
        [int] $WidthInWeight,
        [int] $WidthInPixels,
        [int] $MinimumHeight,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Top', 'Center', 'Bottom')][string] $VerticalContentAlignment,
        [ValidateSet("Accent", 'Default', 'Emphasis', 'Good', 'Warning', 'Attention')][string] $Style,
        [switch] $Hidden,
        [switch] $Separator,

        [ValidateSet('Action.Submit', 'Action.OpenUrl', 'Action.ToggleVisibility')][string] $SelectAction,
        [string] $SelectActionId,
        [string] $SelectActionUrl,
        [string] $SelectActionTitle,
        [string[]] $SelectActionTargetElement
    )
    if ($WidthInWeight) {
        $WidthValue = "$($WidthInWeight)"
        # it actually forces $Width = Weighted but it's not in JSON
    } elseif ($WidthInPixels) {
        $WidthValue = "$($WidthInPixels)px"
    } else {
        # Width value pixels is not displayed
        # it seems width requires lowerCase values which is weird for Microsoft
        $WidthValue = $Width.ToLower()
    }

    if ($Items) {
        $OutputItems = & $Items
        if ($OutputItems) {
            $TeamObject = [ordered] @{
                type                     = 'Column'
                width                    = $WidthValue
                height                   = $Height
                items                    = @(
                    $OutputItems
                )
                horizontalAlignment      = $HorizontalAlignment
                verticalContentAlignment = $VerticalContentAlignment
                spacing                  = $Spacing
                style                    = $Style
            }
            if ($MinimumHeight) {
                $TeamObject['minHeight'] = "$($MinimumHeight)px"
            }
            if ($Hidden) {
                $TeamObject['isVisible'] = $false
            }
            if ($Separator) {
                $TeamObject['separator'] = $Separator.IsPresent
            }
            if ($SelectActionUrl) {
                # We help user so the actioon choses itself
                $SelectAction = 'Action.OpenUrl'
            }
            $TeamObject['selectAction'] = [ordered] @{
                type  = $SelectAction
                id    = $SelectActionId
                title = $SelectActionTitle
                url   = $SelectActionUrl
            }
            if ($SelectActionTargetElement) {
                # We help user so the actioon choses itself
                $TeamObject['selectAction']['type'] = 'Action.ToggleVisibility'
                # We add missing data
                $TeamObject['selectAction']['targetElements'] = @(
                    $SelectActionTargetElement
                )
            }
            Remove-EmptyValue -Hashtable $TeamObject -Recursive -Rerun 1
            $TeamObject
        }
    }
}
function New-AdaptiveColumnSet {
    [cmdletBinding()]
    param(
        [scriptblock] $Columns,
        [ValidateSet("Accent", 'Default', 'Emphasis', 'Good', 'Warning', 'Attention')][string] $Style,
        [int] $MinimumHeight,
        [switch] $Bleed,
        # Layout Start
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [switch] $Separator,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Stretch', 'Automatic')][string] $Height
        # Layout End
    )
    if ($Columns) {
        $ColumnsOutput = & $Columns
        if ($ColumnsOutput) {
            $TeamObject = [ordered] @{
                "type"                = "ColumnSet"
                "columns"             = @(
                    $ColumnsOutput
                )
                "style"               = $Style

                # Layout
                "horizontalAlignment" = $HorizontalAlignment
                "height"              = $Height
                "spacing"             = $Spacing
            }
            if ($Bleed) {
                $TeamObject['bleed'] = $true
            }
            if ($MinimumHeight) {
                $TeamObject['minHeight'] = "$($MinimumHeight)px"
            }
            if ($Separator) {
                $TeamObject['separator'] = $Separator.IsPresent
            }
            if ($SelectActionUrl) {
                # We help user so the actioon choses itself
                $SelectAction = 'Action.OpenUrl'
            }
            $TeamObject['selectAction'] = [ordered] @{
                type  = $SelectAction
                id    = $SelectActionId
                title = $SelectActionTitle
                url   = $SelectActionUrl
            }
            Remove-EmptyValue -Hashtable $TeamObject -Recursive -Rerun 1
            $TeamObject
        }
    }
}
function New-AdaptiveContainer {
    [cmdletBinding()]
    param(
        [scriptblock] $Items,
        # Layout Start
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [switch] $Separator,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        # Layout End
        [ValidateSet("Accent", 'Default', 'Emphasis', 'Good', 'Warning', 'Attention')][string] $Style,
        [int] $MinimumHeight,
        [switch] $Bleed,
        [ValidateSet('top', 'center', 'bottom')][string] $VerticalContentAlignment,
        [string] $Id,
        [switch] $Hidden,

        [string] $BackgroundUrl,
        [ValidateSet('Cover', 'RepeatHorizontally', 'RepeatVertically', 'Repeat')][string] $BackgroundFillMode,
        [ValidateSet('left', 'center', 'right')][string] $BackgroundHorizontalAlignment,
        [ValidateSet('top', 'center', 'bottom')][string] $BackgroundVerticalAlignment,

        [ValidateSet('Action.Submit', 'Action.OpenUrl', 'Action.ToggleVisibility')][string] $SelectAction,
        [string] $SelectActionId,
        [string] $SelectActionUrl,
        [string] $SelectActionTitle,
        [string[]] $SelectActionTargetElement
    )
    if ($Items) {
        $OutputItems = & $Items
        if ($OutputItems) {
            $TeamObject = [ordered] @{
                type                     = "Container"
                id                       = $Id
                items                    = @(
                    $OutputItems
                )
                style                    = $Style
                verticalContentAlignment = $verticalContentAlignment
                # Layout
                horizontalAlignment      = $HorizontalAlignment
                height                   = $Height
                spacing                  = $Spacing
            }
            if ($Bleed) {
                $TeamObject['bleed'] = $true
            }
            if ($MinimumHeight) {
                $TeamObject['minHeight'] = "$($MinimumHeight)px"
            }
            if ($Separator) {
                $TeamObject['separator'] = $Separator.IsPresent
            }
            if ($Hidden) {
                $TeamObject['isVisible'] = $false
            }
            $TeamObject['backgroundImage'] = [ordered] @{
                "fillMode"            = $BackgroundFillMode
                "horizontalAlignment" = $BackgroundHorizontalAlignment
                "verticalAlignment"   = $BackgroundVerticalAlignment
                "url"                 = $BackgroundUrl
            }
            if ($SelectActionUrl) {
                # We help user so the actioon choses itself
                $SelectAction = 'Action.OpenUrl'
            }
            $TeamObject['selectAction'] = [ordered] @{
                type  = $SelectAction
                id    = $SelectActionId
                title = $SelectActionTitle
                url   = $SelectActionUrl
            }
            if ($SelectActionTargetElement) {
                # We help user so the actioon choses itself
                $TeamObject['selectAction']['type'] = 'Action.ToggleVisibility'
                # We add missing data
                $TeamObject['selectAction']['targetElements'] = @(
                    $SelectActionTargetElement
                )
            }
            Remove-EmptyValue -Hashtable $TeamObject -Recursive -Rerun 1
            $TeamObject
        }
    }
}
function New-AdaptiveFact {
    [cmdletBinding()]
    param(
        [string] $Title,
        [string] $Value
    )

    $Fact = [ordered] @{
        title = "$Title"
        value = "$Value"
        #type  = 'fact' # this is only needed for module to process this correctly. JSON doesn't care
    }
    $Fact
}
function New-AdaptiveFactSet {
    [cmdletBinding()]
    param(
        [scriptblock] $Facts,
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        [switch] $Separator
    )
    if ($Facts) {
        $OutputFacts = & $Facts
        if ($OutputFacts) {
            $TeamObject = [ordered] @{
                type    = 'FactSet'
                height  = $Height
                spacing = $Spacing
                facts   = @($OutputFacts)
            }
            if ($Separator) {
                $TeamObject['separator'] = $Separator.IsPresent
            }
            Remove-EmptyValue -Hashtable $TeamObject
            $TeamObject
        }
    }
}
function New-AdaptiveImage {
    <#
    .SYNOPSIS
    Displays an image. Acceptable formats are PNG, JPEG, and GIF

    .DESCRIPTION
    Displays an image. Acceptable formats are PNG, JPEG, and GIF

    .PARAMETER Url
    The URL to the image.

    .PARAMETER Style
    Controls how this Image is displayed.

    .PARAMETER AlternateText
    Alternate text describing the image.

    .PARAMETER Size
    Controls the approximate size of the image. The physical dimensions will vary per host.

    .PARAMETER Spacing
    Controls the amount of spacing between this element and the preceding element.

    .PARAMETER Separator
    Draw a separating line at the top of the element.

    .PARAMETER HorizontalAlignment
    Controls how this element is horizontally positioned within its parent.

    .PARAMETER Height
    The desired height of the image.

    .PARAMETER HeightInPixels
    The desired height of the image. Will be specified in pixel value. The image will distort to fit that exact height. This overrides the size property.

    .PARAMETER WidthInPixels
    The desired on-screen width of the image. This overrides the size property.

    .PARAMETER Id
    A unique identifier associated with the item.

    .PARAMETER Hidden
    If used this item will be removed from the visual tree.

    .PARAMETER BackgroundColor
    Applies a background to a transparent image. This property will respect the image style.

    .PARAMETER SelectAction
    An Action that will be invoked when the card is tapped or selected.

    .PARAMETER SelectActionId
    Provide ID for Select Action

    .PARAMETER SelectActionUrl
    Provide URL to open when using SelectAction with Action.OpenUrl

    .PARAMETER SelectActionTitle
    Provide Title for Select Action

    .EXAMPLE
    New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'

    .EXAMPLE
    New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Size Small -Style person

    .EXAMPLE
    New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Size Small -Style person -SelectAction Action.OpenUrl -SelectActionUrl 'https://evotec.xyz'

    .EXAMPLE
    New-HeroImage -Url 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Seattle_monorail01_2008-02-25.jpg/1024px-Seattle_monorail01_2008-02-25.jpg'

    .EXAMPLE
    New-ThumbnailImage -Url 'https://upload.wikimedia.org/wikipedia/en/a/a6/Bender_Rodriguez.png' -AltText "Bender Rodríguez"

    .NOTES
    Adaptive Image supports most if not all of those options. However HeroImage and ThumbnailImage most likely support only some if not just what is shown in Examples.
    I didn't want to create additional functions just for the sake of having more of them, as I expect most people using Adaptive Cards, and occasionally other types.

    #>
    [alias('New-HeroImage', 'New-ThumbnailImage')]
    [cmdletBinding()]
    param(
        [alias('Link')][string] $Url,
        [ValidateSet('person', 'default')][string] $Style,
        [alias('Alt', 'AltText')][string] $AlternateText,
        [ValidateSet('Auto', 'Stretch', 'Small', 'Medium', 'Large')][string] $Size,
        # Layout Start
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [switch] $Separator,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        [int] $HeightInPixels,
        [int] $WidthInPixels,
        # Layout End
        [string] $Id,
        [switch] $Hidden,
        [string] $BackgroundColor,
        # SelectAction
        [ValidateSet('Action.Submit', 'Action.OpenUrl', 'Action.ToggleVisibility')][string] $SelectAction,
        [string] $SelectActionId,
        [string] $SelectActionUrl,
        [string] $SelectActionTitle,
        [string[]] $SelectActionTargetElement
    )
    $TeamObject = [ordered] @{
        type                = 'Image'
        id                  = $Id
        url                 = $Url
        size                = $Size
        alt                 = $AlternateText
        style               = $Style
        # Start Layout
        horizontalAlignment = $HorizontalAlignment
        height              = $Height
        spacing             = $Spacing
        # End Layout
        backgroundColor     = ConvertFrom-Color -Color $BackgroundColor
    }
    # Start Layout
    if ($Separator) {
        $TeamObject['separator'] = $Separator.IsPresent
    }
    # End Layout
    if ($Hidden) {
        $TeamObject['isVisible'] = $false
    }
    if ($WidthInPixels) {
        $TeamObject['width'] = "$($WidthInPixels)px"
    }
    if ($HeightInPixels) {
        $TeamObject['height'] = "$($HeightInPixels)px"
    } else {
        $TeamObject['height'] = $Height
    }
    if ($SelectActionUrl) {
        # We help user so the actioon choses itself
        $SelectAction = 'Action.OpenUrl'
    }
    $TeamObject['selectAction'] = [ordered] @{
        type  = $SelectAction
        id    = $SelectActionId
        title = $SelectActionTitle
        url   = $SelectActionUrl
    }
    if ($SelectActionTargetElement) {
        # We help user so the actioon choses itself
        $TeamObject['selectAction']['type'] = 'Action.ToggleVisibility'
        # We add missing data
        $TeamObject['selectAction']['targetElements'] = @(
            $SelectActionTargetElement
        )
    }
    Remove-EmptyValue -Hashtable $TeamObject -Recursive -Rerun 1
    $TeamObject
}

$Script:ScriptBlockColors = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $Script:RGBColors.Keys | Where-Object { $_ -like "*$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName New-AdaptiveImage -ParameterName BackgroundColor -ScriptBlock $Script:ScriptBlockColors
function New-AdaptiveImageSet {
    <#
    .SYNOPSIS
    The ImageSet displays a collection of Images similar to a gallery. Acceptable formats are PNG, JPEG, and GIF

    .DESCRIPTION
    The ImageSet displays a collection of Images similar to a gallery. Acceptable formats are PNG, JPEG, and GIF

    .PARAMETER Images
    List of images

    .PARAMETER Size
    Controls size of all images in gallery

    .PARAMETER Spacing
    Controls the amount of spacing between this element and the preceding element.

    .PARAMETER Separator
    Draw a separating line at the top of the element.

    .PARAMETER HorizontalAlignment
    Controls the horizontal text alignment.

    .PARAMETER Height
    Specifies the height of the element.

    .PARAMETER Id
    A unique identifier associated with the item.

    .PARAMETER Hidden
    If used this item will be removed from the visual tree.

    .EXAMPLE
    New-AdaptiveImageGallery {
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
        New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Style person
        New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Style person
        New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Style person
    } -HorizontalAlignment Right -Size Large

    .EXAMPLE
    New-AdaptiveImageGallery {
        New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Size Small -Style person
        New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Size Small -Style person
        New-AdaptiveImage -Url "https://pbs.twimg.com/profile_images/3647943215/d7f12830b3c17a5a9e4afcc370e3a37e_400x400.jpeg" -Size Small -Style person
    }

    .EXAMPLE
    New-AdaptiveImageGallery {
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
        New-AdaptiveImage -BackgroundColor AlbescentWhite -Url 'https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2018/09/Powershell_256.png'
    } -Size Small

    .NOTES
    General notes
    #>
    [alias('New-AdaptiveImageGallery')]
    [cmdletBinding()]
    param(
        [scriptblock] $Images,
        [ValidateSet('Small', 'Medium', 'Large')][string] $Size,
        # Layout Start
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [switch] $Separator,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        # Layout End
        [string] $Id,
        [switch] $Hidden
    )
    if ($Images) {
        $OutputImages = & $Images
        if ($OutputImages) {
            $TeamObject = [ordered] @{
                type                = 'ImageSet'
                images              = @($OutputImages)
                id                  = $Id
                imageSize           = $Size
                # Start Layout
                horizontalAlignment = $HorizontalAlignment
                height              = $Height
                spacing             = $Spacing
                # End Layout
            }
            # Start Layout
            if ($Separator) {
                $TeamObject['separator'] = $Separator.IsPresent
            }
            # End Layout
            if ($Hidden) {
                $TeamObject['isVisible'] = $false
            }
            Remove-EmptyValue -Hashtable $TeamObject -Recursive -Rerun 1
            $TeamObject
        }
    }
}
function New-AdaptiveMedia {
    <#
    .SYNOPSIS
    Displays a media player for audio or video content.

    .DESCRIPTION
    Displays a media player for audio or video content.

    .PARAMETER Sources
    One or more sources of media to attempt to play.

    .PARAMETER PosterUrl
    URL of an image to display before playing

    .PARAMETER AlternateText
    Alternate text describing the audio or video.

    .PARAMETER Spacing
    Controls the amount of spacing between this element and the preceding element.

    .PARAMETER Separator
    Draw a separating line at the top of the element.

    .PARAMETER HorizontalAlignment
    Controls the horizontal text alignment.

    .PARAMETER Height
    Specifies the height of the element.

    .PARAMETER Id
    A unique identifier associated with the item.

    .PARAMETER Hidden
    If used this item will be removed from the visual tree.

    .EXAMPLE
    New-AdaptiveMedia -PosterUrl 'https://adaptivecards.io/content/poster-video.png' {
        New-AdaptiveMediaSource -Type "video/mp4" -Url "https://adaptivecardsblob.blob.core.windows.net/assets/AdaptiveCardsOverviewVideo.mp4"
        New-AdaptiveMediaSource -Type "video/mp4" -Url "https://adaptivecardsblob.blob.core.windows.net/assets/AdaptiveCardsOverviewVideo.mp4"
    }

    .NOTES
    Media playback is currently not supported in Adaptive Cards in Teams. Adding it for sake of having.
    May need to improve how it's handled.

    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][scriptblock] $Sources,
        [string] $PosterUrl,
        [string] $AlternateText,
        # Layout Start
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [switch] $Separator,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        # Layout End,
        [string] $Id,
        [switch] $Hidden
    )
    if ($Sources) {
        $TeamObject = [ordered] @{
            type                = 'Media'
            poster              = $PosterUrl
            id                  = $Id
            altText             = $AlternateText
            # Start Layout
            horizontalAlignment = $HorizontalAlignment
            height              = $Height
            spacing             = $Spacing
            # End Layout
        }
        # Start Layout
        if ($Separator) {
            $TeamObject['separator'] = $Separator.IsPresent
        }
        # End Layout
        if ($Hidden) {
            $TeamObject['isVisible'] = $false
        }
        $TeamObject['sources'] = @(
            & $Sources
        )
        Remove-EmptyValue -Hashtable $TeamObject
        $TeamObject
    }
}

function New-AdaptiveMediaSource {
    <#
    .SYNOPSIS
    Defines a source for a Media element

    .DESCRIPTION
    Defines a source for a Media element

    .PARAMETER Type
    Mime type of associated media (e.g. "video/mp4").

    .PARAMETER Url
    URL to media.

    .EXAMPLE
    New-AdaptiveMediaSource -Type "video/mp4" -Url "https://adaptivecardsblob.blob.core.windows.net/assets/AdaptiveCardsOverviewVideo.mp4"

    .EXAMPLE
    New-AdaptiveMedia -PosterUrl 'https://adaptivecards.io/content/poster-video.png' {
        New-AdaptiveMediaSource -Type "video/mp4" -Url "https://adaptivecardsblob.blob.core.windows.net/assets/AdaptiveCardsOverviewVideo.mp4"
        New-AdaptiveMediaSource -Type "video/mp4" -Url "https://adaptivecardsblob.blob.core.windows.net/assets/AdaptiveCardsOverviewVideo.mp4"
    }

    .NOTES
    Media playback is currently not supported in Adaptive Cards in Teams. Adding it for sake of having.
    May need to improve how it's handled.

    #>
    [cmdletBinding()]
    param(
        [string] $Type,
        [string] $Url
    )
    $TeamObject = [ordered] @{
        mimeType = $Type
        url      = $Url
    }
    $TeamObject
}
function New-AdaptiveMention {
    <#
    .SYNOPSIS
    Allows Adaptive Card to mention specific person in the notification.

    .DESCRIPTION
    Allows Adaptive Card to mention specific person in the notification.
    Currently Adaptive Card in incoming webhook notifications allows you to define a mention property, but it doesn't notify the user on notification.
    It's supposed to be enabled in future by Microsoft.

    .PARAMETER Text
    Provide the text to be mentioned by using <at>person</at> tag. You can provide tags or skip them. Should work either way.

    .PARAMETER UserPrincipalName
    Provide the user principal name of the person to be mentioned.

    .PARAMETER Name
    Provide the name of the person to be mentioned. This is optional.

    .EXAMPLE
    New-AdaptiveMention -Text '<at>przemyslaw.klys</at>' -UserPrincipalName 'przemyslaw.klys@evotec.test'

    .EXAMPLE
    New-AdaptiveMention -Text 'przemyslaw.klys' -UserPrincipalName 'przemyslaw.klys@evotec.test' -Name 'Przemysław Kłys'

    .EXAMPLE
    New-AdaptiveCard -Uri $URI -VerticalContentAlignment center {
        New-AdaptiveTextBlock -Size ExtraLarge -Weight Bolder -Text 'Test' -Color Attention -HorizontalAlignment Center
        New-AdaptiveColumnSet {
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Dark
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Light
            }
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Warning
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Good
            }
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1 <at>Name</at>' -Color Warning
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1 <at>Zenon Jaskuła</at>' -Color Warning
            }
        }
        New-AdaptiveMention -Text 'Zenon Jaskuła' -UserPrincipalName 'przemyslaw.klys@evotec.test'
        New-AdaptiveMention -Text 'Name' -UserPrincipalName 'przemyslaw.klys@evotec.test'
    } -Verbose -FullWidth

    .NOTES
    More information here: https://github.com/EvotecIT/PSTeams/issues/17

    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][string] $Text,
        [parameter(Mandatory)][string] $UserPrincipalName,
        [string] $Name
    )

    $Mention = [ordered] @{
        "type"      = "mention"
        "text"      = if ($Text -like "*<at>*") { $Text } else { "<at>$Text</at>" }
        "mentioned" = @{
            id   = $UserPrincipalName
            name = $Name
        }
    }
    if ($Name) {
        $Mention.mentioned.name = $Name
    }
    $Mention
}
function New-AdaptiveRichTextBlock {
    <#
    .SYNOPSIS
    Defines an array of inlines, allowing for inline text formatting.

    .DESCRIPTION
    Defines an array of inlines, allowing for inline text formatting.

    .PARAMETER Text
    Text to display.

    .PARAMETER Color
    Controls the color of text elements.

    .PARAMETER Subtle
    Displays text slightly toned down to appear less prominent.

    .PARAMETER Size
    Controls size of text.

    .PARAMETER Weight
    Controls the weight of text elements.

    .PARAMETER Highlight
    Controls the hightlight of text elements

    .PARAMETER Italic
    Controls italic of text elements

    .PARAMETER StrikeThrough
    Controls strikethrough of text elements

    .PARAMETER FontType
    Type of font to use for rendering

    .PARAMETER Spacing
    Controls the amount of spacing between this element and the preceding element.

    .PARAMETER Separator
    Draw a separating line at the top of the element.

    .PARAMETER HorizontalAlignment
    Controls the horizontal text alignment.

    .PARAMETER Height
    Specifies the height of the element.

    .PARAMETER Id
    A unique identifier associated with the item.

    .PARAMETER Hidden
    If used this item will be removed from the visual tree.

    .EXAMPLE
    New-AdaptiveRichTextBlock -Text 'This is the first inline.', 'We support colors,', 'both regular and subtle. ', 'Monospace too!' -Color Attention, Default, Warning -StrikeThrough $false, $true, $false -Size ExtraLarge, Default, Medium -Italic $false, $false, $true -Subtle $false, $true, $true

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [string[]] $Text,
        [ValidateSet("Accent", 'Default', 'Dark', 'Light', 'Good', 'Warning', 'Attention')][string[]] $Color = @(),
        [bool[]] $Subtle = @(),
        [alias('FontSize')][ValidateSet("Small", 'Default', "Medium", "Large", "ExtraLarge")][string[]] $Size = @(),
        [alias('FontWeight')][ValidateSet("Lighter", 'Default', "Bolder")][string[]] $Weight = @(),
        [bool[]] $Highlight = @(),
        [bool[]] $Italic = @(),
        [bool[]] $StrikeThrough = @(),
        [ValidateSet('Default', 'Monospace')][string[]] $FontType = @(),
        # Layout Start
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [switch] $Separator,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [ValidateSet('Stretch', 'Automatic')][string] $Height,
        # Layout End
        [string] $Id,
        [switch] $Hidden
    )

    [Array] $Inlines = for ($a = 0; $a -lt $Text.Count; $a++) {
        $TextRun = [ordered] @{
            type = 'TextRun'
            text = $Text[$a]
        }
        if ($Color[$a]) {
            $TextRun['color'] = $Color[$a]
        }
        if ($Subtle[$a]) {
            $TextRun['subtle'] = $Subtle[$a]
        }
        if ($Size[$a]) {
            $TextRun['size'] = $Size[$a]
        }
        if ($Weight[$a]) {
            $TextRun['weight'] = $Weight[$a]
        }
        if ($Highlight[$a]) {
            $TextRun['highlight'] = $Highlight[$a]
        }
        if ($Italic[$a]) {
            $TextRun['italic'] = $Italic[$a]
        }
        if ($StrikeThrough[$a]) {
            $TextRun['strikethrough'] = $StrikeThrough[$a]
        }
        if ($FontType[$a]) {
            $TextRun['fontType'] = $FontType[$a]
        }
        $TextRun
    }
    $TeamObject = [ordered]@{
        type                = "RichTextBlock"
        id                  = $Id
        inlines             = $Inlines
        # Start Layout
        horizontalAlignment = $HorizontalAlignment
        height              = $Height
        spacing             = $Spacing
        # End Layout
    }
    # Start Layout
    if ($Separator) {
        $TeamObject['separator'] = $Separator.IsPresent
    }
    # End Layout
    if ($Hidden) {
        $TeamObject['isVisible'] = $false
    }
    Remove-EmptyValue -Hashtable $TeamObject
    $TeamObject
}
function New-AdaptiveTextBlock {
    <#
    .SYNOPSIS
    Displays text, allowing control over font sizes, weight, and color.

    .DESCRIPTION
    Displays text, allowing control over font sizes, weight, and color.

    .PARAMETER Text
    Text to display. A subset of markdown is supported (https://aka.ms/ACTextFeatures)

    .PARAMETER Color
    Controls the color of TextBlock elements.

    .PARAMETER FontType
    Type of font to use for rendering

    .PARAMETER HorizontalAlignment
    Controls the horizontal text alignment.

    .PARAMETER Subtle
    Displays text slightly toned down to appear less prominent.

    .PARAMETER MaximumLines
    Specifies the maximum number of lines to display.

    .PARAMETER Size
    Controls size of text.

    .PARAMETER Weight
    Controls the weight of TextBlock elements.

    .PARAMETER Wrap
    Allow text to wrap. Otherwise, text is clipped.

    .PARAMETER Height
    Specifies the height of the element.

    .PARAMETER Separator
    Draw a separating line at the top of the element.

    .PARAMETER Spacing
    Controls the amount of spacing between this element and the preceding element.

    .PARAMETER Id
    A unique identifier associated with the item.

    .PARAMETER Hidden
    If used this item will be removed from the visual tree.

    .EXAMPLE
    New-AdaptiveCard -Uri $Env:TEAMSPESTERID -VerticalContentAlignment center {
        New-AdaptiveTextBlock -Size ExtraLarge -Weight Bolder -Text 'Test' -Color Attention -HorizontalAlignment Center
        New-AdaptiveColumnSet {
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Dark
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Light
            }
            New-AdaptiveColumn {
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Warning
                New-AdaptiveTextBlock -Size 'Medium' -Text 'Test Card Title 1' -Color Good
            }
        }
    } -SelectAction Action.OpenUrl -SelectActionUrl 'https://evotec.xyz' -Verbose

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [string] $Text,
        [ValidateSet("Accent", 'Default', 'Dark', 'Light', 'Good', 'Warning', 'Attention')][string] $Color,
        [ValidateSet('Default', 'Monospace')][string] $FontType,
        [ValidateSet("Left", "Center", 'Right')][string] $HorizontalAlignment,
        [switch] $Subtle,
        [int] $MaximumLines,
        [alias('FontSize')][ValidateSet("Small", 'Default', "Medium", "Large", "ExtraLarge")][string] $Size,
        [alias('FontWeight')][ValidateSet("Lighter", 'Default', "Bolder")][string] $Weight,
        [switch] $Wrap,
        [alias('BlockElementHeight')][ValidateSet('Stretch', 'Automatic')][string] $Height,
        [switch] $Separator,
        [ValidateSet('None', 'Small', 'Default', 'Medium', 'Large', 'ExtraLarge', 'Padding')][string] $Spacing,
        [string] $Id,
        [switch] $Hidden
    )
    $TeamObject = [ordered]@{
        type                = "TextBlock"
        text                = $Text
        id                  = $Id
        spacing             = $Spacing
        horizontalAlignment = $HorizontalAlignment
        size                = $Size
        weight              = $Weight
        color               = $Color
        height              = $Height
        fontType            = $FontType
    }
    if ($MaximumLines) {
        $TeamObject['maxLines'] = $MaximumLines
    }
    if ($Separator) {
        $TeamObject['separator'] = $Separator.IsPresent
    }
    if ($Wrap) {
        $TeamObject['wrap'] = $Wrap.IsPresent
    }
    if ($Subtle) {
        $TeamObject['isSubtle'] = $true
    }
    if ($Hidden) {
        $TeamObject['isVisible'] = $false
    }
    Remove-EmptyValue -Hashtable $TeamObject
    $TeamObject
}


function New-CardList {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock] $Content,
        [string] $Title,
        [string] $Uri
    )
    if ($Content) {
        $Buttons = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $Items = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $ExecutedContent = & $Content
        foreach ($E in $ExecutedContent) {
            if ($E.Value) {
                if ($Buttons.Count -lt 6) {
                    $Buttons.Add($E)
                } else {
                    Write-Warning "New-CardList - List Cards support only up to 6 buttons."
                }
            } else {
                $Items.Add($E)
            }
        }

        $Wrapper = @{
            contentType = "application/vnd.microsoft.teams.card.list"
            content     = @{
                title   = $Title
                items   = @(
                    $Items
                )
                buttons = @(
                    $Buttons
                )
            }
        }
    }
    $Body = $Wrapper | ConvertTo-Json -Depth 20
    if ($Uri) {
        Send-TeamsMessageBody -Uri $URI -Body $Body -Wrap
    } else {
        $Body
    }
}
function New-CardListButton {
    [alias('New-HeroButton', 'New-ThumbnailButton')]
    [cmdletBinding()]
    param(
        [ValidateSet('imBack', 'openUrl', 'file')][string] $Type,
        [string] $Title,
        [string] $Value,
        [string] $Image
    )
    if ($Image) {
        Write-Warning "Using Image for Buttons while technically supported by Teams, it's not supported by Teams Connectors. Leaving this in place just in case it starts working"
    }
    $TeamsObject = [ordered] @{
        "type"  = $Type
        "title" = $Title
        "value" = $Value
        "image" = $Image
    }
    Remove-EmptyValue -Hashtable $TeamsObject
    $TeamsObject
}
function New-CardListItem {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][ValidateSet('file', 'resultItem', 'section', 'person')][string] $Type,
        [string] $Icon,
        [string] $Title,
        [string] $SubTitle,
        [ValidateSet('whois', 'editOnline')][string] $TapAction,
        [ValidateSet('imBack', 'openUrl', 'file')][string] $TapType,
        [string] $TapValue
    )
    $TeamsObject = [ordered] @{
        type     = $Type
        id       = if ($TapAction) { $TapValue } else { '' }
        title    = $Title
        subtitle = $SubTitle
        icon     = $Icon
        tap      = @{
            type  = $TapType
            value = "$TapAction $TapValue".Trim()
        }
    }
    Remove-EmptyValue -Hashtable $TeamsObject -Recursive -Rerun 2
    $TeamsObject
}
function New-HeroCard {
    <#
    .SYNOPSIS
    Provides a quick and easy way to build a Hero Card and send it thru incoming webhook to Microsoft Teams.

    .DESCRIPTION
    Provides a quick and easy way to build a Hero Card and send it thru incoming webhook to Microsoft Teams.

    .PARAMETER Content
    ScriptBlock to define the content of HeroCard

    .PARAMETER Title
    Title of the hero card

    .PARAMETER SubTitle
    Subtitle of the hero card

    .PARAMETER Text
    Text to display within hero card

    .PARAMETER Uri
    URI/URL of Incoming Webhook generated in Microsoft Teams

    .EXAMPLE
    New-HeroCard -Title 'Seattle Center Monorail' -SubTitle 'Seattle Center Monorail' -Text "The Seattle Center Monorail is an elevated train line between Seattle Center (near the Space Needle) and downtown Seattle. It was built for the 1962 World's Fair. Its original two trains, completed in 1961, are still in service." {
        New-HeroImage -Url 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Seattle_monorail01_2008-02-25.jpg/1024px-Seattle_monorail01_2008-02-25.jpg'
        New-HeroButton -Type openUrl -Title 'Official website' -Value 'https://www.seattlemonorail.com'
        New-HeroButton -Type openUrl -Title 'Wikipeda page' -Value 'https://www.seattlemonorail.com'
        New-HeroButton -Type imBack -Title 'Evotec page' -Value 'https://www.evotec.xyz'
    } -Uri $URI

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock] $Content,
        [string] $Title,
        [string] $SubTitle,
        [string] $Text,
        [string] $Uri
    )
    if ($Content) {
        $Buttons = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $Images = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $ExecutedContent = & $Content
        foreach ($E in $ExecutedContent) {
            if ($E.Value) {
                if ($Buttons.Count -lt 3) {
                    $Buttons.Add($E)
                } else {
                    Write-Warning "New-HeroCard - Herd Card support only up to 3 buttons."
                }
            } else {
                if ($Images.Count -lt 2) {
                    $Images.Add($E)
                } else {
                    Write-Warning "New-HeroCard - Herd Card support only 1 image."
                }
            }
        }

        $Wrapper = @{
            contentType = "application/vnd.microsoft.card.hero"
            content     = @{
                title    = $Title
                subTitle = $SubTitle
                text     = $Text
                images   = @(
                    $Images
                )
                buttons  = @(
                    $Buttons
                )
            }
        }
    }
    $Body = $Wrapper | ConvertTo-Json -Depth 20
    if ($Uri) {
        Send-TeamsMessageBody -Uri $URI -Body $Body -Wrap
    } else {
        $Body
    }
}
function New-TeamsActivityImage {
    <#
    .SYNOPSIS
    Adds ability to add an image to an activity within Office 365 Connector Card

    .DESCRIPTION
    Adds ability to add an image to an activity within Office 365 Connector Card

    .PARAMETER Image
    Choose one of built-in images to display. Options are: 'Add', 'Alert', 'Cancel', 'Check', 'Disable', 'Download', 'Info', 'Minus', 'Question', 'Reload', 'None'

    .PARAMETER Link
    Provide a link to image to display in the card.

    .PARAMETER Path
    Provide a path to image to display in the card. JPG and PNG files are supported.

    .EXAMPLE
    Send-TeamsMessage -URI $TeamsID -MessageTitle 'PSTeams - Pester Test' -MessageText "This text will show up" -Color DodgerBlue {
        New-TeamsSection {
            New-TeamsActivityTitle -Title "**PSTeams**"
            New-TeamsActivitySubtitle -Subtitle "@PSTeams - $CurrentDate"
            New-TeamsActivityImage -Image Add
            New-TeamsActivityText -Text "This message proves PSTeams Pester test passed properly."
            New-TeamsFact -Name 'PS Version' -Value "**$($PSVersionTable.PSVersion)**"
            New-TeamsFact -Name 'PS Edition' -Value "**$($PSVersionTable.PSEdition)**"
            New-TeamsFact -Name 'OS' -Value "**$($PSVersionTable.OS)**"
            New-TeamsButton -Name 'Visit English Evotec Website' -Link "https://evotec.xyz"
        }
    } -Verbose

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'Link')]
    [alias('ActivityImageLink', 'TeamsActivityImageLink', 'New-TeamsActivityImageLink', 'ActivityImage', 'TeamsActivityImage')]
    param(
        [Parameter(ParameterSetName = 'Image')][string][ValidateSet('Add', 'Alert', 'Cancel', 'Check', 'Disable', 'Download', 'Info', 'Minus', 'Question', 'Reload', 'None')] $Image,
        [Parameter(ParameterSetName = 'Link')][string] $Link,

        [Parameter(ParameterSetName = 'Path')]
        [ValidateScript({
                if (-not ($_ | Test-Path)) {
                    throw "Path is inaccessible or does not exist"
                }
                if (-not ($_ | Test-Path -PathType Leaf) -or ($_ -notmatch "(\.jpg|\.png)")) {
                    throw "Path is not a file or file extension is not supported"
                }
                return $true
            })]
        [System.IO.FileInfo] $Path
    )
    if ($Path) {
        $FilePath = [System.IO.Path]::GetDirectoryName($Path)
        $FileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $FileExtension = [System.IO.Path]::GetExtension($Path)
        @{
            ActivityImageLink = Get-Image -PathToImages $FilePath -FileName $FileBaseName -FileExtension $FileExtension -Verbose
            type              = 'ActivityImage'
        }
    } elseif ($Image) {
        if ($Image -ne 'None') {
            $StoredImages = [IO.Path]::Combine($PSScriptRoot, 'Images')
            @{
                ActivityImageLink = Get-Image -PathToImages $StoredImages -FileName $Image -FileExtension '.jpg' # -Verbose
                type              = 'ActivityImage'
            }
        }
    } else {
        @{
            ActivityImageLink = $Link
            Type              = 'ActivityImageLink'
        }
    }
}

function New-TeamsActivitySubtitle {
    [CmdletBinding()]
    [alias('ActivitySubtitle', 'TeamsActivitySubtitle')]
    param(
        [string] $Subtitle
    )
    @{
        ActivitySubtitle = $Subtitle
        Type             = 'ActivitySubtitle'
    }
}
function New-TeamsActivityText {
    [CmdletBinding()]
    [alias('ActivityText', 'TeamsActivityText')]
    param(
        [string] $Text
    )
    @{
        ActivityText = $Text
        Type         = 'ActivityText'
    }
}
function New-TeamsActivityTitle {
    [CmdletBinding()]
    [alias('ActivityTitle', 'TeamsActivityTitle')]
    param(
        [string] $Title
    )
    @{
        ActivityTitle = $Title
        Type          = 'ActivityTitle'
    }

}
function New-TeamsBigImage {
    [alias('TeamsBigImage')]
    [CmdletBinding()]
    param(
        [alias('Url', 'Uri')] $Link,
        [string] $AlternativeText = 'Alternative Text'
    )
    if ($Link) {
        [ordered] @{
            image = "![$AlternativeText]($Link)"
            type  = 'HeroImageWorkaround'
        }
    }
}
function New-TeamsButton {
    [alias('TeamsButton')]
    [CmdletBinding()]
    param (
        [alias('ButtonName')][Parameter(Mandatory)][ValidateNotNull()][ValidateNotNullOrEmpty()][string] $Name,
        [alias('TargetUri', 'Uri', 'Url')][Parameter(Mandatory)][ValidateNotNull()][ValidateNotNullOrEmpty()][string] $Link,
        [alias('ButtonType')][string][ValidateSet('ViewAction', 'TextInput', 'DateInput', 'HttpPost', 'OpenUri')] $Type = 'ViewAction'
    )
    if ($Type -eq 'ViewAction') {
        $Button = [ordered] @{
            '@context' = 'http://schema.org'
            '@type'    = 'ViewAction'
            name       = "$Name"
            target     = @("$Link")
            type       = 'button' # this is only needed for module to process this correctly. JSON doesn't care
        }
    } elseif ($Type -eq 'TextInput') {
        $Button = [ordered] @{
            #'@context' = 'http://schema.org'
            '@type'  = 'ActionCard'
            'Name'   = $Name
            'Inputs' = @(
                @{
                    '@type'       = 'TextInput'
                    'id'          = 'Comment'
                    'isMultiLine' = $true
                    'title'       = 'Enter Your Text Input Here'
                }
            )
            actions  = @(
                @{
                    '@type'  = 'HttpPOST'
                    'Name'   = 'OK'
                    'target' = $Link
                }
            )
            type     = 'button' # this is only needed for module to process this correctly. JSON doesn't care
        }
    } elseif ($Type -eq 'DateInput') {
        $Button = [ordered] @{
            '@type'  = 'ActionCard'
            'Name'   = $Name
            'Inputs' = @(
                @{
                    '@type' = 'DateInput'
                    'id'    = 'dueDate'
                }
            )
            actions  = @(
                @{
                    '@type'  = 'HttpPOST'
                    'Name'   = 'OK'
                    'target' = $Link
                }
            )
            type     = 'button' # this is only needed for module to process this correctly. JSON doesn't care
        }
    } elseif ($Type -eq 'HttpPost') {
        $Button = [ordered] @{
            'name'   = $Name
            '@type'  = 'HttpPOST'
            'Target' = $Link
            type     = 'button' # this is only needed for module to process this correctly. JSON doesn't care
        }
    } elseif ($Type -eq 'OpenUri') {
        $Button = [ordered] @{
            'name'    = $Name
            '@type'   = 'OpenURI'
            'Targets' = @(
                @{
                    'os'  = 'default'
                    'uri' = $Link
                }
            )
            type      = 'button' # this is only needed for module to process this correctly. JSON doesn't care
        }
    }
    return $Button
}
function New-TeamsFact {
    [alias('TeamsFact')]
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $Value
    )
    $Fact = [ordered] @{
        name  = "$Name"
        value = "$Value"
        type  = 'fact' # this is only needed for module to process this correctly. JSON doesn't care
        #wrap = $false
    }
    return $Fact
}
function New-TeamsImage {
    [alias('TeamsImage')]
    [CmdletBinding()]
    param(
        [alias('Url', 'Uri')] $Link
    )
    if ($Link) {
        [ordered] @{
            image = $Link
            type  = 'image'
        }
    }
}
function New-TeamsList {
    [alias('TeamsList')]
    [CmdletBinding()]
    param(
        [scriptblock] $List,
        [string] $Name
    )

    if ($List) {
        $Output = & $List
        [Array] $Fact = foreach ($_ in $Output) {
            if ($_.Numbered) {
                $Type = '1. '
            } else {
                $Type = "- "
            }
            if ($_.Type -eq 'ListItem') {
                "`t" * $_.Level + $Type + $_.Text
            }
        }
        [string] $Value = $Fact -join "`r" #[System.Environment]::NewLine

        New-TeamsFact -Name $Name -Value $Value
    }
}
function New-TeamsListItem {
    [alias('TeamsListItem')]
    [CmdletBinding()]
    param(
        [string] $Text,
        [int] $Level,
        [switch] $Numbered
    )
    [ordered] @{
        Text     = $Text
        Level    = $Level
        Numbered = $Numbered.IsPresent
        Type     = 'ListItem'
    }
}
function New-TeamsSection {
    [alias('TeamsSection')]
    [CmdletBinding()]
    param (
        [scriptblock] $SectionInput,
        [string] $Title,
        [string] $ActivityTitle,
        [string] $ActivitySubtitle ,
        [string] $ActivityImageLink,
        [string][ValidateSet('Alert', 'Cancel', 'Disable', 'Download', 'Minus', 'Check', 'Add', 'None')] $ActivityImage = 'None',

        [ValidateScript({
                if (-not ($_ | Test-Path)) {
                    throw "ActivityImagePath is inaccessible or does not exist"
                }
                if (-not ($_ | Test-Path -PathType Leaf) -or ($_ -notmatch "(\.jpg|\.png)")) {
                    throw "ActivityImagePath is not a file or file extension is not supported"
                }
                return $true
            })]
        [System.IO.FileInfo] $ActivityImagePath,

        [string] $ActivityText,
        [string] $Text,
        [System.Collections.IDictionary[]]$ActivityDetails,
        [System.Collections.IDictionary[]]$Buttons,
        [switch] $StartGroup
    )

    if ($ActivityImagePath) {
        # ActivityImagePath takes precedence over ActivityImage
        $FilePath = [System.IO.Path]::GetDirectoryName($ActivityImagePath)
        $FileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($ActivityImagePath)
        $FileExtension = [System.IO.Path]::GetExtension($ActivityImagePath)
        $ActivityImageLink = Get-Image -PathToImages $FilePath -FileName $FileBaseName -FileExtension $FileExtension # -Verbose
    } elseif ($ActivityImage -ne 'None') {
        $StoredImages = [IO.Path]::Combine($PSScriptRoot, 'Images')
        $ActivityImageLink = Get-Image -PathToImages $StoredImages -FileName $ActivityImage -FileExtension '.jpg' # -Verbose
    }

    $ButtonsList = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $FactList = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $ImagesList = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    $ImageHeroList = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()

    if ($SectionInput) {
        $SectionOutput = & $SectionInput
        foreach ($_ in $SectionOutput) {
            if ($_.Type -eq 'button') {
                $_.Remove('Type')
                $ButtonsList.Add($_)
            } elseif ($_.Type -eq 'fact') {
                $_.Remove('Type')
                $FactList.Add($_)
            } elseif ($_.Type -eq 'image') {
                $_.Remove('Type')
                $ImagesList.Add($_)
            } elseif ($_.Type -eq 'HeroImageWorkaround') {
                $ImageHeroList.Add($_)
            } elseif ($_.Type -eq 'ActivityTitle') {
                $ActivityTitle = $_.ActivityTitle
            } elseif ($_.Type -eq 'ActivitySubtitle') {
                $ActivitySubtitle = $_.ActivitySubtitle
            } elseif ($_.Type -eq 'ActivityImageLink') {
                $ActivityImageLink = $_.ActivityImageLink
            } elseif ($_.Type -eq 'ActivityText') {
                $ActivityText = $_.ActivityText
            } elseif ($_.Type -eq 'ActivityImage') {
                $ActivityImageLink = $_.ActivityImageLink
            }
        }
    }

    $Section = [ordered] @{ }
    if ($Title) {
        $Section.title = $Title
    }
    if ($ActivityTitle) {
        $Section.activityTitle = "$($ActivityTitle)"
    }
    if ($ActivitySubtitle) {
        $Section.activitySubtitle = "$($ActivitySubtitle)"
    }
    if ($ActivityImageLink) {
        $Section.activityImage = "$($ActivityImageLink)"
    }
    if ($ActivityText) {
        $Section.activityText = "$($ActivityText)"
    }


    # $section.heroImage = @{ image = "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Seattle_monorail01_2008-02-25.jpg/1024px-Seattle_monorail01_2008-02-25.jpg" }

    if ($Text -or $ImageHeroList.Count -gt 0) {
        if ($ImageHeroList.Count -gt 0) {
            [string] $TextBundle = @(
                foreach ($_ in $ImageHeroList) {
                    $_.Image
                }
                if ($Text) {
                    $Text
                }
            )
        } else {
            [string] $TextBundle = $Text
        }
        $section.text = $TextBundle
    }
    if ($ImagesList.Count -gt 0) {
        $section.images = @( $ImagesList )
    }
    if ($StartGroup) {
        $Section.startGroup = $startGroup.IsPresent
    }
    if ($null -ne $ActivityDetails -or $FactList.Count -gt 0) {
        $Section.facts = @(
            if ($SectionInput) {
                $FactList
            } else {
                $ActivityDetails
            }
        )
    }
    if ($null -ne $Buttons -or $ButtonsList.Count -gt 0) {
        $Section.potentialAction = @(
            if ($SectionInput) {
                $ButtonsList
            } else {
                $Buttons
            }
        )
    }
    return $Section
}

function New-ThumbnailCard {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock] $Content,
        [string] $Title,
        [string] $SubTitle,
        [string] $Text,
        [string] $Uri
    )
    if ($Content) {
        $Buttons = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $Images = [System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
        $ExecutedContent = & $Content
        foreach ($E in $ExecutedContent) {
            if ($E.Value) {
                if ($Buttons.Count -lt 6) {
                    $Buttons.Add($E)
                } else {
                    Write-Warning "New-ThumbnailCard - Thumbnail Card support only up to 6 buttons."
                }
            } else {
                if ($Images.Count -lt 1) {
                    $Images.Add($E)
                } else {
                    Write-Warning "New-ThumbnailCard - Thumbnail Card support only 1 image."
                }
            }
        }

        $Wrapper = [ordered]@{
            contentType = "application/vnd.microsoft.card.thumbnail"
            content     = [ordered]@{
                title    = $Title
                subTitle = $SubTitle
                text     = $Text
                images   = @(
                    $Images
                )
                buttons  = @(
                    $Buttons
                )
            }
        }
    }
    $Body = $Wrapper | ConvertTo-Json -Depth 20
    if ($Uri) {
        Send-TeamsMessageBody -Uri $URI -Body $Body -Wrap
    } else {
        $Body
    }
}
function Send-TeamsMessage {
    [alias('TeamsMessage')]
    [CmdletBinding()]
    Param (
        [scriptblock] $SectionsInput,
        [alias("TeamsID", 'Url')][Parameter(Mandatory)][string]$Uri,
        [string]$MessageTitle,
        [string]$MessageText,
        [string]$MessageSummary,
        [string]$Color,
        [switch]$HideOriginalBody,
        [Uri]$Proxy,
        [System.Collections.IDictionary[]]$Sections,
        [alias('Supress')][bool] $Suppress = $true
    )
    if ($SectionsInput) {
        $Output = & $SectionsInput
    } else {
        $Output = $Sections
    }

    if ($Color -or $Color -ne 'None') {
        try {
            $ThemeColor = ConvertFrom-Color -Color $Color
        } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            Write-Warning "Send-TeamsMessage - Color conversion for $Color failed. Error message: $ErrorMessage"
            $ThemeColor = $null
        }
    }
    $Body = Add-TeamsBody -MessageTitle $MessageTitle `
        -MessageText $MessageText `
        -ThemeColor $ThemeColor `
        -Sections $Output `
        -MessageSummary $MessageSummary `
        -HideOriginalBody:$HideOriginalBody.IsPresent
    Write-Verbose "Send-TeamsMessage - Body $Body"
    try {
        $Params = @{
            Uri         = $Uri
            Method      = 'Post'
            Body        = $Body
            ContentType = 'application/json; charset=UTF-8'
            ErrorAction = 'Stop'
        }
        if ($Proxy) {
            $Params.Proxy = $Proxy
        }
        $Execute = Invoke-RestMethod @Params
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            Write-Error "Couldn't send message. Error $ErrorMessage"
        } else {
            Write-Warning "Send-TeamsMessage - Couldn't send message. Error: $ErrorMessage"
        }
    }
    Write-Verbose "Send-TeamsMessage - Execute $Execute"
    if ($Execute -like '*failed*' -or $Execute -like '*error*') {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            Write-Error "Send-TeamsMessage - Couldn't send message. Execute message: $Execute"
        } else {
            Write-Warning "Send-TeamsMessage - Couldn't send message. Execute message: $Execute"
        }
    }
    if (-not $Suppress) { return $Body }
}

Register-ArgumentCompleter -CommandName Send-TeamsMessage -ParameterName Color -ScriptBlock { $Script:RGBColors.Keys }
function Send-TeamsMessageBody {
    [alias('TeamsMessageBody')]
    [CmdletBinding()]
    param (
        [alias("TeamsID", 'Url')][Parameter(Mandatory = $true)][string]$Uri,
        [string] $Body,
        [bool] $Supress = $true,
        [switch] $Wrap,
        [Uri] $Proxy
    )
    if ($Wrap) {
        $TemporaryBody = ConvertFrom-Json -InputObject $Body
        $Wrapper = [ordered]@{
            "type"        = "message"
            "attachments" = @(
                $TemporaryBody
            )
        }
        $Body = $Wrapper | ConvertTo-Json -Depth 20
    }
    Write-Verbose "Send-TeamsMessage - Body $Body"
    try {
        $Params = @{
            Uri         = $Uri
            Method      = 'Post'
            Body        = $Body
            ContentType = 'application/json; charset=UTF-8'
        }
        if ($Proxy) {
            $Params.Proxy = $Proxy
        }
        $Execute = Invoke-RestMethod @Params
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            Write-Error "Couldn't send message. Error $ErrorMessage"
        } else {
            Write-Warning "Send-TeamsMessageBody - Couldn't send message. Error: $ErrorMessage"
        }
    }
    Write-Verbose "Send-TeamsMessageBody - Execute $Execute"
    if ($Execute -like '*failed*' -or $Execute -like '*error*') {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            Write-Error "Send-TeamsMessageBody - Couldn't send message. Execute message: $Execute"
        } else {
            Write-Warning "Send-TeamsMessageBody - Couldn't send message. Execute message: $Execute"
        }
    }
    if (-not $Supress) { return $Body }
}



# Export functions and aliases as required
Export-ModuleMember -Function @('ConvertTo-TeamsFact', 'ConvertTo-TeamsSection', 'New-AdaptiveAction', 'New-AdaptiveActionSet', 'New-AdaptiveCard', 'New-AdaptiveColumn', 'New-AdaptiveColumnSet', 'New-AdaptiveContainer', 'New-AdaptiveFact', 'New-AdaptiveFactSet', 'New-AdaptiveImage', 'New-AdaptiveImageSet', 'New-AdaptiveMedia', 'New-AdaptiveMediaSource', 'New-AdaptiveMention', 'New-AdaptiveRichTextBlock', 'New-AdaptiveTextBlock', 'New-CardList', 'New-CardListButton', 'New-CardListItem', 'New-HeroCard', 'New-TeamsActivityImage', 'New-TeamsActivitySubtitle', 'New-TeamsActivityText', 'New-TeamsActivityTitle', 'New-TeamsBigImage', 'New-TeamsButton', 'New-TeamsFact', 'New-TeamsImage', 'New-TeamsList', 'New-TeamsListItem', 'New-TeamsSection', 'New-ThumbnailCard', 'Send-TeamsMessage', 'Send-TeamsMessageBody') -Alias @('ActivityImage', 'ActivityImageLink', 'ActivitySubtitle', 'ActivityText', 'ActivityTitle', 'New-AdaptiveImageGallery', 'New-HeroButton', 'New-HeroImage', 'New-TeamsActivityImageLink', 'New-ThumbnailButton', 'New-ThumbnailImage', 'TeamsActivityImage', 'TeamsActivityImageLink', 'TeamsActivitySubtitle', 'TeamsActivityText', 'TeamsActivityTitle', 'TeamsBigImage', 'TeamsButton', 'TeamsFact', 'TeamsImage', 'TeamsList', 'TeamsListItem', 'TeamsMessage', 'TeamsMessageBody', 'TeamsSection')
# SIG # Begin signature block
# MIInaAYJKoZIhvcNAQcCoIInWTCCJ1UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBKQEU/Krl1+TB/
# ixW0a6+uF2GnD+qBEStk3tkNRy3LtKCCIWEwggO3MIICn6ADAgECAhAM5+DlF9hG
# /o/lYPwb8DA5MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBa
# Fw0zMTExMTAwMDAwMDBaMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lD
# ZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAK0OFc7kQ4BcsYfzt2D5cRKlrtwmlIiq9M71IDkoWGAM+IDaqRWVMmE8
# tbEohIqK3J8KDIMXeo+QrIrneVNcMYQq9g+YMjZ2zN7dPKii72r7IfJSYd+fINcf
# 4rHZ/hhk0hJbX/lYGDW8R82hNvlrf9SwOD7BG8OMM9nYLxj+KA+zp4PWw25EwGE1
# lhb+WZyLdm3X8aJLDSv/C3LanmDQjpA1xnhVhyChz+VtCshJfDGYM2wi6YfQMlqi
# uhOCEe05F52ZOnKh5vqk2dUXMXWuhX0irj8BRob2KHnIsdrkVxfEfhwOsLSSplaz
# vbKX7aqn8LfFqD+VFtD/oZbrCF8Yd08CAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFEXroq/0ksuCMS1Ri6enIZ3zbcgP
# MB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUA
# A4IBAQCiDrzf4u3w43JzemSUv/dyZtgy5EJ1Yq6H6/LV2d5Ws5/MzhQouQ2XYFwS
# TFjk0z2DSUVYlzVpGqhH6lbGeasS2GeBhN9/CTyU5rgmLCC9PbMoifdf/yLil4Qf
# 6WXvh+DfwWdJs13rsgkq6ybteL59PyvztyY1bV+JAbZJW58BBZurPSXBzLZ/wvFv
# hsb6ZGjrgS2U60K3+owe3WLxvlBnt2y98/Efaww2BxZ/N3ypW2168RJGYIPXJwS+
# S86XvsNnKmgR34DnDDNmvxMNFG7zfx9jEB76jRslbWyPpbdhAbHSoyahEHGdreLD
# +cOZUbcrBwjOLuZQsqf6CkUvovDyMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1
# b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtE
# aWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgx
# MDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLX
# cep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSR
# I5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXi
# TWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5
# Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8
# vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYD
# VR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4
# oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJv
# b3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCow
# KAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZI
# AYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaA
# FEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPz
# ItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRu
# pY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKN
# JK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmif
# z0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN
# 3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKy
# ZqHnGKSaZFHvMIIFPTCCBCWgAwIBAgIQBNXcH0jqydhSALrNmpsqpzANBgkqhkiG
# 9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEy
# IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDYyNjAwMDAwMFoXDTIz
# MDcwNzEyMDAwMFowejELMAkGA1UEBhMCUEwxEjAQBgNVBAgMCcWabMSFc2tpZTER
# MA8GA1UEBxMIS2F0b3dpY2UxITAfBgNVBAoMGFByemVteXPFgmF3IEvFgnlzIEVW
# T1RFQzEhMB8GA1UEAwwYUHJ6ZW15c8WCYXcgS8WCeXMgRVZPVEVDMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv7KB3iyBrhkLUbbFe9qxhKKPBYqDBqln
# r3AtpZplkiVjpi9dMZCchSeT5ODsShPuZCIxJp5I86uf8ibo3vi2S9F9AlfFjVye
# 3dTz/9TmCuGH8JQt13ozf9niHecwKrstDVhVprgxi5v0XxY51c7zgMA2g1Ub+3ti
# i0vi/OpmKXdL2keNqJ2neQ5cYly/GsI8CREUEq9SZijbdA8VrRF3SoDdsWGf3tZZ
# zO6nWn3TLYKQ5/bw5U445u/V80QSoykszHRivTj+H4s8ABiforhi0i76beA6Ea41
# zcH4zJuAp48B4UhjgRDNuq8IzLWK4dlvqrqCBHKqsnrF6BmBrv+BXQIDAQABo4IB
# xTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYE
# FBixNSfoHFAgJk4JkDQLFLRNlJRmMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3
# BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQu
# Y29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25p
# bmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAmr1sz4ls
# LARi4wG1eg0B8fVJFowtect7SnJUrp6XRnUG0/GI1wXiLIeow1UPiI6uDMsRXPHU
# F/+xjJw8SfIbwava2eXu7UoZKNh6dfgshcJmo0QNAJ5PIyy02/3fXjbUREHINrTC
# vPVbPmV6kx4Kpd7KJrCo7ED18H/XTqWJHXa8va3MYLrbJetXpaEPpb6zk+l8Rj9y
# G4jBVRhenUBUUj3CLaWDSBpOA/+sx8/XB9W9opYfYGb+1TmbCkhUg7TB3gD6o6ES
# Jre+fcnZnPVAPESmstwsT17caZ0bn7zETKlNHbc1q+Em9kyBjaQRcEQoQQNpezQu
# g9ufqExx6lHYDjCCBbEwggSZoAMCAQICEAEkCvseOAuKFvFLcZ3008AwDQYJKoZI
# hvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNz
# dXJlZCBJRCBSb290IENBMB4XDTIyMDYwOTAwMDAwMFoXDTMxMTEwOTIzNTk1OVow
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjww
# IjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J5
# 8soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMH
# hOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6
# Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQ
# ecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4b
# A3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9
# WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCU
# tNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvo
# ZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/J
# vNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCP
# orF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCAV4wggFaMA8GA1UdEwEB/wQFMAMB
# Af8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXr
# oq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggr
# BgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqg
# OKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkq
# hkiG9w0BAQwFAAOCAQEAmhYCpQHvgfsNtFiyeK2oIxnZczfaYJ5R18v4L0C5ox98
# QE4zPpA854kBdYXoYnsdVuBxut5exje8eVxiAE34SXpRTQYy88XSAConIOqJLhU5
# 4Cw++HV8LIJBYTUPI9DtNZXSiJUpQ8vgplgQfFOOn0XJIDcUwO0Zun53OdJUlsem
# Ed80M/Z1UkJLHJ2NltWVbEcSFCRfJkH6Gka93rDlkUcDrBgIy8vbZol/K5xlv743
# Tr4t851Kw8zMR17IlZWt0cu7KgYg+T9y6jbrRXKSeil7FAM8+03WSHF6EBGKCHTN
# bBsEXNKKlQN2UVBT1i73SkbDrhAscUywh7YnN0RgRDCCBq4wggSWoAMCAQICEAc2
# N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEh
# MB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIyMDMyMzAwMDAw
# MFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYg
# U0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD+Vr2EaFE
# FUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz7iuAhIoi
# GN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1decfBmWNlCnT2exp39mQh0YA
# e9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFobjchu0CsX7LeSn3O
# 9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6Th+xtVhNef7Xj3OTrCw54qVI
# 1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4EbP29p7m
# O1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlRErWHRAKKtzQ87fSqEcazjFKfPK
# qpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUoJEHtQr8F
# nGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh3pP+OcD5sjClTNfpmEpYPtMD
# iP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSyPx4Jduyr
# XUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnSDmuZDNIztM2xAgMBAAGjggFd
# MIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6FtltTYUvcyl2mi91
# jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8B
# Af8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKG
# NWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290
# RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQC
# MAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ipRCIBfmbW
# 2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL5Vxb122H
# +oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU1/+rT4os
# equFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2dfNBwCnzvqLx1T7pa96kQsl3p
# /yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibBt94q6/aesXmZgaNWhqsKRcnf
# xI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7T6NJuXdmkfFynOlLAlKnN36T
# U6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14OuSereU0
# cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9HSjTx/no8Zhf
# +yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7YGcWoWa6
# 3VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLfBInwAM1d
# wvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r5db7qS9E
# FUrnEw4d2zc4GqEr9u3WfPwwggbGMIIErqADAgECAhAKekqInsmZQpAGYzhNhped
# MA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2Vy
# dCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNI
# QTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjIwMzI5MDAwMDAwWhcNMzMwMzE0MjM1
# OTU5WjBMMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xJDAi
# BgNVBAMTG0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIyIC0gMjCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALkqliOmXLxf1knwFYIY9DPuzFxs4+AlLtIx5DxA
# rvurxON4XX5cNur1JY1Do4HrOGP5PIhp3jzSMFENMQe6Rm7po0tI6IlBfw2y1vmE
# 8Zg+C78KhBJxbKFiJgHTzsNs/aw7ftwqHKm9MMYW2Nq867Lxg9GfzQnFuUFqRUIj
# QVr4YNNlLD5+Xr2Wp/D8sfT0KM9CeR87x5MHaGjlRDRSXw9Q3tRZLER0wDJHGVvi
# mC6P0Mo//8ZnzzyTlU6E6XYYmJkRFMUrDKAz200kheiClOEvA+5/hQLJhuHVGBS3
# BEXz4Di9or16cZjsFef9LuzSmwCKrB2NO4Bo/tBZmCbO4O2ufyguwp7gC0vICNEy
# u4P6IzzZ/9KMu/dDI9/nw1oFYn5wLOUrsj1j6siugSBrQ4nIfl+wGt0ZvZ90QQqv
# uY4J03ShL7BUdsGQT5TshmH/2xEvkgMwzjC3iw9dRLNDHSNQzZHXL537/M2xwafE
# DsTvQD4ZOgLUMalpoEn5deGb6GjkagyP6+SxIXuGZ1h+fx/oK+QUshbWgaHK2jCQ
# a+5vdcCwNiayCDv/vb5/bBMY38ZtpHlJrYt/YYcFaPfUcONCleieu5tLsuK2QT3n
# r6caKMmtYbCgQRgZTu1Hm2GV7T4LYVrqPnqYklHNP8lE54CLKUJy93my3YTqJ+7+
# fXprAgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAW
# BgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglg
# hkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0O
# BBYEFI1kt4kh/lZYRIRhp+pvHDaP3a8NMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEy
# NTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZT
# SEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAA0tI3Sm
# 0fX46kuZPwHk9gzkrxad2bOMl4IpnENvAS2rOLVwEb+EGYs/XeWGT76TOt4qOVo5
# TtiEWaW8G5iq6Gzv0UhpGThbz4k5HXBw2U7fIyJs1d/2WcuhwupMdsqh3KErlrib
# Vakaa33R9QIJT4LWpXOIxJiA3+5JlbezzMWn7g7h7x44ip/vEckxSli23zh8y/pc
# 9+RTv24KfH7X3pjVKWWJD6KcwGX0ASJlx+pedKZbNZJQfPQXpodkTz5GiRZjIGvL
# 8nvQNeNKcEiptucdYL0EIhUlcAZyqUQ7aUcR0+7px6A+TxC5MDbk86ppCaiLfmSi
# ZZQR+24y8fW7OK3NwJMR1TJ4Sks3KkzzXNy2hcC7cDBVeNaY/lRtf3GpSBp43UZ3
# Lht6wDOK+EoojBKoc88t+dMj8p4Z4A2UKKDr2xpRoJWCjihrpM6ddt6pc6pIallD
# rl/q+A8GQp3fBmiW/iqgdFtjZt5rLLh4qk1wbfAs8QcVfjW05rUMopml1xVrNQ6F
# 1uAszOAMJLh8UgsemXzvyMjFjFhpr6s94c/MfRWuFL+Kcd/Kl7HYR+ocheBFThIc
# FClYzG/Tf8u+wQ5KbyCcrtlzMlkI5y2SoRoR/jKYpl0rl+CL05zMbbUNrkdjOEcX
# W28T2moQbh9Jt0RbtAgKh1pZBHYRoad3AhMcMYIFXTCCBVkCAQEwgYYwcjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENv
# ZGUgU2lnbmluZyBDQQIQBNXcH0jqydhSALrNmpsqpzANBglghkgBZQMEAgEFAKCB
# hDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEE
# AYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJ
# BDEiBCDD5mwzE90TPoLy5I86h0hTDf+UkuzQHyLOcIfAdXZYlDANBgkqhkiG9w0B
# AQEFAASCAQBT8Znmm7XUXh1+Nd2hihZqvrfcR3LyJtTeQBJ8EXMI/v381M6/ZX+M
# 05/CtLrFuD4DnZ/o0BSrzQMJfQKgUSwDJ9ZpDOBRqNF41QWALffbZ7y/FLZViPbH
# CJHA8DCfppqJyjXTqFPsZ900OXtYlm57q+1rgWItTQMSgmxuK6DJtBlIaDkdu9nJ
# c/Egk5JbLoMZk5PPBzoBw6d7JrOQy1IlhROa+kVrJrSSiLwLhvuyFwfFq8s9Bqxj
# PE9T0FRI5pfoXrIbzaK7nGZ39TTRmSloOuVQCO7SkJnbrPpVaISHmZaYrBI2CLhf
# t+hBNmMBx55wbd/uH+UWABJyL7Kz+hJZoYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0w
# ggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRp
# bWVTdGFtcGluZyBDQQIQCnpKiJ7JmUKQBmM4TYaXnTANBglghkgBZQMEAgEFAKBp
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIyMDcx
# MzEzMDQxMFowLwYJKoZIhvcNAQkEMSIEIDwx2vXD7xOAb5E8GkZ0TWvpVxJ3TeMG
# LpezFM2U5xpIMA0GCSqGSIb3DQEBAQUABIICAAStfgR+gOQvRJlMdOCj9BDjjcav
# EOAfavpREOOhNfk+RZh0jZZBFD4NynF2RP2IVtV88s5jwwifi+y3thZeGZBJw9r2
# Uv8tIDT7uKkK+B1rKx8eNOU0bB5DToVGA0fNY1Vg5zPMkqr5Wn2xH+uRdPudlau9
# kJt3T6z1ehAltWzQmx063ypfNVrWmBtel6mSJ+i43zShtknzMzDU8UqF1wC5ztCR
# 3qgp7V+mZbs+UdkSxexS+mdNjAHeFMnPIl3HbywoHtFp5Yl8fJa8WWROrtREv+xB
# fOPTIqnRDwasMV3YyLwDLOQB8HOYwOaw1UElNV2zjEiue1pQ1L6IhBnetd7vxPGj
# tgHjViHz2Hvy++p+s3hK5UIYvrQ7GMN7Q+anyfUzUXZDuaye9zVRbNgghk18EukE
# xyEMwDpIwBFgI9X+Sk8cfTN9ZlpHNP0iIzcO74vleQ5Ibr+eQ3+P8Q7xlcUiw58N
# iWOE48khL/l7IoEhwFvtxXatNBy5cDxDDbdTTg8Rp2GICe9DnkP3HXyS8qZ9otoO
# /aeArQ+9z88goIwKmWh68U9AZOS9+KZVAzTJ3Wrt6k2Cf6b/BwL8jfvLcpem/eRN
# ToGmcmkkRY7dEDfCcaR2Cli2nLDg/AdlfrTKCDZIYw8q7AdaNeKqPoGRzyk2GDMo
# IYOdIHOUOGz7EvlI
# SIG # End signature block
