[cmdletbinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'The list of symbols to publish')]
    [List[string]]$PdbFiles,

    [Parameter(Mandatory = $true, HelpMessage = 'The share to which symbol publishing occurs')]
    [string]$Share,

    [Parameter(Mandatory = $true, HelpMessage = 'The Product parameter to symstore.exe')]
    [string]$Product,

    [Parameter(Mandatory = $true, HelpMessage = 'The Version parameter to symstore.exe')]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    # TODO WHERE IS THIS MIN/MAX VALIDATED DOWNSTREAM? Yank that code out.
    [ValidateRange(MinRange = { [timespan]::FromMinutes(1) }, MaxRange = { [timespan]::FromHours(3) })]
    [timespan]$MaximumWaitTime,

    [Parameter(Mandatory = $true)]
    [ValidateRange(MinRange = { [timespan]::FromMinutes(30) }, MaxRange = { [timespan]::FromDays(3) })]
    [timespan]$MaximumSemaphoreAge,

    [Parameter(Mandatory = $false, HelpMessage = 'Message that is written to _lockfile.sem semaphore file')]
    [string]$SemaphoreMessage,

    [Parameter(Mandatory = $false, HelpMessage = 'The name of the artifact that will get created for the symbols location')]
    [string]$ArtifactName
)

begin {
}

process {
    [string]$symbolsRspFile = $null;
    try {
        if (!$PdbFiles) {
            Write-Warning (Get-LocalizedString -Key 'No files were selected for publishing.')
            return
        }

        [string]$symstorePath = Get-ToolPath 'Symstore\symstore.exe'
        if (!$symstorePath) {
            throw (Get-LocalizedString -Key 'Could not find symstore.exe')
        }

        # Write a response file (.rsp) to pass to symstore.exe.
        $symbolsRspFile = [System.IO.Path]::GetTempFileName()
    }
    catch {
        Write-Error -ErrorRecord $Error[0]
    }
    finally {
    }
<#

            try
            {
                base.ProcessRecord();

                {
                    String symstorePath = ToolLocationHelper.GetToolsPath(@"Symstore\symstore.exe");
                    WriteVerbose(LocalizationHelper.FormatString("Looking for symstore.exe at {0}", symstorePath));

                    if (symstorePath == null)
                    {
                        WriteError(new ErrorRecord(new Exception(LocalizationHelper.FormatString("Could not find symstore.exe at expected location {0}", symstorePath)), "1", ErrorCategory.NotSpecified, null));
                        return;
                    }

                    // Write a response file (.rsp) to pass to symstore.exe
                    symbolsRspFile = Path.GetTempFileName();
                    using (StreamWriter sw = new StreamWriter(File.OpenWrite(symbolsRspFile)))
                    {
                        foreach (string pdbFile in this.PdbFiles)
                        {
                            if (File.Exists(pdbFile))
                            {
                                sw.WriteLine(pdbFile);
                            }
                        }
                    }
                    WriteVerbose(LocalizationHelper.FormatString("Wrote response file to {0}", symbolsRspFile));

                    publishSymbolsInternal(symbolsRspFile, symstorePath);
                }
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "1", ErrorCategory.NotSpecified, null));
            }
            finally
            {
                if (!String.IsNullOrEmpty(symbolsRspFile))
                {
                    // Delete the locally create temporary rsp file
                    PathHelper.TryDeleteFile(symbolsRspFile);
                }
            }
            #>
}

end {
}

# TODO: FIGURE OUT WHETHER StopProcessing OVERRIDE IS REALLY REQUIRED.

<#
        protected override void ProcessRecord()
        {
            String symbolsRspFile = null;

            try
            {
                base.ProcessRecord();

                if (this.PdbFiles == null || this.PdbFiles.Count == 0)
                {
                    WriteWarning(LocalizationHelper.FormatString("No files were selected for publishing."));
                    return;
                }
                else
                {
                    String symstorePath = ToolLocationHelper.GetToolsPath(@"Symstore\symstore.exe");
                    WriteVerbose(LocalizationHelper.FormatString("Looking for symstore.exe at {0}", symstorePath));

                    if (symstorePath == null)
                    {
                        WriteError(new ErrorRecord(new Exception(LocalizationHelper.FormatString("Could not find symstore.exe at expected location {0}", symstorePath)), "1", ErrorCategory.NotSpecified, null));
                        return;
                    }

                    // Write a response file (.rsp) to pass to symstore.exe
                    symbolsRspFile = Path.GetTempFileName();
                    using (StreamWriter sw = new StreamWriter(File.OpenWrite(symbolsRspFile)))
                    {
                        foreach (string pdbFile in this.PdbFiles)
                        {
                            if (File.Exists(pdbFile))
                            {
                                sw.WriteLine(pdbFile);
                            }
                        }
                    }
                    WriteVerbose(LocalizationHelper.FormatString("Wrote response file to {0}", symbolsRspFile));

                    publishSymbolsInternal(symbolsRspFile, symstorePath);
                }
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "1", ErrorCategory.NotSpecified, null));
            }
            finally
            {
                if (!String.IsNullOrEmpty(symbolsRspFile))
                {
                    // Delete the locally create temporary rsp file
                    PathHelper.TryDeleteFile(symbolsRspFile);
                }
            }
        }

        private void publishSymbolsInternal(String symbolsRspFile, string symstorePath)
        {
            Stream semaphoreFileStream = null;

            try
            {
                //maximumWaitTime is in milliseconds
                Int32 maximumWaitTime = EnsureValidValue(this.MaximumWaitTime, minimumValue: 1 * 60 * 1000 /*1m*/, maximumValue: 3 * 60 * 60 * 1000 /*3h*/);
                if(maximumWaitTime != this.MaximumWaitTime)
                {
                    // We changed the value, log it
                    WriteVerbose(LocalizationHelper.FormatString("Changed value of MaximumWaitTime from {0} to {1}.", this.MaximumWaitTime.ToString(), maximumWaitTime.ToString()));
                }
                //maximumSemaphoreAge is in minutes
                Int32 maximumSemaphoreAge = EnsureValidValue(this.MaximumSemaphoreAge, minimumValue: 30 /*30m*/,  maximumValue: 3 * 24 * 60 /*3d*/);
                if (maximumSemaphoreAge != this.MaximumSemaphoreAge)
                {
                    // We changed the value, log it
                    WriteVerbose(LocalizationHelper.FormatString("Changed value of MaximumSemaphoreAge from {0} to {1}.", this.MaximumSemaphoreAge.ToString(), maximumSemaphoreAge.ToString()));
                }

                Int32 sleepInterval = 10 * 1000; //10 seconds
                Int32 totalSleepTime = 0;

                Boolean attemptedDelete = false;
                String semaphoreFile = Path.Combine(this.Share, "_lockfile.sem");
                while (totalSleepTime < maximumWaitTime)
                {
                    try
                    {
                        //Check to see if the semaphore file exists
                        //  If it does exist and is older than 24h (configurable), try to clean the file up then retry
                        //      If the clean up fails, continue to try to publish symbols
                        //  If it does exist and is not older than 24h, assume another process is using it and wait
                        if (File.Exists(semaphoreFile))
                        {
                            DateTime creationTimeUtc = File.GetCreationTimeUtc(semaphoreFile);
                            WriteVerbose(LocalizationHelper.FormatString("Semaphore file creation time (UTC): {0}", creationTimeUtc.ToString()));

                            DateTime yesterdayUtc = DateTime.UtcNow.AddMinutes(0 - maximumSemaphoreAge);
                            WriteVerbose(LocalizationHelper.FormatString("Semaphore file comparison time (UTC): {0}", yesterdayUtc.ToString()));
                            if (creationTimeUtc < yesterdayUtc && !attemptedDelete)  //This doesn't prevent this worker or other agents from trying to delete the file on the very next build
                            {
                                WriteWarning(LocalizationHelper.FormatString("Semaphore file {0} already exists and was last accessed over {1} minutes ago.  Attempting to clean up.", semaphoreFile, maximumSemaphoreAge));
                                if (File.Exists(semaphoreFile))
                                {
                                    try
                                    {
                                        attemptedDelete = true;
                                        PathHelper.TryDeleteFile(semaphoreFile);
                                        WriteWarning(LocalizationHelper.FormatString("Semaphore file {0} was cleaned up successfully.", semaphoreFile));

                                        // If we cleaned up the semaphore file, just retry the loop (no sleep or warning message)
                                        continue;
                                    }
                                    catch (Exception e)
                                    {
                                        WriteWarning(LocalizationHelper.FormatString("Could not clean up the existing semaphore file {0}.  Error: {1}", e.Message));
                                    }
                                }
                            }

                            WriteWarning(LocalizationHelper.FormatString("Semaphore file {0} already exists.  Retrying symbol publishing in {1} seconds...", semaphoreFile, sleepInterval / 1000));
                            Thread.Sleep(sleepInterval);
                            totalSleepTime += sleepInterval;
                            continue;
                        }

                        // In BuildvNext, we're checking for the existence of the semaphore file on the share.  In XAML Build, we didn't have the semaphore file and the users could
                        // enter a non-existent share and we would create it.  So replicate that functionality here (which was provided by symstore.exe in XAML build).
                        if (!Directory.Exists(this.Share))
                        {
                            Directory.CreateDirectory(this.Share);
                            WriteVerbose(LocalizationHelper.FormatString("Created symbol store path at {0} since it did not exist.", this.Share));
                        }

                        String semaphoreMessage = null;
                        if (!String.IsNullOrEmpty(SemaphoreMessage))
                        {
                            semaphoreMessage = SemaphoreMessage;
                        }
                        else
                        {
                            semaphoreMessage = String.Format("Machine: {0} at {1} UTC", Environment.MachineName, DateTime.UtcNow.ToString());
                        }
                        byte[] bytes = UTF8Encoding.UTF8.GetBytes(semaphoreMessage);

                        using (semaphoreFileStream = File.Open(semaphoreFile, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                        {
                            semaphoreFileStream.Write(bytes, 0, bytes.Length);

                            // Doing work inside the using prevents external users from deleting the file while the work is being done
                            String symstoreArgs = String.Format(@"add /f ""@{0}"" /s ""{1}"" /t ""{2}"" /v ""{3}""", symbolsRspFile, this.Share, this.Product, this.Version);
                            WriteVerbose(String.Format(@"{0} {1}", symstorePath, symstoreArgs));

                            String tempFolderPath = Path.GetTempPath();
                            ProcessInvoker symstoreProcessInvoker = new ProcessInvoker(symstorePath, symstoreArgs, tempFolderPath);
                            Int32 symstoreExitCode = 0;
                            symstoreProcessInvoker.Output = new Action<String>(HandleOutput);
                            symstoreProcessInvoker.Error = new Action<String>(HandleError);
                            symstoreExitCode = symstoreProcessInvoker.Run(m_tokenSource.Token);
                            WriteVerbose(LocalizationHelper.FormatString("symstore.exe exit code: {0}", symstoreExitCode));

                            //Can't delete the file here since the using has the stream open
                        }
                        // Prevent .Dispose in outermost finally block from being called
                        semaphoreFileStream = null;

                        // Delete the file here so if all goes according to plan, the file no longer exists
                        // If the call to symstore.exe throws, the semaphore file will contain info to let users know 
                        // who was running the process when it went wrong
                        // The next time symstore folder is tried to be accessed, the task will write a warning
                        PathHelper.TryDeleteFile(semaphoreFile);

                        // Determine the artifact name to use for the published symbols location
                        String artifactName = String.Empty;
                        if (String.IsNullOrEmpty(this.ArtifactName))
                        { 
                            // Get the last transaction id so we can create the artifact based on the transaction id and share
                            String lastTransactionId = GetLastTransactionId();
                            if (String.IsNullOrEmpty(lastTransactionId))
                            {
                                String path = Path.Combine(this.Share, "000Admin");
                                WriteWarning(LocalizationHelper.FormatString("Symbol store lastid.txt file was not found at {0}", path));

                                // If no other value, use a Guid
                                artifactName = Guid.NewGuid().ToString();
                            }
                            else
                            {
                                artifactName = lastTransactionId;
                            }
                        }
                        else
                        {
                            artifactName = this.ArtifactName;
                        }

                        var artifact = new LoggingEvent("Artifact", "Associate")
                        {
                            Properties =
                            {
                                { "artifactname", artifactName },
                            },
                            Data = this.Share,
                        };

                        WriteVerbose(artifact.ToString());
                        //TODO: Create the artifact using the Powershell cmdlet when it's available
                        WriteObject(artifact.ToString());

                        // symstore.exe has completed its work, the cmdlet is done
                        break;
                    }
                    catch (IOException io)
                    {
                        // DirectoryNotFound and PathTooLong are both IOExceptions.  If we get either, don't retry
                        if (io is DirectoryNotFoundException ||
                            io is PathTooLongException)
                        {
                            //Don't retry on these two exception types
                            throw;
                        }

                        // IOException with "The network path was not found." error (HResult: -2147024843)
                        int NETWORK_PATH_NOT_FOUND = unchecked((int)0x80070035);
                        if (io.HResult == NETWORK_PATH_NOT_FOUND)
                        {
                            //Don't retry on this exception either (XAML build, via symstore.exe, would fail straight away in this scenario)
                            throw;
                        }

                        // This will occur if the file is in use by another agent (the "typical, expected" case)
                        // This will occur if the file gets created after the File.Exists check above but before File.Open
                        // It can also occur if the server does not exist or cannot be found
                        WriteWarning(LocalizationHelper.FormatString("{0} Accessing semaphore file: {1}, Retrying symbol publishing in {2} seconds...", io.Message, semaphoreFile, sleepInterval / 1000));

                        // Retry if we get other IOExceptions
                        Thread.Sleep(sleepInterval);
                        totalSleepTime += sleepInterval;
                    }
                    catch (Exception e)
                    {
                        // Don't retry on exceptions
                        WriteError(new ErrorRecord(e, "1", ErrorCategory.NotSpecified, null));
                        break;
                    }
                    finally
                    {
                        if (totalSleepTime >= maximumWaitTime)
                        {
                            WriteError(new ErrorRecord(new Exception(LocalizationHelper.FormatString("Symbol publishing could not be completed.  Reached maximum wait time of {0} seconds.", maximumWaitTime / 1000)), "1", ErrorCategory.NotSpecified, null));
                        }
                    }
                }
            }
            finally
            {
                if (semaphoreFileStream != null)
                {
                    semaphoreFileStream.Dispose();
                }
            }
        }

        private String GetLastTransactionId()
        {
            String lastidFilename = Path.Combine(this.Share, "000Admin");
            lastidFilename = Path.Combine(lastidFilename, "lastid.txt");

            if (File.Exists(lastidFilename))
            {
                // There is a slight chance this file won't exist (due to timing).
                // If we hit that case, it will propogate a FileNotFoundException
                // or DirectoryNotFoundException.
                return File.ReadAllText(lastidFilename).Trim();
            }
            else
            {
                return String.Empty;
            }
        }

        /// <summary>
        /// Given the passed currentValue, use minimumValue if the currentValue is less than minimumValue.
        /// Use maximumValue if the currentValue is greater than maximumValue.
        /// </summary>
        /// <param name="currentValue"></param>
        /// <param name="minimumValue"></param>
        /// <param name="maximumValue"></param>
        /// <returns></returns>
        private Int32 EnsureValidValue(Int32 currentValue, Int32 minimumValue, Int32 maximumValue)
        {
            if (currentValue <= minimumValue)
            {
                return minimumValue;
            }
            if (currentValue > maximumValue)
            {
                return maximumValue;
            }
            return currentValue;
        }

        private void HandleOutput(String line)
        {
            WriteVerbose(line);
        }

        private void HandleError(String line)
        {
            if (!String.IsNullOrEmpty(line))
            {
                WriteError(new ErrorRecord(new Exception(line), "1", ErrorCategory.NotSpecified, null));
            }
        }

        protected override void StopProcessing()
        {
            m_tokenSource.Cancel();
            base.StopProcessing();
        }

        private CancellationTokenSource m_tokenSource = new CancellationTokenSource();
#>