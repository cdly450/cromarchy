<#
.SYNOPSIS
    Logs a message to the ZenWin log file and optionally displays it in the console.

.DESCRIPTION
    Adds a timestamped log message to the ZenWin log file located at $Global:ZenWinLogFile.
    Also prints the message to the console with a color based on the log level,
    unless -NoConsole is specified.

.PARAMETER Message
    The message to log. This is the content of the log entry.

.PARAMETER Level
    The severity level of the message. Affects the log tag and default color.
    Valid values: INFO, SUCCESS, WARNING, ERROR.
    Default is INFO.

.PARAMETER Color
    (Optional) The console color used when printing the message.
    If not provided, a default color is chosen based on the Level.

.PARAMETER NoConsole
    If specified, suppresses console output and only logs to file.

.EXAMPLE
    Add-LogMessage -Message "Git installation complete." -Level SUCCESS

.EXAMPLE
    Add-LogMessage -Message "Something went wrong." -Level ERROR -NoConsole

.EXAMPLE
    Add-LogMessage -Message "Starting ZenWin install..." -Verbose

.NOTES
    Author: Craig Dempsey
    Project: ZenWin
    License: MIT
#>
function Add-LogMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO",

        [ConsoleColor]$Color = [ConsoleColor]::White,

        [switch]$NoConsole
    )

    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $logLine = "[$timestamp] [$Level] $Message"

    # Set Line color
    switch ($Level) {
        "INFO"    { if (-not $PSBoundParameters.ContainsKey('Color')) { $Color = 'Cyan' } }
        "SUCCESS" { if (-not $PSBoundParameters.ContainsKey('Color')) { $Color = 'Green' } }
        "WARNING" { if (-not $PSBoundParameters.ContainsKey('Color')) { $Color = 'Magenta' } }
        "ERROR"   { if (-not $PSBoundParameters.ContainsKey('Color')) { $Color = 'Red' } }
    }
    # Write to log file
    Add-Content -Path $Global:ZenWinLogFile -Value $logLine

    # Optional console output
    if (-not $NoConsole) {
        Write-Host $logLine -ForegroundColor $Color
    }

    Write-Verbose "Logged: $logLine"
}