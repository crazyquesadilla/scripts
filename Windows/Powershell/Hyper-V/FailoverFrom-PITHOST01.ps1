$SourceHost = Read-Host "Please specify the name of the source Hyper-V host to failover VMs from (PITHOST01 or PMTREPLICA01)" #Read input from user to choose which server to failover VMs from

if ($SourceHost -eq 'PMTREPLICA01') #Setting the second server as destination depending on the user input above
{
    $DestinationHost = 'PITHOST01'
}
elseif ($SourceHost -eq 'PITHOST01')
{
    $DestinationHost = 'PMTREPLICA01'
}
else
{
    Write-Host 'Invalid source Hyper-V host. Please rerun the script and specify a valid Hyper-V host server' -ForegroundColor Red #If invalid host server was specified, script exists
    Exit #Instead of exit, script can be modified to go in a loop until a correct hostname is given
}

Write-Host "Setting source Hyper-V host as $SourceHost and destination Hyper-V host as $DestinationHost" #Informational message showing HV host servers

$VMs = Get-VM -ComputerName $SourceHost | Where-Object {$_.State –eq 'Running'} #Retrieve list of all Running VMs on selected source server

foreach ($VM in $VMs) #Look for each VM in that list
{
    $VMName = $VM.Name #Setting VMName variable for use in output
    $SkipVM = 0 #Future use

    if ($VM.State -eq 'Running' -and $VM.Name -ne 'CriticalVM1' -and $VM.Name -ne 'CriticalVM2') #If the VM is in a running state and is not one of the critical VMs (the latter functionality can be removed if not needed)
    {
        try
        {
            $GetVMReplicaDetails = Get-VMReplication -VMName $VM.Name -ErrorAction Stop #Checking to make sure the VM has actually replication set up
        }
        catch
        {
            Write-Host "Replication is not enabled for the virtual machine $VMName. Skipping it" -ForegroundColor Yellow #If not, VM is skipped and loop proceeds to next VM in list
            Continue
        }
        
        try
        {
            Write-Host "Stopping virtual machine $VMName"

            Stop-VM -ComputerName $SourceHost -Name $VM.Name -Force -ErrorAction Stop #VM is shut down. If user is logged or machine is locked, shut down operation is forced

            $State = (Get-VM $VM.Name -ComputerName $SourceHost).State #State variable for use with loop below. Precautionary only

            do #Looping to wait for VM to be in a shut down state. Precautionary only, command above only finishes executing when the VM is off
            {
                $State = (Get-VM $VM.Name -ComputerName $SourceHost).State
                Start-Sleep -Seconds 5
            }
            while ($State -eq 'Running')
        }
        catch
        {
            Write-Error -Message "Failed to shut down $VMName, skipping it" #If VM failed to shutdown, it will be skipped
            Continue
        }

        if ($SkipVM -eq 0) #Future use
        {
            try
            {
                Write-Host "Failing over virtual machine $VMName"

                Start-VMFailover –Prepare –VMName $VM.Name -ComputerName $SourceHost -Confirm:$false -ErrorAction Stop #Sends any remaining replication data waiting to replicate
                Start-VMFailover –VMName $VM.Name -ComputerName $DestinationHost -Confirm:$false -ErrorAction Stop #Initiate a failover for the current VM
                Set-VMReplication –Reverse –VMName $VM.Name -ComputerName $DestinationHost -Confirm:$false -ErrorAction Stop #Reverse replication direction for the current VM
                Start-VM –VMName $VM.Name -ComputerName $DestinationHost -ErrorAction Stop #Starts the failed over VM on the destination server

                Write-Host "$VMName has been failed over from $SourceHost to $DestinationHost and has been started"
            }

            catch
            {
                Write-Error "$VMName failed to failover to $DestinationHost"
                Continue
            }
        }
    }
    elseif ($VM.Name -eq 'CriticalVM1' -or $VM.Name -eq 'CriticalVM2') #If VM is one of the critical servers, warning message is shown. If not needed, entire section can be removed
    {
        Write-Warning "Virtual machine $VMName cannot be failed over as it is one of the specified critical VMs"
    }
    else #If VM is already in a turned off state
    {
        try
        {
            $GetVMReplicaDetails = Get-VMReplication -VMName $VM.Name -ErrorAction Stop #Making sure VM is enabled for replication
        }
        catch
        {
            Write-Host "Replication is not enabled for the virtual machine $VMName. Skipping it" -ForegroundColor Yellow
            Continue
        }
        
        #This section is needed if initial input for Hyper-V Host server was not FQDN
        $CheckPrimaryHost = $GetVMReplicaDetails.PrimaryServer + '.' #Should always return FQDN, but just in case, '.' is added
        $CheckPrimaryHost = $CheckPrimaryHost.SubString(0, $CheckPrimaryHost.IndexOf('.'))

        if ($CheckPrimaryHost -eq $SourceHost) #If the VM is primary on the chosen source HV server, failover will proceed.
        {
            try
            {
                Write-Host "Failing over the already turned off virtual machine $VMName" #Notice already turned off in output message

                Start-VMFailover –Prepare –VMName $VM.Name -ComputerName $SourceHost -Confirm:$false -ErrorAction Stop #Same as above, 1- replicating any remaining data, 2- fail over VM, 3- reverse replication.
                Start-VMFailover –VMName $VM.Name -ComputerName $DestinationHost -Confirm:$false -ErrorAction Stop
                Set-VMReplication –Reverse –VMName $VM.Name -ComputerName $DestinationHost -Confirm:$false -ErrorAction Stop
                #Notice VM is not started
               
                Write-Host "$VMName has been failed over from $SourceHost to $DestinationHost"
            }

            catch
            {
                Write-Error "$VMName failed to failover to $DestinationHost"
                Continue
            }
        }
        else #If the VM is the replica and not the primary, skip it. Can be modified to output nothing if desired, in this case, only VMs being failed over will appear in the output
        {
            Write-Host "The specified virtual machine $VMName cannot be failed over because the specified Hyper-V source host is hosting the replicated VM and not the primary VM" -ForegroundColor Yellow
        }
    }
}