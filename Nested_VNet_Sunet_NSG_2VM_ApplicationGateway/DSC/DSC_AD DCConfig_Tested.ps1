configuration DCConfig           
{             
 
      $dscDomainAdmin = Get-AutomationPSCredential -Name 'gcredentials'
      $dscDomainName = Get-AutomationVariable -Name 'domainname'
      $dscDomainNetbiosName = Get-AutomationVariable -Name 'netbiosname'
      $dscSafeModePassword = $dscDomainAdmin
      $dscDomainJoinAdminUsername = $dscDomainAdmin.UserName
      $dscDomainJoinAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist "$dscDomainName\$dscDomainJoinAdminUsername", $dscDomainAdmin.Password
            
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xStorage
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xDSCDomainjoin
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xDnsServer
               
            
    Node FirstDC             
    {             
            
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }            
            
        File ADFiles            
        {            
            DestinationPath = 'C:\NTDS'            
            Type = 'Directory'            
            Ensure = 'Present'            
        }            
        
        WindowsFeature DNS
	{
		Ensure = "Present"
		Name = "DNS"
	}
         xDnsServerAddress DnsServerAddress
	{
		Address        = '127.0.0.1'
		InterfaceAlias = 'Ethernet'
		AddressFamily  = 'IPv4'
		DependsOn = "[WindowsFeature]DNS"
	}
          WindowsFeature AD-Domain-Services             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"
            DependsOn = "[File]ADFiles"           
        }            
         
       WindowsFeature RSAT-DNS-Server
	{
		Ensure = "Present"
		Name = "RSAT-DNS-Server"
		DependsOn = "[WindowsFeature]DNS"
	}

	WindowsFeature RSAT-AD-Tools
	{
		Name = 'RSAT-AD-Tools'
		Ensure = 'Present'
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}

	WindowsFeature RSAT-ADDS
	{
		Ensure = "Present"
		Name = "RSAT-ADDS"
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}
	WindowsFeature RSAT-ADDS-Tools
	{
		Name = 'RSAT-ADDS-Tools'
		Ensure = 'Present'
		DependsOn = "[WindowsFeature]RSAT-ADDS"
	}
	WindowsFeature RSAT-AD-AdminCenter
	{
		Name = 'RSAT-AD-AdminCenter'
		Ensure = 'Present'
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}
        # No slash at end of folder paths            
        xADDomain FirstDS             
        {             
            DomainName = $dscDomainName            
            DomainAdministratorCredential = $dscDomainAdmin            
            SafemodeAdministratorPassword = $dscSafeModePassword            
            DatabasePath = 'C:\NTDS'            
            LogPath = 'C:\NTDS'            
            DependsOn = "[WindowsFeature]AD-Domain-Services","[File]ADFiles"            
        }
        
        xADUser FirstUser
        { 
            DomainName = $dscDomainName 
            UserName = $dscDomainAdmin.Username 
            Password = $dscDomainAdmin
			PasswordNeverExpires = $true
            Ensure = "Present" 
            DependsOn = "[xADDomain]FirstDS" 
        } 
		
        xADGroup DomainAdmins
        {
            GroupName = 'Domain Admins'
            MembersToInclude = $dscDomainAdmin.Username
	    DependsOn = "[xADUser]FirstUser" 
        }
            
    }             
}            
            
# Configuration Data for AD              
$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "FirstDC"    
            PSDscAllowDomainUser = $True
            PsDscAllowPlainTextPassword = $true            
        }            
    )             
}