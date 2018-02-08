﻿function Get-THRUST_NetRoute {
    <#
    .SYNOPSIS 
        Gets a list of IPv4 Routes on a given system.

    .DESCRIPTION 
        Gets a list of IPv4 Routes on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THRUST_NetRoute 
        Get-THRUST_NetRoute SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THRUST_NetRoute
        Hunt-Get-THRUST_NetRoute $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-Get-THRUST_NetRoute

    .NOTES 
        Updated: 2018-02-07

        Contributing Authors:
            Jeremy Arnold
            
        LEGAL: Copyright (C) 2018
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
        
    .LINK
       https://github.com/TonyPhipps/THRUST
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        Enum RouteType
        {
            AdminDefinedRoute = 2
            ComputedRoute = 3
            ActualRoute = 4        
        }

        class Route
        {
            [String] $Computer
            [dateTime] $DateScanned

            [String] $InterfaceIndex
            [String] $InterfaceName
            [String] $DestinationPrefix
            [String] $NextHop
            [String] $Metric
            [String] $Protocol
            [String] $Store
            [String] $PublishedRoute
            [RouteType] $TypeOfRoute
        };
	};

    process{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $routes = $null;
        $routes = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $interfaces = $null;
            $interfaces = Get-NetAdapter | Where-Object {$_.MediaConnectionState -eq "Connected"};
            $routeTable = $null;

            Foreach ($interface in $interfaces) { # loop through each interface
                                
                $routeTable += Get-NetRoute -AddressFamily IPv4 -InterfaceIndex $interface.ifIndex -IncludeAllCompartments;
                
            };

            return $routeTable;
        
        };
            
        if ($routes) {
            
            $outputArray = @();

            Foreach ($route in $routes) {
                
                $output = $null;
                $output = [Route]::new();
    
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
    
                $output.InterfaceIndex = $route.ifIndex;
                $output.InterfaceName= $route.interfaceAlias;
                $output.DestinationPrefix = $route.DestinationPrefix;
                $output.NextHop = $route.NextHop;
                $output.Metric = $route.RouteMetric;
                $output.Protocol = $route.Protocol;
                $output.Store = $route.Store
                $output.PublishedRoute = $route.Publish;
                $output.TypeOfRoute = $route.TypeOfRoute;

                $outputArray += $output;
            };

            return $outputArray;

        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [Route]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total++;
                return $output;
            };
        };
    };

    end{

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};