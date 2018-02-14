﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config
)

$MinerFileVersion = "20180214_00" #Format: YYYMMMDD_[Counter]
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Type = "NVIDIA"
$API = "Claymore"

#hardcode Uri in the miner file to get the correct DL link on updated miner file
$Uri = "https://mega.nz/#F!O4YA2JgD!n2b4iSHQDruEsYUvTQP5_w"

if (-not $Config.$Name.MinerFileVersion) {
    # Create default miner config file for use in setup
    $Config = [PSCustomObject]@{
        $Name = [PSCustomObject]@{
            "MinerFileVersion" = "$MinerFileVersion"
            "MinerBinaryInfo" =  "Claymore Claymore Dual Ethereum AMD/NVIDIA GPU Miner v11.0"
            "Uri" = "$Uri"
            "UriComment" = "Note: The miner binary cannot be updated automatically due to the lack of a proper download link. You need to download the miner binaries from '$($Uri)' and then extract them to .\\Bin\\Ethash-Claymore\\"
            "Type" = "NVIDIA"
            "Path" = ".\Bin\Ethash-Claymore\EthDcrMiner64.exe"
            "Port" = 23333
            "MinerFeeInPercent" = 1.5
            "IgnoreAmdGpuID" = @(0, 1)
            "IgnoreNvidiaGpuID" =  @(0, 1)
            "Commands" = [PSCustomObject]@{
                "ethash" = ""
                "ethash2gb" = ""
                "ethash;blake2s;-dcoin blake2s -dcri 40" = ""
                "ethash;blake2s;-dcoin blake2s -dcri 60" = ""
                "ethash;blake2s;-dcoin blake2s -dcri 80" = ""
                "ethash;decred;-dcoin dcr -dcri 100" = ""
                "ethash;decred;-dcoin dcr -dcri 130" = ""
                "ethash;decred;-dcoin dcr -dcri 160" = ""
                "ethash;keccak;-dcoin keccak -dcri 70" = ""
                "ethash;keccak;-dcoin keccak -dcri 90" = ""
                "ethash;keccak;-dcoin keccak -dcri 110" = ""
                "ethash;lbry;-dcoin lbc -dcri 60" = ""
                "ethash;lbry;-dcoin lbc -dcri 75" = ""
                "ethash;lbry;-dcoin lbc -dcri 90" = ""
                "ethash;pascal;-dcoin pasc -dcri 40" = ""
                "ethash;pascal;-dcoin pasc -dcri 60" = ""
                "ethash;pascal;-dcoin pasc -dcri 80" = ""
                "ethash;pascal;-dcoin pasc -dcri 100" = ""
                "ethash2gb;blake2s;-dcoin blake2s -dcri 75" = ""
                "ethash2gb;blake2s;-dcoin blake2s -dcri 100" = ""
                "ethash2gb;blake2s;-dcoin blake2s -dcri 125" =  ""
                "ethash2gb;decred;-dcoin dcr -dcri 100" = ""
                "ethash2gb;decred;-dcoin dcr -dcri 130" = ""
                "ethash2gb;decred;-dcoin dcr -dcri 160" = ""
                "ethash2gb;keccak;-dcoin keccak -dcri 70" = ""
                "ethash2gb;keccak;-dcoin keccak -dcri 90" = ""
                "ethash2gb;keccak;-dcoin keccak -dcri 110" = ""
                "ethash2gb;lbry;-dcoin lbc -dcri 60" = ""
                "ethash2gb;lbry;-dcoin lbc -dcri 75" = ""
                "ethash2gb;lbry;-dcoin lbc -dcri 90" = ""
                "ethash2gb;pascal;-dcoin pasc -dcri 40" = ""
                "ethash2gb;pascal;-dcoin pasc -dcri 60" = ""
                "ethash2gb;pascal;-dcoin pasc -dcri 80" = ""
            }
            "CommonCommands" = " -logsmaxsize 1"
        } 
    }
    $Config.$Name | ConvertTo-Json -Depth 10 | Set-Content "Configs\Miners\$($Name).txt" -Force -ErrorAction Stop
}
else {
    if ($MinerFileVersion -gt $Config.$Name.MinerFileVersion) {
        # new miner version, possible functions to be implemented:
        # - force download new binaries (by deleting existing miner executable in bin folder)
        # - update existing miner config, e.g newly added algorithms

        # Overwrite config item if in existing config file, otherwise add it
        # Always update MinerFileVersion and download link
        $Config.$Name | Add-member MinerFileVersion "$MinerFileVersion" -Force
        $Config.$Name | Add-member Uri "$Uri" -Force
        
        # Add config item if not in existing config file
        $Config.$Name.Commands | Add-Member "ethash;pascal;-dcoin pasc -dcri 40" "" -ErrorAction SilentlyContinue
        $Config.$Name.Commands | Add-Member "ethash;pascal;-dcoin pasc -dcri 60" "" -ErrorAction SilentlyContinue
        $Config.$Name.Commands | Add-Member "ethash;pascal;-dcoin pasc -dcri 80" "" -ErrorAction SilentlyContinue
        $Config.$Name.Commands | Add-Member "ethash2gb;pascal;-dcoin pasc -dcri 40" "" -ErrorAction SilentlyContinue
        $Config.$Name.Commands | Add-Member "ethash2gb;pascal;-dcoin pasc -dcri 60" "" -ErrorAction SilentlyContinue
        $Config.$Name.Commands | Add-Member "ethash2gb;pascal;-dcoin pasc -dcri 80" "" -ErrorAction SilentlyContinue
        
        # Remove config item if in existing config file
        #$Config.$Name | Foreach-Object { $Config.$Name.PSObject.Properties.Remove("Dummy") } -ErrorAction SilentlyContinue

        # Execute action, e.g force re-download of binary
        #Remove-Item $Path -Force
        
        # Update config file
        $Config.$Name | ConvertTo-Json -Depth 10 | Set-Content "Configs\Miners\$($Name).txt" -Force -ErrorAction Stop
    }    
}

if (-not $SubtractMinerFees) { $MinerFeeInPercent = 0}

$Config.$Name.Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Command = $Config.$Name.Commands.$_
    $MainAlgorithm = $_.Split(";") | Select -Index 0
    $MainAlgorithm_Norm = Get-Algorithm $MainAlgorithm
    $DcriCmd = $_.Split(";") | Select -Index 2
    if ($DcriCmd) {
        $SecondaryAlgorithm = $_.Split(";") | Select -Index 1
        $SecondaryAlgorithm_Norm = Get-Algorithm $SecondaryAlgorithm
        $Dcri = $DcriCmd.Split(" ") | Select -Index 3
    }
    else {
        $SecondaryAlgorithm = ""
        $SecondaryAlgorithm_Norm = ""
        $Dcri = ""
    }

    if ($Pools.$($MainAlgorithm_Norm).Name -and -not $SecondaryAlgorithm) {
        
        [PSCustomObject]@{
            Name      = "$($Name)_$($MainAlgorithm_Norm)"
            Type      = $Type
            Path      = $Config.$Name.Path
            Arguments = ("-mode 1 -mport -$($Config.$Name.Port) -epool $($Pools.$MainAlgorithm_Norm.Host) $($Pools.$MainAlgorithm_Norm.Port) -ewal $($Pools.$MainAlgorithm_Norm.User) -epsw $($Pools.$MainAlgorithm_Norm.Pass) -esm 3 -allpools 1 -allcoins 1 -platform 2 $Command $($Config.$Name.CommonCommands)").trim()
            HashRates = [PSCustomObject]@{"$MainAlgorithm_Norm" = ($Stats."$($Name)_$($MainAlgorithm_Norm)_HashRate".Week * (100 - $MinerFeeInPercent))} 
            API       = $Api
            Port      = $Config.$Name.Port
            URI       = $Uri
        }
    }
    if ($Pools.$($MainAlgorithm_Norm).Name -and $Pools.$($SecondaryAlgorithm_Norm).Name) {
        [PSCustomObject]@{
            Name      = "$($Name)_$($SecondaryAlgorithm_Norm)$($Dcri)"
            Type      = $Type
            Path      = $Config.$Name.Path
            Arguments = ("-mode 0 -mport -$($Config.$Name.Port) -epool $($Pools.$MainAlgorithm_Norm.Host) $($Pools.$MainAlgorithm.Port) -ewal $($Pools.$MainAlgorithm_Norm.User) -epsw $($Pools.$MainAlgorithm_Norm.Pass) -esm 3 -allpools 1 -allcoins exp -dpool $($Pools."$SecondaryAlgorithm_Norm".Host) $($Pools.$SecondaryAlgorithm_Norm.Port) -dwal $($Pools.$SecondaryAlgorithm_Norm.User) -dpsw $($Pools.$SecondaryAlgorithm_Norm.Pass) -platform 2 $($DcriCmd) $Command $($Config.$Name.CommonCommands)").trim()
            HashRates = [PSCustomObject]@{"$MainAlgorithm_Norm" = ($Stats."$($Name)_$($MainAlgorithm_Norm)_HashRate".Week * (100 - $MinerFeeInPercent)); "$SecondaryAlgorithm_Norm" = ($Stats."$($Name)_$($SecondaryAlgorithm_Norm)_HashRate".Week * (100 - $MinerFeeInPercent))}
            API       = $Api
            Port      = $Config.$Name.Port
            URI       = $Uri
        }
        if ($SecondaryAlgorithm_Norm -eq "Sia" -or $SecondaryAlgorithm_Norm -eq "Decred") {
            $SecondaryAlgorithm_Norm = "$($SecondaryAlgorithm_Norm)NiceHash"
            [PSCustomObject]@{
                Name      = "$($Name)_$($SecondaryAlgorithm_Norm)$($Dcri)"
                Type      = $Type
                Path      = $Config.$Name.Path
                Arguments = ("-mode 0 -mport -$($Config.$Name.Port) -epool $($Pools.$MainAlgorithm_Norm.Host) $($Pools.$MainAlgorithm.Port) -ewal $($Pools.$MainAlgorithm_Norm.User) -epsw $($Pools.$MainAlgorithm_Norm.Pass) -esm 3 -allpools 1 -allcoins exp -dpool $($Pools.$SecondaryAlgorithm_Norm.Host) $($Pools.$SecondaryAlgorithm_Norm.Port) -dwal $($Pools.$SecondaryAlgorithm_Norm.User) -dpsw $($Pools.$SecondaryAlgorithm_Norm.Pass) -platform 2 $($DcriCmd) $Command $($CommonCommands)").trim()
                HashRates = [PSCustomObject]@{"$MainAlgorithm_Norm" = ($Stats."$($Name)_$($MainAlgorithm_Norm)_HashRate".Week * (100 - $MinerFeeInPercent)); "$SecondaryAlgorithm_Norm" = ($Stats."$($Name)_$($SecondaryAlgorithm_Norm)_HashRate".Week * (100 - $MinerFeeInPercent))}
                API       = $Api
                Port      = $Config.$Name.Port
                URI       = $Uri
            }
        }
    }
}